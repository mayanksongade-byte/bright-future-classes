import 'package:cloud_firestore/cloud_firestore.dart';

class TestModel {
  final String testId;
  final String testName;
  final String classId;
  final String subject;
  final String testDate; // e.g. "2026-10-15"
  final double totalMarks;
  final double? passingMarks;
  final String description;
  final String createdBy;
  final String? createdByName;
  final String? createdByRole;
  final bool isCancelled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TestModel({
    required this.testId,
    required this.testName,
    required this.classId,
    required this.subject,
    required this.testDate,
    required this.totalMarks,
    this.passingMarks,
    this.description = '',
    required this.createdBy,
    this.createdByName,
    this.createdByRole,
    this.isCancelled = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TestModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return TestModel(
      testId: docId ?? map['testId'] as String? ?? '',
      testName: map['testName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      testDate: map['testDate'] as String? ?? '',
      totalMarks: (map['totalMarks'] as num?)?.toDouble() ?? 0.0,
      passingMarks: (map['passingMarks'] as num?)?.toDouble(),
      description: map['description'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String?,
      createdByRole: map['createdByRole'] as String?,
      isCancelled: map['isCancelled'] as bool? ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'testName': testName,
      'classId': classId,
      'subject': subject,
      'testDate': testDate,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'description': description,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'isCancelled': isCancelled,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TestModel copyWith({
    String? testId,
    String? testName,
    String? classId,
    String? subject,
    String? testDate,
    double? totalMarks,
    double? passingMarks,
    String? description,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    bool? isCancelled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TestModel(
      testId: testId ?? this.testId,
      testName: testName ?? this.testName,
      classId: classId ?? this.classId,
      subject: subject ?? this.subject,
      testDate: testDate ?? this.testDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
