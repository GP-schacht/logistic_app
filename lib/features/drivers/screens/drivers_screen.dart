import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/driver.dart';
import '../providers/drivers_providers.dart';
import '../../../core/providers/auth_provider.dart';

class DriverDetailScreen extends ConsumerWidget {
  const DriverDetailScreen({super.key, required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverByIdProvider(driverId));
    final role        = ref.watch(userRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle conductor'),
        actions: [
          if (role.canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/drivers/$driverId/edit'),
            ),
          if (role.canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: driverAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(driverByIdProvider(driverId)),
        ),
        data: (driver) => driver == null
            ? const _NotFound()
            : _DriverDetailBody(driver: driver),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conductor'),
        content: const Text(
            'Se eliminará el conductor y su perfil. Esta acción no se puede deshacer.'),
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
      await ref.read(driversRepoProvider).delete(driverId);
      context.go('/drivers');
    }
  }
}

// ── Body principal ───────────────────────────────────────

class _DriverDetailBody extends StatelessWidget {
  const _DriverDetailBody({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(driver: driver),
        const SizedBox(height: 12),
        _LicenseAlert(driver: driver),
        _InfoCard(driver: driver),
        const SizedBox(height: 12),
        _TruckCard(driver: driver),
      ],
    );
  }
}

// ── Header con avatar y estado ───────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: driver.photoUrl != null
                  ? NetworkImage(driver.photoUrl!) : null,
              backgroundColor: Colors.blue.shade100,
              child: driver.photoUrl == null
                  ? Text(
                      driver.fullName.isNotEmpty
                          ? driver.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700),
                    )
                  : null,
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                  color: _statusColor(driver.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 16),

          // Nombre y estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _StatusBadge(status: driver.status),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'en_curso'   => Colors.blue,
    'programado' => Colors.orange,
    _            => Colors.green,
  };
}

// ── Alerta de licencia ───────────────────────────────────

class _LicenseAlert extends StatelessWidget {
  const _LicenseAlert({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    if (!driver.isLicenseExpired && !driver.isLicenseExpiringSoon) {
      return const SizedBox.shrink();
    }

    final color = driver.isLicenseExpired ? Colors.red : Colors.orange;
    final msg   = driver.isLicenseExpired
        ? 'Licencia vencida — requiere renovación inmediata'
        : 'Licencia vence en menos de 30 días';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ]),
    );
  }
}

// ── Card de información personal ─────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final expiry    = driver.licenseExpiry;
    final formatted = '${expiry.day.toString().padLeft(2, '0')}/'
                      '${expiry.month.toString().padLeft(2, '0')}/'
                      '${expiry.year}';
    final licenseColor = driver.isLicenseExpired
        ? Colors.red
        : driver.isLicenseExpiringSoon
            ? Colors.orange : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          _InfoRow(
            icon:  Icons.credit_card_outlined,
            label: 'Licencia',
            value: driver.licenseNumber,
            color: licenseColor,
          ),
          _Divider(),
          _InfoRow(
            icon:  Icons.calendar_today_outlined,
            label: 'Vencimiento',
            value: formatted,
            color: licenseColor,
          ),
          _Divider(),
          _InfoRow(
            icon:  Icons.phone_outlined,
            label: 'Teléfono',
            value: driver.phone ?? '—',
          ),
          _Divider(),
          _InfoRow(
            icon:  Icons.emergency_outlined,
            label: 'Emergencia',
            value: driver.emergencyContact ?? '—',
          ),
        ]),
      ),
    );
  }
}

// ── Card de camión base ──────────────────────────────────

class _TruckCard extends StatelessWidget {
  const _TruckCard({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final hasTruck = driver.hasDefaultTruck;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: hasTruck
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: hasTruck ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Camión base',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  hasTruck
                      ? driver.defaultTruckPlate ?? 'Asignado'
                      : 'Sin camión base asignado',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: hasTruck ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Badge de estado del camión si está en mantenimiento
          if (hasTruck && driver.defaultTruckPlate != null)
            _TruckStatusBadge(plate: driver.defaultTruckPlate!),
        ]),
      ),
    );
  }
}

class _TruckStatusBadge extends StatelessWidget {
  const _TruckStatusBadge({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(plate,
          style: const TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   color;

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
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: color)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1, indent: 46, color: Colors.grey.withOpacity(0.15));
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'en_curso'   => ('En ruta',    Colors.blue),
      'programado' => ('Programado', Colors.orange),
      _            => ('Disponible', Colors.green),
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

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Conductor no encontrado'),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
      const SizedBox(height: 12),
      Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 16),
      FilledButton.tonal(
          onPressed: onRetry, child: const Text('Reintentar')),
    ]),
  );
}