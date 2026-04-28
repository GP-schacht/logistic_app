import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trucks.dart';
import '../providers/trucks_provider.dart';

class TruckDetailScreen extends ConsumerWidget {
  const TruckDetailScreen({super.key, required this.truckId});
  final String truckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final truckAsync = ref.watch(truckByIdProvider(truckId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de camión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/trucks/$truckId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: truckAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (truck) => truck == null
            ? const Center(child: Text('Camión no encontrado'))
            : _TruckDetail(truck: truck),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar camión'),
        content: const Text('Esta acción no se puede deshacer. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(trucksRepoProvider).delete(truckId);
      context.go('/trucks');
    }
  }
}

class _TruckDetail extends StatelessWidget {
  const _TruckDetail({required this.truck});
  final Truck truck;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Foto del camión
        if (truck.photoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(truck.photoUrl!, height: 200, fit: BoxFit.cover),
          ),
        const SizedBox(height: 16),

        // Info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _InfoRow('Placa',      truck.plate),
              _InfoRow('Marca',      truck.brand ?? '—'),
              _InfoRow('Modelo',     truck.model ?? '—'),
              _InfoRow('Año',        truck.year?.toString() ?? '—'),
              _InfoRow('Capacidad',  truck.capacityTons != null
                  ? '${truck.capacityTons} ton' : '—'),
              _InfoRow('Estado',     truck.status.name),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value,  style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}