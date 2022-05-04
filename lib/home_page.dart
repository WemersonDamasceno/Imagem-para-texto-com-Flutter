import 'dart:convert';
import 'dart:io' as Io;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_to_text/secrets.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late XFile? imagefile = XFile("");
  List palavras = [];
  List<PalavraModel> chipsEscolha = [];

  Dio dio = Dio();
  String parsedtext = '';

  parsethetext() async {
    // pick a image
    imagefile = (await ImagePicker()
        .pickImage(source: ImageSource.camera, maxWidth: 670, maxHeight: 970));

    if (imagefile != null) {
      // prepare the image
      var bytes = Io.File(imagefile!.path.toString()).readAsBytesSync();
      String img64 = base64Encode(bytes);
      print(img64.toString());

      // send to api
      var url = 'https://api.ocr.space/parse/image';
      var payload = {
        "base64Image": "data:image/jpg;base64,${img64.toString()}"
      };
      var header = {"apikey": Secrets.apiKey};
      var post =
          await http.post(Uri.parse(url), body: payload, headers: header);

      // get result from api
      var result = jsonDecode(post.body);
      setState(() {
        parsedtext = result['ParsedResults'][0]['ParsedText'];
      });
      montarChipsComPalavras(texto: parsedtext);
    }
  }

  montarChipsComPalavras({required String texto}) {
    setState(() {
      texto = texto.trim();
      palavras = texto.split('\n');
      palavras.forEach((palavra) {
        chipsEscolha.add(PalavraModel(palavra: palavra));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to Text'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 15.0),
              SizedBox(
                width: MediaQuery.of(context).size.width * .8,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  onPressed: () => parsethetext(),
                  label: const Text(
                    'Tire uma foto',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 70.0),
              Container(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.file(
                      File(imagefile!.path.toString()),
                      width: 150,
                      height: 150,
                    ),
                    Text(
                      "Textos encontrados",
                      style: GoogleFonts.montserrat(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SingleChildScrollView(
                      child: Wrap(
                        children:
                            List<Widget>.generate(chipsEscolha.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 2.0,
                              left: 6.0,
                            ),
                            child: FilterChip(
                              label: Text(chipsEscolha[i].palavra),
                              selected: chipsEscolha[i].isSelected,
                              onSelected: (bool value) {
                                setState(() {
                                  //Desmarcar todos os itens para deixar
                                  chipsEscolha.forEach((element) {
                                    element.isSelected = false;
                                  });
                                  chipsEscolha[i].isSelected = true;
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PalavraModel {
  String palavra;
  bool isSelected;

  PalavraModel({required this.palavra, this.isSelected = false});
}
