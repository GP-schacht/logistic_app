import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../models/container.dart';

// Lista en tiempo real
final containersProvider = StreamProvider<List<ContainerModel>>((ref) {
  return supabase
      .from('containers')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(ContainerModel.fromMap).toList());
});

// Un contenedor por id
final containerByIdProvider =
    FutureProvider.family<ContainerModel?, String>((ref, id) async {
  final data = await supabase
      .from('containers')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data == null ? null : ContainerModel.fromMap(data);
});

// CRUD
class ContainersRepository {
  Future<void> create(ContainerModel container) async {
    await supabase.from('containers').insert(container.toMap());
  }

  Future<void> update(String id, ContainerModel container) async {
    await supabase.from('containers').update(container.toMap()).eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('containers').delete().eq('id', id);
  }

  Future<void> changeStatus(String id, ContainerStatus status) async {
    await supabase
        .from('containers')
        .update({'status': status.name})
        .eq('id', id);
  }
}

final containersRepoProvider = Provider((_) => ContainersRepository());