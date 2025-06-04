import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onScan;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Background navigation bar avec dégradé
        Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withAlpha((0.15 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 0, ),
              _buildNavItem(Icons.location_on, 1, ),
              const SizedBox(width: 70), // Spacer pour le bouton central
              _buildNavItem(Icons.assignment, 2, ),
              _buildNavItem(Icons.apps, 3, ),
            ],
          ),
        ),
        // Bouton central flottant avec effet glassmorphism
        Positioned(
          bottom: 30,
          child: GestureDetector(
            onTap: onScan,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade400,
                    Colors.purple.shade600,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withAlpha((0.4 * 255).toInt()),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withAlpha((0.2 * 255).toInt()),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Indicateur de l'onglet actif
     
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isActive 
            ? Colors.purple.shade100.withAlpha((0.3 * 255).toInt())
            : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isActive ? 30 : 26,
              color: isActive 
                ? Colors.purple.shade600 
                : Colors.grey.shade600,
            ),            
          ],
        ),
      ),
    );
  }

  /*double _getIndicatorPosition() {
    final screenWidth = 375.0; // Largeur approximative
    final itemWidth = screenWidth / 5;
    
    switch (currentIndex) {
      case 0:
        return itemWidth * 0.5;
      case 1:
        return itemWidth * 1.5;
      case 2:
        return itemWidth * 3.5;
      case 3:
        return itemWidth * 4.5;
      default:
        return itemWidth * 0.5;
    }
  }*/
}