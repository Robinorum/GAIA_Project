import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'prediction_screen.dart';
import '../services/prediction_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final PredictionService _predictionService = PredictionService();
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isLoading = false; // État du chargement
  double _cameraAspectRatio = 1.0;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
        _cameraAspectRatio = 1 / _cameraController.value.aspectRatio;
      });
    }
  }

  Future<void> toggleFlash() async {
    if (_cameraController.value.isInitialized) {
      _isFlashOn = !_isFlashOn;
      await _cameraController
          .setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
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
              Text("Scan en cours ..."),
            ],
          ),
        ),
      );

      final XFile photo = await _cameraController.takePicture();
      final Map<String, dynamic> artworkData =
          await _predictionService.predictArtwork(photo.path);

      // Ferme la boîte de dialogue de chargement
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });

      if (artworkData['id'] != null) {
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => PredictionScreen(
              artworkData: artworkData,
            ),
          ),
        );
      } else {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error de reconnaissance'),
            content: const Text('Aucun tableau reconnu à partir de l\'image'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Ferme la boîte de dialogue en cas d'erreur
      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      setState(() {
        _isLoading = false;
      });

      debugPrint('Erreur lors de la capture: $e');
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
            Center(
              child: ClipRect(
                child: AspectRatio(
                  aspectRatio: _cameraAspectRatio, // Garde un carré
                  child: CameraPreview(_cameraController),
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 28),
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
                const Text(
                  'Appuyez pour scanner l\'art !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: _isLoading
                      ? null
                      : capturePhoto, // Désactive le bouton si en chargement
                  child: const Icon(Icons.camera_alt,
                      size: 36, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
