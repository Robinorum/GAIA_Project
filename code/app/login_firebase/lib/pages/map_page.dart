import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Map"), automaticallyImplyLeading: false),
      body: Center(
        child: Image.asset(
          'assets/images/CarteToulon.png',
          fit: BoxFit.cover,
          height: 300,
        ),
      ),
    );
  }
}
