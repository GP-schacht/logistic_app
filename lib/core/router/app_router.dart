import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:logistic_app/features/trips/screens/trip_detail.dart';
import 'package:logistic_app/features/trips/screens/trip_form.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/drivers/screens/drivers_screen.dart';
import '../../features/drivers/screens/drivers_detail.dart';
import '../../features/drivers/screens/drivers_form.dart';
import '../../features/trucks/screens/trucks_list.dart';
import '../../features/trucks/screens/trucks_detail.dart';
import '../../features/trucks/screens/trucks_form.dart';
import '../../features/invoices/screens/invoices_screen.dart';
import '../../features/drivers/screens/driver_assign_screen.dart';
import '../config/supabase_config.dart';
import '../../features/containers/screens/containers_screen.dart';
import '../../features/containers/screens/container_detail.dart';
import '../../features/containers/screens/container_form.dart';
final appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: AppGoRouterRefreshStream(
    supabase.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final session      = supabase.auth.currentSession;
    final isLoginRoute = state.matchedLocation == '/login';

    if (session == null && !isLoginRoute) return '/login';
    if (session != null && isLoginRoute) return '/dashboard';
    return null;
  },
  routes: [

    // ── Auth ──────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Dashboard ─────────────────────────────────────────
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),

    // ── Camiones ──────────────────────────────────────────
    GoRoute(
      path: '/trucks',
      builder: (context, state) => const TruckListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const TruckFormScreen(),
        ),
        GoRoute(
          path: ':truckId',
          builder: (context, state) => TruckDetailScreen(
            truckId: state.pathParameters['truckId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => TruckFormScreen(
                truckId: state.pathParameters['truckId'],
              ),
            ),
          ],
        ),
      ],
    ),

    // ── Conductores ───────────────────────────────────────
  GoRoute(
  path: '/drivers',
  builder: (context, state) => const DriversScreen(),
  routes: [
    // Nueva ruta de asignación
    GoRoute(
      path: 'assign',
      builder: (context, state) {
        final extra = state.extra;
        final profile = extra is Map<String, dynamic>
            ? extra
            : (extra is Map ? Map<String, dynamic>.from(extra) : null);

        if (profile == null) return const DriversScreen();

        return DriverAssignScreen(profile: profile);
      },
    ),
    GoRoute(
      path: ':driverId',
      builder: (context, state) => DriverDetailScreen(
        driverId: state.pathParameters['driverId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => DriverFormScreen(
            driverId: state.pathParameters['driverId'],
          ),
        ),
      ],
    ),
  ],
),

    // ── Viajes ────────────────────────────────────────────
    GoRoute(
      path: '/trips',
      builder: (context, state) => const TripsScreen(),
      routes: [
        GoRoute(
          path:'new',
          builder:(context,state) => const TripFormScreen(),

        ),
        GoRoute(
          path: ':tripId',
          builder:(context, state) => TripDetailScreen(
            tripId: state.pathParameters['tripId']!,
            ),
          ),
      ]
    ),

    // ── Facturas ──────────────────────────────────────────
    GoRoute(
      path: '/invoices',
      builder: (context, state) => const InvoicesScreen(),
    ),

    // ── Containers ──────────────────────────────────────────
GoRoute(
  path: '/containers',
  builder: (context, state) => const ContainersScreen(),
  routes: [
    GoRoute(
      path: 'new',
      builder: (context, state) => const ContainerFormScreen(),
    ),
    GoRoute(
      path: ':containerId',
      builder: (context, state) => ContainerDetailScreen(
        containerId: state.pathParameters['containerId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => ContainerFormScreen(
            containerId: state.pathParameters['containerId'],
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