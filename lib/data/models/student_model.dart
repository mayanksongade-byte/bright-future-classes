import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String name;
  final String phone;
  final String parentName;
  final String parentPhone;
  final String? classId;
  final String status;
  final String? userId;
  final DateTime? createdAt;

  StudentModel({
    required this.studentId,
    required this.name,
    required this.phone,
    required this.parentName,
    required this.parentPhone,
    this.classId,
    this.status = 'active',
    this.userId,
    this.createdAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    return StudentModel(
      studentId: docId ?? map['studentId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      parentName: map['parentName'] as String? ?? '',
      parentPhone: map['parentPhone'] as String? ?? '',
      classId: map['classId'] as String?,
      status: map['status'] as String? ?? 'active',
      userId: map['userId'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'phone': phone,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'classId': classId,
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? phone,
    String? parentName,
    String? parentPhone,
    String? classId,
    String? status,
    String? userId,
    DateTime? createdAt,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      classId: classId ?? this.classId,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
