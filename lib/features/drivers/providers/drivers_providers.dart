import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/driver.dart';

// Lista en tiempo real con join a profiles
final driversProvider = StreamProvider<List<Driver>>((ref) {
  return supabase
      .from('drivers')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .asyncMap((rows) async {
        // Stream no soporta joins, hacemos el enrich manualmente
        final enriched = await Future.wait(rows.map((row) async {
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', row['profile_id'])
              .maybeSingle();

          // Ver si el conductor tiene un viaje activo hoy
          final activeTrip = await supabase
              .from('trips')
              .select('status')
              .eq('driver_id', row['id'])
              .inFilter('status', ['en_curso', 'programado'])
              .maybeSingle();

          return {
            ...row,
            'profiles': profile,
            'status': activeTrip != null
                ? activeTrip['status'] as String
                : 'disponible',
          };
        }));

        return enriched.map(Driver.fromMap).toList();
      });
});

// Un conductor por id
final driverByIdProvider = FutureProvider.family<Driver?, String>((ref, id) async {
  final row = await supabase
      .from('drivers')
      .select('*, profiles(*)')
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

class DriversRepository {
  Future<void> create({
    required String fullName,
    required String? phone,
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String? emergencyContact,
  }) async {
    // 1. Crear perfil
    final profile = await supabase
        .from('profiles')
        .insert({
          'full_name': fullName,
          'phone':     phone,
          'role':      'chofer',
        })
        .select()
        .single();

    // 2. Crear conductor vinculado al perfil
    await supabase.from('drivers').insert({
      'profile_id':        profile['id'],
      'license_number':    licenseNumber,
      'license_expiry':    licenseExpiry.toIso8601String().split('T').first,
      'emergency_contact': emergencyContact,
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
      }).eq('id', driverId),
    ]);
  }

  Future<void> delete(String driverId) async {
    await supabase.from('drivers').delete().eq('id', driverId);
  }
}

final driversRepoProvider = Provider((_) => DriversRepository());