import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'prediction_screen.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> capturePhoto() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      final XFile photo = await _cameraController.takePicture();
      var uri = Uri.parse('http://127.0.0.1:5000/predict');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', photo.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);

        if (data['prediction'] != null && data['prediction'] is List) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PredictionScreen(
                imagePath: photo.path,
                prediction: List<String>.from(data['prediction']),
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Aucune correspondance trouvée'),
                content: Text('Aucune œuvre d\'art reconnue dans l\'image.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        print('Erreur lors de l\'envoi de la photo');
      }
    } catch (e) {
      print('Erreur lors de la capture de la photo : $e');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Art Scanner')),
      body: Column(
        children: [
          if (_isCameraInitialized) CameraPreview(_cameraController),
          ElevatedButton(
            onPressed: capturePhoto,
            child: Text('Scan'),
          ),
        ],
      ),
    );
  }
}