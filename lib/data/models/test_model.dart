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
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedBy;
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
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
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

    DateTime? parsedArchivedAt;
    final rawArchivedAt = map['archivedAt'];
    if (rawArchivedAt is Timestamp) {
      parsedArchivedAt = rawArchivedAt.toDate();
    } else if (rawArchivedAt is String) {
      parsedArchivedAt = DateTime.tryParse(rawArchivedAt);
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
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: parsedArchivedAt,
      archivedBy: map['archivedBy'] as String?,
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
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'archivedBy': archivedBy,
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
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
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
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
