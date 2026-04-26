class UserProfile {
  final String id;
  final String fullName;
  final String role; // 'admin' | 'operador' | 'chofer'
  final String? phone;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      phone: map['phone'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isOperador => role == 'operador';
  bool get isChofer => role == 'chofer';
  bool get canEdit => role == 'admin' || role == 'operador';
}