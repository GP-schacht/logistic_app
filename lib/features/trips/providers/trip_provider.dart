import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../models/trip.dart';

// Lista filtrada por rol automáticamente
final tripsProvider = FutureProvider<List<Trip>>((ref) async {
  ref.watch(authStateProvider); // re-ejecuta al cambiar sesión

  final uid  = supabase.auth.currentUser?.id;
  if (uid == null) return [];

  // Obtener rol
  final profile = await supabase
      .from('profiles')
      .select('role')
      .eq('id', uid)
      .single();
  final role = profile['role'] as String;

  late List rows;

  if (role == 'chofer') {
    // Chofer — solo sus viajes via driver_id
    final driver = await supabase
        .from('drivers')
        .select('id')
        .eq('profile_id', uid)
        .maybeSingle();

    if (driver == null) return [];

    rows = await supabase
        .from('trips')
        .select('''
          *,
          trucks(plate),
          containers(container_number),
          drivers(profiles(full_name))
        ''')
        .eq('driver_id', driver['id'])
        .order('created_at', ascending: false);
  } else {
    // Admin y operador — todos los viajes
    rows = await supabase
        .from('trips')
        .select('''
          *,
          trucks(plate),
          containers(container_number),
          drivers(profiles(full_name))
        ''')
        .order('created_at', ascending: false);
  }

  return rows.map((r) => Trip.fromMap(r)).toList();
});

// Un viaje por id
final tripByIdProvider = FutureProvider.family<Trip?, String>((ref, id) async {
  final row = await supabase
      .from('trips')
      .select('''
        *,
        trucks(plate, brand, model),
        containers(container_number, type, weight_kg),
        drivers(profiles(full_name, phone))
      ''')
      .eq('id', id)
      .maybeSingle();

  return row == null ? null : Trip.fromMap(row);
});

// Contenedores disponibles para asignar a un viaje
final availableContainersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await supabase
      .from('containers')
      .select('id, container_number, type, weight_kg')
      .inFilter('status', ['en_patio', 'en_puerto'])
      .order('container_number');
  return List<Map<String, dynamic>>.from(rows);
});

// Conductores disponibles
final availableDriversProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Conductores sin viaje activo
  final activeDriverIds = await supabase
      .from('trips')
      .select('driver_id')
      .inFilter('status', ['programado', 'en_curso']);

  final busyIds = (activeDriverIds as List)
      .map((r) => r['driver_id'] as String)
      .toList();

  var query = supabase
      .from('drivers')
      .select('id, default_truck_id, profiles(full_name), trucks(plate)');

  final rows = busyIds.isEmpty
      ? await query.order('created_at')
      : await query
          .not('id', 'in', busyIds )
          .order('created_at');

  return List<Map<String, dynamic>>.from(rows);
});

// Repositorio
class TripsRepository {
  Future<void> create(Trip trip) async {
    final createdBy = supabase.auth.currentUser!.id;
    await supabase.from('trips').insert({
      ...trip.toMap(),
      'created_by': createdBy,
    });
  }

  Future<void> updateStatus(String tripId, TripStatus status) async {
    final now = DateTime.now().toIso8601String();
    await supabase.from('trips').update({
      'status': status.name,
      if (status == TripStatus.en_curso)   'started_at':   now,
      if (status == TripStatus.completado) 'completed_at': now,
    }).eq('id', tripId);
  }

  Future<void> cancel(String tripId) async {
    await supabase.from('trips').update({
      'status': 'cancelado',
    }).eq('id', tripId);
  }
}

final tripsRepoProvider = Provider((_) => TripsRepository());

final availableTrucksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await supabase
      .from('trucks')
      .select('id, plate, brand, model, status')
      .inFilter('status', ['disponible'])
      .order('plate');
  return List<Map<String, dynamic>>.from(rows);
});