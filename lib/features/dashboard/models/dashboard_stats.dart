class DashboardStats {
  // Camiones
  final int trucksAvailable;
  final int trucksOnRoute;
  final int trucksMaintenance;

  // Contenedores
  final int containersInYard;
  final int containersInTransit;
  final int containersDelivered;

  // Viajes del día
  final int tripsScheduled;
  final int tripsInProgress;
  final int tripsCompleted;

  // Rendimiento choferes
  final List<DriverPerformance> topDrivers;

  // Actividad semanal (viajes completados por día)
  final List<WeeklyActivity> weeklyActivity;

  const DashboardStats({
    required this.trucksAvailable,
    required this.trucksOnRoute,
    required this.trucksMaintenance,
    required this.containersInYard,
    required this.containersInTransit,
    required this.containersDelivered,
    required this.tripsScheduled,
    required this.tripsInProgress,
    required this.tripsCompleted,
    required this.topDrivers,
    required this.weeklyActivity,
  });

  int get totalTrucks => trucksAvailable + trucksOnRoute + trucksMaintenance;
  int get totalTripsToday => tripsScheduled + tripsInProgress + tripsCompleted;
}

class DriverPerformance {
  final String driverId;
  final String name;
  final int tripsCompleted;
  final double completionRate; // 0.0 - 1.0

  const DriverPerformance({
    required this.driverId,
    required this.name,
    required this.tripsCompleted,
    required this.completionRate,
  });
}

class WeeklyActivity {
  final String day;     // 'Lun', 'Mar', etc.
  final int completed;
  final int scheduled;

  const WeeklyActivity({
    required this.day,
    required this.completed,
    required this.scheduled,
  });
}