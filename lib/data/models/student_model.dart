import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String name;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String address;
  final String parentName;
  final String parentPhone;
  final String? classId;
  final String status;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.studentId,
    required this.name,
    this.dateOfBirth = '',
    this.gender = 'Male',
    required this.phone,
    this.address = '',
    required this.parentName,
    required this.parentPhone,
    this.classId,
    this.status = 'active',
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return StudentModel(
      studentId: docId ?? map['studentId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      gender: map['gender'] as String? ?? 'Male',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      parentName: map['parentName'] as String? ?? '',
      parentPhone: map['parentPhone'] as String? ?? '',
      classId: map['classId'] as String?,
      status: map['status'] as String? ?? 'active',
      userId: map['userId'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'address': address,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'classId': classId,
      'status': status,
      'userId': userId,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudentModel copyWith({
    String? studentId,
    String? name,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? address,
    String? parentName,
    String? parentPhone,
    String? classId,
    String? status,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      classId: classId ?? this.classId,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
