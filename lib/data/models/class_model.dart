import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classId;
  final String className;
  final String standard;
  final String medium;
  final String academicYear;
  final String status;
  final DateTime? createdAt;

  ClassModel({
    required this.classId,
    required this.className,
    required this.standard,
    required this.medium,
    required this.academicYear,
    this.status = 'active',
    this.createdAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    return ClassModel(
      classId: docId ?? map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      standard: map['standard'] as String? ?? '',
      medium: map['medium'] as String? ?? '',
      academicYear: map['academicYear'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'standard': standard,
      'medium': medium,
      'academicYear': academicYear,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  ClassModel copyWith({
    String? classId,
    String? className,
    String? standard,
    String? medium,
    String? academicYear,
    String? status,
    DateTime? createdAt,
  }) {
    return ClassModel(
      classId: classId ?? this.classId,
      className: className ?? this.className,
      standard: standard ?? this.standard,
      medium: medium ?? this.medium,
      academicYear: academicYear ?? this.academicYear,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
