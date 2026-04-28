import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../../core/config/supabase_config.dart';

// Stream del usuario autenticado — se actualiza solo al login/logout
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

// Perfil completo del usuario (incluye rol)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = await ref.watch(authStateProvider.future);
  final user = authState.session?.user;
  if (user == null) return null;

  final data = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return UserProfile.fromMap(data);
});