import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String teacherId;
  final String name;
  final String email;
  final String phone;
  final List<String> classIds;
  final String status;
  final String? userId;
  final DateTime? createdAt;

  TeacherModel({
    required this.teacherId,
    required this.name,
    required this.email,
    required this.phone,
    required this.classIds,
    this.status = 'active',
    this.userId,
    this.createdAt,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    List<String> parsedClassIds = [];
    final rawClassIds = map['classIds'];
    if (rawClassIds is List) {
      parsedClassIds = rawClassIds.map((e) => e.toString()).toList();
    }

    return TeacherModel(
      teacherId: docId ?? map['teacherId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      classIds: parsedClassIds,
      status: map['status'] as String? ?? 'active',
      userId: map['userId'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'name': name,
      'email': email,
      'phone': phone,
      'classIds': classIds,
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  TeacherModel copyWith({
    String? teacherId,
    String? name,
    String? email,
    String? phone,
    List<String>? classIds,
    String? status,
    String? userId,
    DateTime? createdAt,
  }) {
    return TeacherModel(
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      classIds: classIds ?? this.classIds,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
