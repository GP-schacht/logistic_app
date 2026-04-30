class Driver {
  final String id;
  final String profileId;
  final String fullName;
  final String? phone;
  final String? photoUrl;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String? emergencyContact;
  final String status;
  final String? defaultTruckId;    // ← nuevo
  final String? defaultTruckPlate; // ← nuevo (para mostrar en UI)

  const Driver({
    required this.id,
    required this.profileId,
    required this.fullName,
    this.phone,
    this.photoUrl,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.emergencyContact,
    this.status = 'disponible',
    this.defaultTruckId,
    this.defaultTruckPlate,
  });

  factory Driver.fromMap(Map<String, dynamic> m) => Driver(
    id:               m['id'] as String,
    profileId:        m['profile_id'] as String,
    fullName:         m['profiles']?['full_name'] as String? ?? 'Sin nombre',
    phone:            m['profiles']?['phone'] as String?,
    photoUrl:         m['profiles']?['photo_url'] as String?,
    licenseNumber:    m['license_number'] as String,
    licenseExpiry:    DateTime.parse(m['license_expiry'] as String),
    emergencyContact: m['emergency_contact'] as String?,
    status:           m['status'] as String? ?? 'disponible',
    defaultTruckId:   m['default_truck_id'] as String?,
    defaultTruckPlate: m['trucks']?['plate'] as String?, // join
  );

  bool get hasDefaultTruck => defaultTruckId != null;
  bool get isLicenseExpiringSoon =>
      licenseExpiry.difference(DateTime.now()).inDays <= 30;
  bool get isLicenseExpired =>
      licenseExpiry.isBefore(DateTime.now());

  Map<String, dynamic> driverMap() => {
    'profile_id':        profileId,
    'license_number':    licenseNumber,
    'license_expiry':    licenseExpiry.toIso8601String().split('T').first,
    'emergency_contact': emergencyContact,
    'default_truck_id':  defaultTruckId,
  };
}