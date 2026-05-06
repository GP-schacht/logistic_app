import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/container.dart';
import '../providers/containers_provider.dart';
import '../../../shared/widgets/bottom_navegation.dart';
import '../../../core/providers/auth_provider.dart';

class ContainersScreen extends ConsumerWidget {
  const ContainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containersAsync = ref.watch(containersProvider);
    final role            = ref.watch(userRoleProvider);

    return MainScaffold(
      title: 'Contenedores',
      floatingActionButton: role.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/containers/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo contenedor'),
            )
          : null,
      child: containersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (containers) => containers.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: containers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ContainerCard(container: containers[i]),
              ),
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.container});
  final ContainerModel container;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: _statusColor(container.status).withOpacity(0.15),
          child: Icon(Icons.inventory_2_outlined,
              color: _statusColor(container.status)),
        ),
        title: Text(container.containerNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (container.blNumber != null)
              Text('BL: ${container.blNumber}',
                  style: const TextStyle(fontSize: 12)),
            if (container.currentLocation != null)
              Text(container.currentLocation!,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: _StatusBadge(status: container.status),
        onTap: () => context.push('/containers/${container.id}'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inventory_2_outlined,
          size: 64, color: Colors.grey.shade400),
      const SizedBox(height: 16),
      Text('No hay contenedores registrados',
          style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      FilledButton.tonal(
        onPressed: () => context.push('/containers/new'),
        child: const Text('Agregar primero'),
      ),
    ]),
  );
}