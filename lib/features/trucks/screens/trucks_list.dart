import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/features/auth/providers/auth_provider.dart';
import 'package:logistic_app/shared/widgets/bottom_navegation.dart';
import '../models/trucks.dart';
import '../providers/trucks_provider.dart';
import '../../../core/providers/auth_provider.dart';

class TruckListScreen extends ConsumerWidget {
  const TruckListScreen({super.key});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final trucksAsync = ref.watch(trucksProvider);
  final role        = ref.watch(userRoleProvider);  // ← agregar  

  return MainScaffold(
    title: 'Camiones',
    // FAB solo para admin y operador
    floatingActionButton: role.canEdit
        ? FloatingActionButton.extended(
            onPressed: () => context.push('/trucks/new'),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo camión'),
          )
        : null,
    child: trucksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (trucks) => trucks.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trucks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TruckCard(truck: trucks[i]),
            ),
    ),
  );
}

  void _showFilterSheet(BuildContext context) {
    // TODO: filtrar por status
  }
}

class _TruckCard extends StatelessWidget {
  const _TruckCard({required this.truck});
  final Truck truck;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(truck.status).withOpacity(0.15),
          backgroundImage: truck.photoUrl != null
              ? NetworkImage(truck.photoUrl!) : null,
          child: truck.photoUrl == null
              ? Icon(Icons.local_shipping, color: _statusColor(truck.status))
              : null,
        ),
        title: Text(truck.plate,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          [truck.brand, truck.model, truck.year?.toString()]
              .whereType<String>().join(' · '),
        ),
        trailing: _StatusBadge(status: truck.status),
        onTap: () => context.push('/trucks/${truck.id}'),
      ),
    );
  }

  Color _statusColor(TruckStatus s) => switch (s) {
    TruckStatus.disponible    => Colors.green,
    TruckStatus.en_ruta       => Colors.blue,
    TruckStatus.mantenimiento => Colors.orange,
    TruckStatus.inactivo      => Colors.grey,
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final TruckStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TruckStatus.disponible    => ('Disponible', Colors.green),
      TruckStatus.en_ruta       => ('En ruta', Colors.blue),
      TruckStatus.mantenimiento => ('Mantenimiento', Colors.orange),
      TruckStatus.inactivo      => ('Inactivo', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text('No hay camiones registrados',
          style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      FilledButton.tonal(
        onPressed: () => context.push('/trucks/new'),
        child: const Text('Agregar primero'),
      ),
    ]),
  );
}