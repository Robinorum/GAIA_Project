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
        // Background navigation bar
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  size: 28,
                  color: currentIndex == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => onTap(0),
              ),
              IconButton(
                icon: Icon(
                  Icons.location_on,
                  size: 28,
                  color: currentIndex == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => onTap(1),
              ),
              const SizedBox(width: 60), // Spacer for central button
              IconButton(
                icon: Icon(
                  Icons.assignment,
                  size: 28,
                  color: currentIndex == 2 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => onTap(2),
              ),
              IconButton(
                icon: Icon(
                  Icons.apps,
                  size: 28,
                  color: currentIndex == 3 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => onTap(3),
              ),
            ],
          ),
        ),
        // Central floating button
        Positioned(
          bottom: 25,
          child: GestureDetector(
            onTap: onScan,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: const Icon(
                Icons.add_a_photo,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
