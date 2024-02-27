import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавьте этот импорт
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/api_key.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _extractedText = '';
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qazaq Dana'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),
              if (_imagePath != null)
                Card(
                  elevation: 5,
                  shadowColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_imagePath!),
                      width: 300,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  _extractedText,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _extractedText))
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Текст скопирован"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  });
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => pickImageAndDetectText(context),
        child: Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> pickImageAndDetectText(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Галерея'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Камера'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
      detectText(image.path);
    }
  }

  Future<void> detectText(String imagePath) async {
    final String apiKey = apikey;
    final String url =
        "https://vision.googleapis.com/v1/images:annotate?key=$apiKey";

    final bytes = File(imagePath).readAsBytesSync();
    String base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "TEXT_DETECTION"}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      final textAnnotations =
          responseJson['responses'][0]['textAnnotations'] ?? [];
      setState(() {
        _extractedText = textAnnotations.isNotEmpty
            ? textAnnotations[0]['description']
            : "No text found";
      });
    } else {
      setState(() {
        _extractedText = "Произошла ошибка при распознавании текста.";
      });
    }
  }
}
