import 'package:flutter/material.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
      ),
      body: const Center(
        child: Text('Drivers List'),
      ),
    );
  }
}