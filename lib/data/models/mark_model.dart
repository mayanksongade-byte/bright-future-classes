import 'package:cloud_firestore/cloud_firestore.dart';

class MarkModel {
  final String markId;
  final String testId;
  final String studentId;
  final String classId;
  final double? marks; // null if absent or not entered
  final bool isAbsent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MarkModel({
    required this.markId,
    required this.testId,
    required this.studentId,
    required this.classId,
    this.marks,
    this.isAbsent = false,
    this.createdAt,
    this.updatedAt,
  });

  static String generateId(String testId, String studentId) {
    return '${testId}_$studentId';
  }

  factory MarkModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return MarkModel(
      markId: docId ?? map['markId'] as String? ?? '',
      testId: map['testId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      marks: (map['marks'] as num?)?.toDouble(),
      isAbsent: map['isAbsent'] as bool? ?? false,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'markId': markId,
      'testId': testId,
      'studentId': studentId,
      'classId': classId,
      'marks': marks,
      'isAbsent': isAbsent,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MarkModel copyWith({
    String? markId,
    String? testId,
    String? studentId,
    String? classId,
    double? marks,
    bool? isAbsent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarkModel(
      markId: markId ?? this.markId,
      testId: testId ?? this.testId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      marks: marks ?? this.marks,
      isAbsent: isAbsent ?? this.isAbsent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
