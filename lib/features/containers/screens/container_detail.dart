import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/container.dart';
import '../providers/containers_provider.dart';
import '../../../core/providers/auth_provider.dart';

class ContainerDetailScreen extends ConsumerWidget {
  const ContainerDetailScreen({super.key, required this.containerId});
  final String containerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerAsync = ref.watch(containerByIdProvider(containerId));
    final role           = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle contenedor'),
        actions: [
          if (role.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('/containers/$containerId/edit'),
            ),
          if (role.canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: containerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (container) => container == null
            ? const Center(child: Text('Contenedor no encontrado'))
            : _ContainerDetailBody(container: container),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contenedor'),
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
      await ref.read(containersRepoProvider).delete(containerId);
      context.go('/containers');
    }
  }
}

class _ContainerDetailBody extends StatelessWidget {
  const _ContainerDetailBody({required this.container});
  final ContainerModel container;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(container: container),
        const SizedBox(height: 12),
        _InfoCard(container: container),
        if (container.notes != null) ...[
          const SizedBox(height: 12),
          _NotesCard(notes: container.notes!),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.container});
  final ContainerModel container;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _statusColor(container.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_outlined,
                color: _statusColor(container.status), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(container.containerNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _StatusBadge(status: container.status),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Color _statusColor(ContainerStatus s) => switch (s) {
    ContainerStatus.en_patio    => Colors.grey,
    ContainerStatus.en_puerto   => Colors.blue,
    ContainerStatus.en_transito => Colors.orange,
    ContainerStatus.entregado   => Colors.green,
  };
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.container});
  final ContainerModel container;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          _InfoRow(
            icon: Icons.tag,
            label: 'Número BL',
            value: container.blNumber ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Tipo',
            value: container.type?.name.toUpperCase() ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.scale_outlined,
            label: 'Peso',
            value: container.weightKg != null
                ? '${container.weightKg} kg'
                : '—',
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ubicación actual',
            value: container.currentLocation ?? '—',
          ),
        ]),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notas',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(notes,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 46, color: Colors.grey.withOpacity(0.15));
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ContainerStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ContainerStatus.en_patio    => ('En patio',    Colors.grey),
      ContainerStatus.en_puerto   => ('En puerto',   Colors.blue),
      ContainerStatus.en_transito => ('En tránsito', Colors.orange),
      ContainerStatus.entregado   => ('Entregado',   Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}