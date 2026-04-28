enum TruckStatus { disponible, en_ruta, mantenimiento, inactivo }

class Truck {
  final String id;
  final String plate;
  final String? brand;
  final String? model;
  final int? year;
  final double? capacityTons;
  final TruckStatus status;
  final String? photoUrl;
  final DateTime createdAt;

  const Truck({
    required this.id,
    required this.plate,
    this.brand,
    this.model,
    this.year,
    this.capacityTons,
    required this.status,
    this.photoUrl,
    required this.createdAt,
  });

  factory Truck.fromMap(Map<String, dynamic> m) => Truck(
    id:           m['id'] as String,
    plate:        m['plate'] as String,
    brand:        m['brand'] as String?,
    model:        m['model'] as String?,
    year:         m['year'] as int?,
    capacityTons: (m['capacity_tons'] as num?)?.toDouble(),
    status:       TruckStatus.values.byName(m['status'] as String),
    photoUrl:     m['photo_url'] as String?,
    createdAt:    DateTime.parse(m['created_at'] as String),
  );

  Map<String, dynamic> toMap() => {
    'plate':         plate,
    'brand':         brand,
    'model':         model,
    'year':          year,
    'capacity_tons': capacityTons,
    'status':        status.name,
    'photo_url':     photoUrl,
  };

  // Útil para editar sin mutar el original
  Truck copyWith({
    String? plate, String? brand, String? model,
    int? year, double? capacityTons,
    TruckStatus? status, String? photoUrl,
  }) => Truck(
    id: id, createdAt: createdAt,
    plate:        plate        ?? this.plate,
    brand:        brand        ?? this.brand,
    model:        model        ?? this.model,
    year:         year         ?? this.year,
    capacityTons: capacityTons ?? this.capacityTons,
    status:       status       ?? this.status,
    photoUrl:     photoUrl     ?? this.photoUrl,
  );
}