import 'package:cloud_firestore/cloud_firestore.dart';

class MarkAuditModel {
  final String auditId;
  final String testId;
  final String testName;
  final String classId;
  final String studentId;
  final String studentName;
  final double? oldMarks;
  final double? newMarks;
  final bool oldIsAbsent;
  final bool newIsAbsent;
  final String? oldRemarks;
  final String? newRemarks;
  final String editedByUid;
  final String editedByRole;
  final String editedByName;
  final String changeType;
  final DateTime? createdAt;

  MarkAuditModel({
    required this.auditId,
    required this.testId,
    this.testName = '',
    required this.classId,
    required this.studentId,
    this.studentName = '',
    this.oldMarks,
    this.newMarks,
    this.oldIsAbsent = false,
    this.newIsAbsent = false,
    this.oldRemarks,
    this.newRemarks,
    required this.editedByUid,
    required this.editedByRole,
    required this.editedByName,
    this.changeType = 'Marks Updated',
    this.createdAt,
  });

  factory MarkAuditModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    return MarkAuditModel(
      auditId: docId ?? map['auditId'] as String? ?? '',
      testId: map['testId'] as String? ?? '',
      testName: map['testName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      oldMarks: (map['oldMarks'] as num?)?.toDouble(),
      newMarks: (map['newMarks'] as num?)?.toDouble(),
      oldIsAbsent: map['oldIsAbsent'] as bool? ?? false,
      newIsAbsent: map['newIsAbsent'] as bool? ?? false,
      oldRemarks: map['oldRemarks'] as String?,
      newRemarks: map['newRemarks'] as String?,
      editedByUid: map['editedByUid'] as String? ?? '',
      editedByRole: map['editedByRole'] as String? ?? '',
      editedByName: map['editedByName'] as String? ?? '',
      changeType: map['changeType'] as String? ?? 'Marks Updated',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auditId': auditId,
      'testId': testId,
      'testName': testName,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'oldMarks': oldMarks,
      'newMarks': newMarks,
      'oldIsAbsent': oldIsAbsent,
      'newIsAbsent': newIsAbsent,
      'oldRemarks': oldRemarks,
      'newRemarks': newRemarks,
      'editedByUid': editedByUid,
      'editedByRole': editedByRole,
      'editedByName': editedByName,
      'changeType': changeType,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
