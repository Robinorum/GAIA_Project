import 'dart:ui';
import 'package:flutter/material.dart';

Future<void> showBlurryDialog({
  required BuildContext context,
  required Widget title,
  required String content,
  required String buttonText,
  required double triangleAlignment,
  required double verticalAlignment,
  bool pointUp = false,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation1, animation2) {
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          Align(
            alignment: Alignment(0.0, verticalAlignment),
            child: CustomPaint(
              painter: BubblePainter(
                triangleAlignment: triangleAlignment,
                pointUp: pointUp,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        child: title,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.left,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(buttonText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}



class BubblePainter extends CustomPainter {
  final double triangleAlignment;
  final bool pointUp; // Nouveau paramètre pour pointer vers le haut

  BubblePainter({
    required this.triangleAlignment,
    this.pointUp = false, // Par défaut pointe vers le bas
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple // Couleur cohérente avec le thème
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final double triangleX = triangleAlignment * size.width;
    const double baseHalf = 30;
    const double height = 30;
    const double offset = 6;

    if (pointUp) {
      // Triangle pointant vers le haut (pour le profil et refresh)
      path.moveTo(triangleX - baseHalf, -offset);
      path.lineTo(triangleX, -height - offset);
      path.lineTo(triangleX + baseHalf, -offset);
    } else {
      // Triangle pointant vers le bas (pour la navbar)
      path.moveTo(triangleX - baseHalf, size.height + offset);
      path.lineTo(triangleX, size.height + height + offset);
      path.lineTo(triangleX + baseHalf, size.height + offset);
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
