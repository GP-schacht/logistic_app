import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../models/trucks.dart';

// Lista en tiempo real
final trucksProvider = StreamProvider<List<Truck>>((ref) {
  return supabase
      .from('trucks')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Truck.fromMap).toList());
});

// Un camión por id (para detalle/edición)
final truckByIdProvider = FutureProvider.family<Truck?, String>((ref, id) async {
  final data = await supabase
      .from('trucks')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data == null ? null : Truck.fromMap(data);
});

// Operaciones CRUD
class TrucksRepository {
 Future<void> create(Truck truck) async {
  try {
    await supabase.from('trucks').insert(truck.toMap());
  } catch (e) {
    // Ver el error completo en consola de VS Code
    debugPrint('Error creando camión: $e');
    rethrow;
  }
}

  Future<void> update(String id, Truck truck) async {
    await supabase.from('trucks').update(truck.toMap()).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('trucks').delete().eq('id', id);
  }

  Future<void> changeStatus(String id, TruckStatus status) async {
    await supabase
        .from('trucks')
        .update({'status': status.name})
        .eq('id', id);
  }

  
}

final trucksRepoProvider = Provider((_) => TrucksRepository());