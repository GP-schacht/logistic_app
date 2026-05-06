enum TripStatus { programado, en_curso, completado, cancelado }

class Trip {
  final String id;
  final String truckId;
  final String driverId;
  final String containerId;
  final String origin;
  final String destination;
  final TripStatus status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;

  // Datos enriquecidos (joins)
  final String? truckPlate;
  final String? driverName;
  final String? containerNumber;

  const Trip({
    required this.id,
    required this.truckId,
    required this.driverId,
    required this.containerId,
    required this.origin,
    required this.destination,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.notes,
    required this.createdAt,
    this.truckPlate,
    this.driverName,
    this.containerNumber,
  });

  factory Trip.fromMap(Map<String, dynamic> m) => Trip(
    id:              m['id'] as String,
    truckId:         m['truck_id'] as String,
    driverId:        m['driver_id'] as String,
    containerId:     m['container_id'] as String,
    origin:          m['origin'] as String,
    destination:     m['destination'] as String,
    status:          TripStatus.values.byName(m['status'] as String),
    scheduledAt:     m['scheduled_at'] != null
                         ? DateTime.parse(m['scheduled_at']) : null,
    startedAt:       m['started_at'] != null
                         ? DateTime.parse(m['started_at']) : null,
    completedAt:     m['completed_at'] != null
                         ? DateTime.parse(m['completed_at']) : null,
    notes:           m['notes'] as String?,
    createdAt:       DateTime.parse(m['created_at'] as String),
    truckPlate:      m['trucks']?['plate'] as String?,
    driverName:      m['drivers']?['profiles']?['full_name'] as String?,
    containerNumber: m['containers']?['container_number'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'truck_id':      truckId,
    'driver_id':     driverId,
    'container_id':  containerId,
    'origin':        origin,
    'destination':   destination,
    'status':        status.name,
    'scheduled_at':  scheduledAt?.toIso8601String(),
    'notes':         notes,
  };

  // Siguiente estado válido
  TripStatus? get nextStatus => switch (status) {
    TripStatus.programado  => TripStatus.en_curso,
    TripStatus.en_curso    => TripStatus.completado,
    _                      => null,
  };

  String get nextStatusLabel => switch (nextStatus) {
    TripStatus.en_curso   => 'Iniciar viaje',
    TripStatus.completado => 'Completar viaje',
    _                     => '',
  };
}