import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/shared/widgets/bottom_navegation.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MainScaffold(
      title: 'Viajes',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('trips/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Mensaje'),
        ),
        child: const Center(child: Text('Modulo de viajes'),),
    );
      
}
}