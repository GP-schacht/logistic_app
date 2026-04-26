import 'package:flutter/material.dart';

class TrucksScreen extends StatelessWidget {
  const TrucksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trucks'),
      ),
      body: const Center(
        child: Text('Trucks List'),
      ),
    );
  }
}