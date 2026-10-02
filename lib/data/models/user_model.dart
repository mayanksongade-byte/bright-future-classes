class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.phone = '',
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return UserModel(
        uid: uid,
        name: '',
        email: '',
        role: '',
        isActive: false,
        phone: '',
      );
    }
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      phone: data['phone'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'phone': phone,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? phone,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
    );
  }
}
