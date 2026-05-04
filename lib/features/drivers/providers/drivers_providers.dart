import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/driver.dart';

// ── 1. Lista en tiempo real ──────────────────────────────
final driversProvider = StreamProvider<List<Driver>>((ref) {
  return supabase
      .from('drivers')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((rows) async {
        final enriched = await Future.wait(rows.map((row) async {
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', row['profile_id'])
              .maybeSingle();

          Map<String, dynamic>? truck;
          if (row['default_truck_id'] != null) {
            truck = await supabase
                .from('trucks')
                .select('plate, brand, model, status')
                .eq('id', row['default_truck_id'])
                .maybeSingle();
          }

          final activeTrip = await supabase
              .from('trips')
              .select('status')
              .eq('driver_id', row['id'])
              .inFilter('status', ['en_curso', 'programado'])
              .maybeSingle();

          return {
            ...row,
            'profiles': profile,
            'trucks':   truck,
            'status':   activeTrip?['status'] ?? 'disponible',
          };
        }));

        return enriched.map(Driver.fromMap).toList();
      });
});

// ── 2. Un conductor por id ───────────────────────────────
final driverByIdProvider = FutureProvider.family<Driver?, String>((ref, id) async {
  final row = await supabase
      .from('drivers')
      .select('*, profiles(*), trucks(plate, brand, model, status)')
      .eq('id', id)
      .maybeSingle();

  if (row == null) return null;

  final activeTrip = await supabase
      .from('trips')
      .select('status')
      .eq('driver_id', id)
      .inFilter('status', ['en_curso', 'programado'])
      .maybeSingle();

  return Driver.fromMap({
    ...row,
    'status': activeTrip?['status'] ?? 'disponible',
  });
});

// ── 3. Repositorio ───────────────────────────────────────
class DriversRepository {
Future<void> create({
  required String profileId,      // ← recibe el id directamente
  required String licenseNumber,
  required DateTime licenseExpiry,
  required String? emergencyContact,
  String? defaultTruckId,
}) async {
  await supabase.from('drivers').insert({
    'profile_id':        profileId,
    'license_number':    licenseNumber,
    'license_expiry':    licenseExpiry.toIso8601String().split('T').first,
    'emergency_contact': emergencyContact,
    'default_truck_id':  defaultTruckId,
  });
}

  Future<void> update({
    required String driverId,
    required String profileId,
    required String fullName,
    required String? phone,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String? emergencyContact,
    required String? defaultTruckId,
  }) async {
    await Future.wait([
      supabase.from('profiles').update({
        'full_name': fullName,
        'phone':     phone,
      }).eq('id', profileId),
      supabase.from('drivers').update({
        'license_number':    licenseNumber,
        'license_expiry':    licenseExpiry.toIso8601String().split('T').first,
        'emergency_contact': emergencyContact,
        'default_truck_id':  defaultTruckId,
      }).eq('id', driverId),
    ]);
  }

  Future<void> delete(String driverId) async {
    await supabase.from('drivers').delete().eq('id', driverId);
  }
}

// ── 4. Provider del repositorio ──────────────────────────
final driversRepoProvider = Provider((_) => DriversRepository());

// Choferes registrados pero sin fila en drivers (pendientes de asignar)
final unassignedProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Traer todos los profiles con role=chofer
  final profiles = await supabase
      .from('profiles')
      .select('id, full_name')
      .eq('role', 'chofer');

  // Traer los profile_id que ya tienen fila en drivers
  final assigned = await supabase
      .from('drivers')
      .select('profile_id');

  final assignedIds = assigned
      .map((r) => r['profile_id'] as String)
      .toSet();

  // Filtrar los que NO están asignados
  return (profiles as List)
      .where((p) => !assignedIds.contains(p['id']))
      .toList() 
      .cast<Map<String, dynamic>>();
});