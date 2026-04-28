import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/drivers/screens/drivers_screen.dart';
import '../../features/trucks/screens/trucks_list.dart';
import '../../features/trucks/screens/trucks_detail.dart';
import '../../features/trucks/screens/trucks_form.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../config/supabase_config.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: AppGoRouterRefreshStream(
    supabase.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
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
      path: '/invoices',
      builder: (context, state) => const InvoicesScreen(),
    ),
    GoRoute(
      path: '/trucks',
      builder: (context, state) => const TruckListScreen(), // ← context y state únicos
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const TruckFormScreen(), // ← ídem
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => TruckDetailScreen(
            truckId: state.pathParameters['id']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => TruckFormScreen(
                truckId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppGoRouterRefreshStream extends ChangeNotifier {
  AppGoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}