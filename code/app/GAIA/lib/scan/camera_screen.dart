import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'prediction_screen.dart';
import '../services/prediction_service.dart';
import '../services/user_service.dart';
import '../services/museum_service.dart';
import '../provider/user_provider.dart';
import '../model/museum.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final PredictionService _predictionService = PredictionService();
  final UserService _userService = UserService();
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isLoading = false; // État du chargement
  double _cameraAspectRatio = 1.0;
  
  // Variables pour la quête
  Museum? _currentMuseum;
  String? _currentQuestImageUrl;
  bool _isLoadingQuest = false;
  bool _isInMuseum = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _checkCurrentMuseum();
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

  Future<void> _checkCurrentMuseum() async {
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";
      
      // Récupérer le musée actuel depuis la BDD
      final currentMuseumId = await _userService.getCurrentMuseum(uid);
      
      if (currentMuseumId != null) {
        // Récupérer les détails du musée
        final museums = await MuseumService().fetchMuseums();
        final museum = museums.firstWhere(
          (m) => m.officialId == currentMuseumId,
          orElse: () => throw Exception("Musée non trouvé"),
        );
        
        setState(() {
          _currentMuseum = museum;
          _isInMuseum = true;
        });
        
        await _loadCurrentQuest();
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification du musée actuel: $e");
    }
  }

  Future<void> _loadCurrentQuest() async {
    if (!_isInMuseum || _currentMuseum == null) return;
    
    setState(() {
      _isLoadingQuest = true;
    });

    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      final uid = user?.id ?? "default_uid";

      final imageUrl = await _userService.initQuestMuseum(
        uid,
        _currentMuseum!.officialId,
      );

      if (!mounted) return;

      if (imageUrl == "QUEST_ALREADY_COMPLETED") {
        // Marquer la quête comme complétée et charger la suivante
        await _loadCurrentQuest(); // Récursif pour charger la suivante
      } else if (imageUrl == "NO_QUEST") {
        setState(() {
          _currentQuestImageUrl = null;
          _isLoadingQuest = false;
        });
      } else if (!imageUrl.startsWith("Erreur")) {
        setState(() {
          _currentQuestImageUrl = imageUrl;
          _isLoadingQuest = false;
        });
      } else {
        setState(() {
          _currentQuestImageUrl = null;
          _isLoadingQuest = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentQuestImageUrl = null;
        _isLoadingQuest = false;
      });
    }
  }

  Widget _buildQuestOverlay() {
    if (!_isInMuseum || _currentMuseum == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 110,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.museum, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Quête - ${_currentMuseum!.title}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingQuest)
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
            else if (_currentQuestImageUrl != null)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentQuestImageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                          child: const Icon(Icons.error, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Trouvez cette œuvre dans le musée",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                "Aucune quête disponible",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
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
        ).then((_) {
          // Recharger la quête quand on revient de PredictionScreen
          if (_isInMuseum) {
            _loadCurrentQuest();
          }
        });
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
          // Overlay de la quête
          _buildQuestOverlay(),
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
