class UserModel {
  final String id;
  final String name;
  final String email;
  final bool active;
  final String? phoneNumber;
  final String? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.role,
    this.active = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      role: map['role'],
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'active': active,
    };
  }
}