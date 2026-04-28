import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/dashboard_stats.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  // Lanzar todas las queries en paralelo
  final results = await Future.wait([
    _fetchTruckStats(),
    _fetchContainerStats(),
    _fetchTodayTrips(),
    _fetchDriverPerformance(),
    _fetchWeeklyActivity(),
  ]);

  final trucks     = results[0] as Map<String, int>;
  final containers = results[1] as Map<String, int>;
  final trips      = results[2] as Map<String, int>;
  final drivers    = results[3] as List<DriverPerformance>;
  final weekly     = results[4] as List<WeeklyActivity>;

  return DashboardStats(
    trucksAvailable:    trucks['disponible']   ?? 0,
    trucksOnRoute:      trucks['en_ruta']      ?? 0,
    trucksMaintenance:  trucks['mantenimiento'] ?? 0,
    containersInYard:      containers['en_patio']    ?? 0,
    containersInTransit:   containers['en_transito'] ?? 0,
    containersDelivered:   containers['entregado']   ?? 0,
    tripsScheduled:    trips['programado'] ?? 0,
    tripsInProgress:   trips['en_curso']   ?? 0,
    tripsCompleted:    trips['completado'] ?? 0,
    topDrivers:        drivers,
    weeklyActivity:    weekly,
  );
});

// Realtime: refresca el provider cuando cambia trucks o trips
final dashboardRealtimeProvider = StreamProvider<void>((ref) {
  final stream = supabase
      .channel('dashboard')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trips',
        callback: (_) => ref.invalidate(dashboardStatsProvider),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'trucks',
        callback: (_) => ref.invalidate(dashboardStatsProvider),
      )
      .subscribe();

  ref.onDispose(() => supabase.removeChannel(stream));
  return const Stream.empty();
});

// ── Queries privadas ─────────────────────────────────────

Future<Map<String, int>> _fetchTruckStats() async {
  final rows = await supabase
      .from('trucks')
      .select('status');

  final Map<String, int> counts = {};
  for (final row in rows) {
    final status = row['status'] as String;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

Future<Map<String, int>> _fetchContainerStats() async {
  final rows = await supabase
      .from('containers')
      .select('status');

  final Map<String, int> counts = {};
  for (final row in rows) {
    final status = row['status'] as String;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

Future<Map<String, int>> _fetchTodayTrips() async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day).toIso8601String();
  final end   = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

  final rows = await supabase
      .from('trips')
      .select('status')
      .gte('created_at', start)
      .lte('created_at', end);

  final Map<String, int> counts = {};
  for (final row in rows) {
    final status = row['status'] as String;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

Future<List<DriverPerformance>> _fetchDriverPerformance() async {
  final rows = await supabase
      .from('trips')
      .select('driver_id, status, drivers(profiles(full_name))')
      .eq('status', 'completado');

  // Agrupar por driver
  final Map<String, Map<String, dynamic>> grouped = {};
  for (final row in rows) {
    final driverId = row['driver_id'] as String;
    final name = row['drivers']?['profiles']?['full_name'] as String? ?? 'Sin nombre';

    grouped[driverId] ??= {'name': name, 'completed': 0, 'total': 0};
    grouped[driverId]!['completed'] = (grouped[driverId]!['completed'] as int) + 1;
  }

  // Total de viajes por driver (para calcular tasa)
  final allTrips = await supabase
      .from('trips')
      .select('driver_id');

  for (final row in allTrips) {
    final driverId = row['driver_id'] as String;
    if (grouped.containsKey(driverId)) {
      grouped[driverId]!['total'] = (grouped[driverId]!['total'] as int) + 1;
    }
  }

  final list = grouped.entries.map((e) {
    final total     = e.value['total'] as int;
    final completed = e.value['completed'] as int;
    return DriverPerformance(
      driverId:       e.key,
      name:           e.value['name'] as String,
      tripsCompleted: completed,
      completionRate: total > 0 ? completed / total : 0,
    );
  }).toList()
    ..sort((a, b) => b.tripsCompleted.compareTo(a.tripsCompleted));

  return list.take(5).toList(); // top 5
}

Future<List<WeeklyActivity>> _fetchWeeklyActivity() async {
  final now  = DateTime.now();
  final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  // Últimos 7 días
  final List<WeeklyActivity> result = [];

  for (int i = 6; i >= 0; i--) {
    final date  = now.subtract(Duration(days: i));
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end   = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final rows = await supabase
        .from('trips')
        .select('status')
        .gte('created_at', start)
        .lte('created_at', end);

    final completed = rows.where((r) => r['status'] == 'completado').length;
    final scheduled = rows.length;

    result.add(WeeklyActivity(
      day:       days[date.weekday - 1],
      completed: completed,
      scheduled: scheduled,
    ));
  }

  return result;
}