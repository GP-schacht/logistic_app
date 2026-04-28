import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

// Sesión activa
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Rol del usuario actual — disponible en toda la app
final userRoleProvider = FutureProvider<String?>((ref) async {
  // Se re-ejecuta automáticamente cuando cambia la sesión
  ref.watch(authStateProvider);

  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return null;

  final data = await supabase
      .from('profiles')
      .select('role')
      .eq('id', uid)
      .single();

  return data['role'] as String?;
});

// Helper — booleanos listos para usar en la UI
extension UserRoleX on AsyncValue<String?> {
  bool get isAdmin    => valueOrNull == 'admin';
  bool get isOperador => valueOrNull == 'operador';
  bool get isChofer   => valueOrNull == 'chofer';
  bool get canEdit    => isAdmin || isOperador;  // crear, editar, eliminar
  bool get canDelete  => isAdmin;                // solo admin elimina
}