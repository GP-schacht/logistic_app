import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/core/providers/auth_provider.dart';
import '../models/driver.dart';
import '../providers/drivers_providers.dart';

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
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (driver) => driver == null
            ? const Center(child: Text('Conductor no encontrado'))
            : _DriverDetailBody(driver: driver),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar conductor'),
        content: const Text('Se eliminará el conductor y su perfil. ¿Continuar?'),
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

class _DriverDetailBody extends StatelessWidget {
  const _DriverDetailBody({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final expiry     = driver.licenseExpiry;
    final formatted  = '${expiry.day.toString().padLeft(2,'0')}/'
                       '${expiry.month.toString().padLeft(2,'0')}/'
                       '${expiry.year}';
    final licenseColor = driver.isLicenseExpired
        ? Colors.red
        : driver.isLicenseExpiringSoon ? Colors.orange : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header con avatar grande
        Center(
          child: Column(children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: driver.photoUrl != null
                  ? NetworkImage(driver.photoUrl!) : null,
              backgroundColor: Colors.blue.shade100,
              child: driver.photoUrl == null
                  ? Text(driver.fullName[0].toUpperCase(),
                      style: TextStyle(fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(driver.fullName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _StatusBadge(status: driver.status),
          ]),
        ),
        const SizedBox(height: 24),

        // Alerta licencia
        if (driver.isLicenseExpired || driver.isLicenseExpiringSoon)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: licenseColor!.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: licenseColor.withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: licenseColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.isLicenseExpired
                      ? 'Licencia vencida — requiere renovación inmediata'
                      : 'Licencia vence en menos de 30 días',
                  style: TextStyle(color: licenseColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),

        // Info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _InfoRow(Icons.credit_card,   'Licencia',          driver.licenseNumber, licenseColor),
              _InfoRow(Icons.calendar_today,'Vencimiento',       formatted,            licenseColor),
              _InfoRow(Icons.phone,         'Teléfono',          driver.phone ?? '—',  null),
              _InfoRow(Icons.emergency,     'Emergencia',        driver.emergencyContact ?? '—', null),
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value, this.valueColor);
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: valueColor)),
          ]),
        ),
      ]),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}