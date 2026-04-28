import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/core/providers/auth_provider.dart';
import '../models/driver.dart';
import '../providers/drivers_providers.dart';
import '../../../shared/widgets/bottom_navegation.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);
    final role = ref.watch(userRoleProvider);

    return MainScaffold(
      title: 'Conductores',
      child: driversAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (drivers) => drivers.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: drivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DriverCard(
                  driver: drivers[i],
                  canEdit: role.canEdit,),
                 
              ),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canEdit? () => context.push('/drivers/${driver.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              _DriverAvatar(driver: driver),
              const SizedBox(width: 12),

              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(driver.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        _StatusBadge(status: driver.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Teléfono
                    if (driver.phone != null)
                      _InfoChip(
                          icon: Icons.phone_outlined, text: driver.phone!),
                    const SizedBox(height: 2),
                    // Licencia
                    _LicenseChip(driver: driver),
                    // Contacto emergencia
                    if (driver.emergencyContact != null) ...[
                      const SizedBox(height: 2),
                      _InfoChip(
                          icon: Icons.emergency_outlined,
                          text: driver.emergencyContact!),
                    ],
                  ],
                ),
              ),
              if(canEdit)
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: driver.photoUrl != null
              ? NetworkImage(driver.photoUrl!) : null,
          backgroundColor: Colors.blue.shade100,
          child: driver.photoUrl == null
              ? Text(
                  driver.fullName.isNotEmpty
                      ? driver.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700),
                )
              : null,
        ),
        // Indicador de estado online
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color: _statusDotColor(driver.status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusDotColor(String status) => switch (status) {
    'en_curso'   => Colors.blue,
    'programado' => Colors.orange,
    _            => Colors.green,
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'en_curso'   => ('En ruta',     Colors.blue),
      'programado' => ('Programado',  Colors.orange),
      _            => ('Disponible',  Colors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _LicenseChip extends StatelessWidget {
  const _LicenseChip({required this.driver});
  final Driver driver;

  @override
  Widget build(BuildContext context) {
    final color = driver.isLicenseExpired
        ? Colors.red
        : driver.isLicenseExpiringSoon
            ? Colors.orange
            : Colors.grey.shade600;

    final expiry = driver.licenseExpiry;
    final formatted =
        '${expiry.day.toString().padLeft(2, '0')}/'
        '${expiry.month.toString().padLeft(2, '0')}/'
        '${expiry.year}';

    return Row(children: [
      Icon(Icons.credit_card_outlined, size: 13, color: color),
      const SizedBox(width: 4),
      Text('${driver.licenseNumber} · vence $formatted',
          style: TextStyle(fontSize: 12, color: color)),
      if (driver.isLicenseExpired) ...[
        const SizedBox(width: 4),
        Icon(Icons.warning_amber_rounded, size: 13, color: color),
      ],
    ]);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Expanded(
        child: Text(text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('No hay conductores registrados',
            style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () => context.push('/drivers/new'),
          child: const Text('Agregar conductor'),
        ),
      ]),
    );
  }
}