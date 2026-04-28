import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/shared/widgets/bottom_navegation.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

@override
Widget build(BuildContext context, WidgetRef ref) {
  return MainScaffold(
    title: 'Conductores',
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/drivers/new'),
      icon: const Icon(Icons.add),
      label: const Text('Nuevo conductor'),
    ),
    child: const Center(child: Text('Módulo de conductores')),
  );
}
}