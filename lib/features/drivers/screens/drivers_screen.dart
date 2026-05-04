import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/driver.dart';
import '../providers/drivers_providers.dart';
import '../../../shared/widgets/bottom_navegation.dart';
import '../../../core/providers/auth_provider.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync    = ref.watch(driversProvider);
    final pendingAsync    = ref.watch(unassignedProfilesProvider);
    final role            = ref.watch(userRoleProvider);

    return MainScaffold(
      title: 'Conductores',
      // FAB solo si hay pendientes y el usuario puede editar
      floatingActionButton: role.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showPendingSheet(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Asignar conductor'),
            )
          : null,
      child: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (drivers) => CustomScrollView(
          slivers: [

            // ── Sección: Por asignar ──────────────────────
            pendingAsync.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error:   (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (pending) {
                if (pending.isEmpty || !role.canEdit) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _PendingSection(
                    pending: pending,
                    onTap: (profile) => _openAssignForm(context, profile),
                  ),
                );
              },
            ),

            // ── Sección: Flota activa ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Flota activa',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600)),
              ),
            ),

            drivers.isEmpty
                ? SliverFillRemaining(child: _EmptyState())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _DriverCard(
                        driver: drivers[i],
                        canEdit: role.canEdit,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet con lista de pendientes
  void _showPendingSheet(BuildContext context, WidgetRef ref) {
    final pending = ref.read(unassignedProfilesProvider).valueOrNull ?? [];

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay choferes pendientes de asignar'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PendingBottomSheet(
        pending: pending,
        onSelect: (profile) {
          Navigator.pop(context);
          _openAssignForm(context, profile);
        },
      ),
    );
  }

 void _openAssignForm(BuildContext context, Map<String, dynamic> profile) {
  if (profile['id'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: perfil sin ID')),
    );
    return;
  }
  context.push('/drivers/assign', extra: profile);
}
}

// ── Sección banner de pendientes ─────────────────────────

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.pending, required this.onTap});
  final List<Map<String, dynamic>> pending;
  final void Function(Map<String, dynamic>) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              const Icon(Icons.pending_actions_outlined,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text('Por asignar (${pending.length})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 13)),
            ]),
          ),
          ...pending.take(3).map((p) => ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.withOpacity(0.15),
              child: Text(
                (p['full_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            title: Text(p['full_name'] as String? ?? 'Sin nombre',
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(p['phone'] as String? ?? 'Sin teléfono',
                style: const TextStyle(fontSize: 11)),
            trailing: TextButton(
              onPressed: () => onTap(p),
              child: const Text('Asignar'),
            ),
          )),
          if (pending.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('+${pending.length - 3} más pendientes',
                  style: TextStyle(
                      fontSize: 12, color: Colors.orange.shade700)),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Bottom sheet completo de pendientes ──────────────────

class _PendingBottomSheet extends StatelessWidget {
  const _PendingBottomSheet(
      {required this.pending, required this.onSelect});
  final List<Map<String, dynamic>> pending;
  final void Function(Map<String, dynamic>) onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              const Icon(Icons.person_add_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Seleccionar chofer',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${pending.length} disponibles',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = pending[i];
                final name = p['full_name'] as String? ?? 'Sin nombre';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(name[0].toUpperCase(),
                          style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                        p['phone'] as String? ?? 'Sin teléfono',
                        style: const TextStyle(fontSize: 12)),
                    trailing: FilledButton.tonal(
                      onPressed: () => onSelect(p),
                      child: const Text('Asignar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.drive_eta_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No hay conductores activos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver, required this.canEdit});

  final Driver driver;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade50,
          foregroundImage:
              driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
          child: driver.photoUrl == null
              ? Text(
                  driver.fullName.isNotEmpty
                      ? driver.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(driver.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (driver.phone != null) Text(driver.phone!),
            const SizedBox(height: 4),
            Text(
              driver.hasDefaultTruck
                  ? 'Camión: ${driver.defaultTruckPlate ?? 'Sin placa'}'
                  : 'Sin camión asignado',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: canEdit
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  // Placeholder for edit action
                },
              )
            : null,
      ),
    );
  }
}