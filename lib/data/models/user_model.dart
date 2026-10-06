class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic>? data) {
    if (data == null) {
      return UserModel(
        uid: uid,
        name: '',
        email: '',
        role: '',
        isActive: false,
      );
    }
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}
