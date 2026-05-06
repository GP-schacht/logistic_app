enum ContainerStatus { en_patio, en_puerto, en_transito, entregado }

enum ContainerType { dry, reefer, open_top, flat_rack, tank }

class ContainerModel {
  final String id;
  final String containerNumber;
  final ContainerType? type;
  final double? weightKg;
  final ContainerStatus status;
  final String? currentLocation;
  final String? blNumber;
  final String? notes;
  final DateTime createdAt;

  const ContainerModel({
    required this.id,
    required this.containerNumber,
    this.type,
    this.weightKg,
    required this.status,
    this.currentLocation,
    this.blNumber,
    this.notes,
    required this.createdAt,
  });

  factory ContainerModel.fromMap(Map<String, dynamic> m) => ContainerModel(
    id:               m['id'] as String,
    containerNumber:  m['container_number'] as String,
    type:             m['type'] != null
                          ? ContainerType.values.byName(m['type'] as String)
                          : null,
    weightKg:         (m['weight_kg'] as num?)?.toDouble(),
    status:           ContainerStatus.values.byName(m['status'] as String),
    currentLocation:  m['current_location'] as String?,
    blNumber:         m['bl_number'] as String?,
    notes:            m['notes'] as String?,
    createdAt:        DateTime.parse(m['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'container_number': containerNumber,
    'type':             type?.name,
    'weight_kg':        weightKg,
    'status':           status.name,
    'current_location': currentLocation,
    'bl_number':        blNumber,
    'notes':            notes,
  };

  ContainerModel copyWith({
    String? containerNumber,
    ContainerType? type,
    double? weightKg,
    ContainerStatus? status,
    String? currentLocation,
    String? blNumber,
    String? notes,
  }) => ContainerModel(
    id: id, createdAt: createdAt,
    containerNumber:  containerNumber  ?? this.containerNumber,
    type:             type             ?? this.type,
    weightKg:         weightKg         ?? this.weightKg,
    status:           status           ?? this.status,
    currentLocation:  currentLocation  ?? this.currentLocation,
    blNumber:         blNumber         ?? this.blNumber,
    notes:            notes            ?? this.notes,
  );
}