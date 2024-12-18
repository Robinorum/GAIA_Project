import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  color: currentIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => onTap(0),
            ),
            IconButton(
              icon: Icon(Icons.location_on,
                  color: currentIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () => onTap(1),
            ),
            const SizedBox(width: 48), // Espace pour le bouton flottant
            IconButton(
              icon: Icon(Icons.assignment,
                  color: currentIndex == 2 ? Colors.blue : Colors.grey),
              onPressed: () => onTap(2),
            ),
            IconButton(
              icon: Icon(Icons.apps,
                  color: currentIndex == 3 ? Colors.blue : Colors.grey),
              onPressed: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}
