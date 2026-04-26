import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/drivers/screens/drivers_screen.dart';
import '../../features/trucks/screens/trucks_screen.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../config/supabase_config.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    // El guard revisa la sesión en cada navegación
    final session = supabase.auth.currentSession;
    final isLoginRoute = state.matchedLocation == '/login';

    if (session == null && !isLoginRoute) return '/login';
    if (session != null && isLoginRoute) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/trips',
      builder: (context, state) => const TripsScreen(),
    ),
    GoRoute(
      path: '/drivers',
      builder: (context, state) => const DriversScreen(),
    ),
    GoRoute(
      path: '/trucks',
      builder: (context, state) => const TrucksScreen(),
    ),
    GoRoute(
      path: '/invoices',
      builder: (context, state) => const InvoicesScreen(),
    ),
  ],
);