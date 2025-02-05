import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'prediction_screen.dart';
import '../services/prediction_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final PredictionService _predictionService = PredictionService();
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isLoading = false; // État du chargement

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

  Future<void> toggleFlash() async {
    if (_cameraController.value.isInitialized) {
      _isFlashOn = !_isFlashOn;
      await _cameraController.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    }
  }

  Future<void> capturePhoto() async {
    if (!_cameraController.value.isInitialized) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Affiche une boîte de dialogue avec un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false, // Empêche la fermeture en cliquant à côté
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("Scanning ..."),
            ],
          ),
        ),
      );

      final XFile photo = await _cameraController.takePicture();
      final Map<String, dynamic> artworkData =
          await _predictionService.predictArtwork(photo.path);

      // Ferme la boîte de dialogue de chargement
      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });

      if (artworkData['id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionScreen(
              artworkData: artworkData,
            ),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('No matches found'),
            content: Text('No recognized artwork in the image.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Ferme la boîte de dialogue en cas d'erreur
      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la capture: $e')),
      );
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController),
            ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 20,
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
                size: 30,
              ),
              onPressed: toggleFlash,
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap to capture a photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : capturePhoto, // Désactive le bouton si en chargement
                  child: Icon(Icons.camera_alt, size: 36, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
