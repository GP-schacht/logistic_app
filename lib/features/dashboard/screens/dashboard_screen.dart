import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logistic_app/shared/widgets/bottom_navegation.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_stats.dart';
import '../../../core/config/supabase_config.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activar realtime
    ref.watch(dashboardRealtimeProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return MainScaffold(
   title: 'Dashboard',
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => ref.invalidate(dashboardStatsProvider),
      ),
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          await supabase.auth.signOut();
          if (context.mounted) context.go('/login');
        },
      ),
    ],
    child: statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(dashboardStatsProvider)),
      data: (stats) => _DashboardBody(stats: stats),
    ),
  );
}
}

// ── Body ─────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {}, // el botón de refresh invalida el provider
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Camiones'),
          const SizedBox(height: 8),
          _TruckStatusRow(stats: stats),
          const SizedBox(height: 20),

          _SectionTitle('Contenedores'),
          const SizedBox(height: 8),
          _ContainerStatusRow(stats: stats),
          const SizedBox(height: 20),

          _SectionTitle('Viajes de hoy'),
          const SizedBox(height: 8),
          _TripsTodayRow(stats: stats),
          const SizedBox(height: 20),

          _SectionTitle('Actividad semanal'),
          const SizedBox(height: 8),
          _WeeklyChart(activity: stats.weeklyActivity),
          const SizedBox(height: 20),

          _SectionTitle('Top conductores'),
          const SizedBox(height: 8),
          _DriverLeaderboard(drivers: stats.topDrivers),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Sección: camiones ────────────────────────────────────

class _TruckStatusRow extends StatelessWidget {
  const _TruckStatusRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(
        label: 'Disponibles',
        value: stats.trucksAvailable,
        icon: Icons.check_circle_outline,
        color: Colors.green,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'En ruta',
        value: stats.trucksOnRoute,
        icon: Icons.directions,
        color: Colors.blue,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'Mantenimiento',
        value: stats.trucksMaintenance,
        icon: Icons.build_outlined,
        color: Colors.orange,
      )),
    ]);
  }
}

// ── Sección: contenedores ────────────────────────────────

class _ContainerStatusRow extends StatelessWidget {
  const _ContainerStatusRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(
        label: 'En patio',
        value: stats.containersInYard,
        icon: Icons.warehouse_outlined,
        color: Colors.grey,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'En tránsito',
        value: stats.containersInTransit,
        icon: Icons.local_shipping_outlined,
        color: Colors.blue,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'Entregados',
        value: stats.containersDelivered,
        icon: Icons.done_all,
        color: Colors.green,
      )),
    ]);
  }
}

// ── Sección: viajes de hoy ───────────────────────────────

class _TripsTodayRow extends StatelessWidget {
  const _TripsTodayRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(
        label: 'Programados',
        value: stats.tripsScheduled,
        icon: Icons.schedule,
        color: Colors.purple,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'En curso',
        value: stats.tripsInProgress,
        icon: Icons.play_circle_outline,
        color: Colors.blue,
      )),
      const SizedBox(width: 8),
      Expanded(child: _StatCard(
        label: 'Completados',
        value: stats.tripsCompleted,
        icon: Icons.task_alt,
        color: Colors.green,
      )),
    ]);
  }
}

// ── Widget: tarjeta de stat ──────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text('$value',
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Widget: gráfica semanal ──────────────────────────────

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.activity});
  final List<WeeklyActivity> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Sin datos esta semana')),
        ),
      );
    }

    final maxVal = activity
        .map((a) => a.scheduled)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Viajes por día',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: activity.map((a) {
                  final completedH = maxVal > 0
                      ? (a.completed / maxVal) * 100 : 0.0;
                  final scheduledH = maxVal > 0
                      ? (a.scheduled / maxVal) * 100 : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Barra programados (fondo)
                          Stack(alignment: Alignment.bottomCenter, children: [
                            Container(
                              height: scheduledH,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Barra completados (encima)
                            Container(
                              height: completedH,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          Text(a.day,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Leyenda
            Row(children: [
              _LegendDot(color: Colors.blue, label: 'Completados'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.blue.withOpacity(0.2), label: 'Programados'),
            ]),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }
}

// ── Widget: leaderboard conductores ─────────────────────

class _DriverLeaderboard extends StatelessWidget {
  const _DriverLeaderboard({required this.drivers});
  final List<DriverPerformance> drivers;

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sin datos de conductores')),
        ),
      );
    }

    return Card(
      child: Column(
        children: drivers.asMap().entries.map((entry) {
          final i      = entry.key;
          final driver = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _rankColor(i).withOpacity(0.15),
              child: Text('${i + 1}',
                  style: TextStyle(color: _rankColor(i),
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(driver.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: LinearProgressIndicator(
              value: driver.completionRate,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${driver.tripsCompleted}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('viajes',
                    style: TextStyle(fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _rankColor(int i) => switch (i) {
    0 => const Color(0xFFFFB800), // oro
    1 => const Color(0xFF9E9E9E), // plata
    2 => const Color(0xFFCD7F32), // bronce
    _ => Colors.blue,
  };
}

// ── Helpers ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold,
                color: Colors.grey.shade700));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text('No se pudo cargar el dashboard',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(error,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.tonal(
            onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}