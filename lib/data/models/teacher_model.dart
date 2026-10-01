import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String teacherId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final List<String> classIds;
  final String status;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeacherModel({
    required this.teacherId,
    required this.name,
    required this.email,
    required this.phone,
    this.address = '',
    required this.classIds,
    this.status = 'active',
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = map['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      parsedUpdatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    List<String> parsedClassIds = [];
    final rawClassIds = map['classIds'];
    if (rawClassIds is List) {
      parsedClassIds = rawClassIds.map((e) => e.toString()).toSet().toList();
    }

    return TeacherModel(
      teacherId: docId ?? map['teacherId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      classIds: parsedClassIds,
      status: map['status'] as String? ?? 'active',
      userId: map['userId'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'classIds': classIds.toSet().toList(),
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TeacherModel copyWith({
    String? teacherId,
    String? name,
    String? email,
    String? phone,
    String? address,
    List<String>? classIds,
    String? status,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherModel(
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      classIds: classIds != null ? classIds.toSet().toList() : this.classIds,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
