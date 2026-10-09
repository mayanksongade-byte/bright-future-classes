import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceAuditModel {
  final String auditId;
  final String attendanceSessionId;
  final String classId;
  final String date;
  final String studentId;
  final String oldStatus;
  final String newStatus;
  final String changedByUid;
  final String changedByRole;
  final String changedByName;
  final String reason;
  final String teacherUid;
  final DateTime? createdAt;

  AttendanceAuditModel({
    required this.auditId,
    required this.attendanceSessionId,
    required this.classId,
    required this.date,
    required this.studentId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedByUid,
    required this.changedByRole,
    required this.changedByName,
    required this.reason,
    required this.teacherUid,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'auditId': auditId,
      'attendanceSessionId': attendanceSessionId,
      'classId': classId,
      'date': date,
      'studentId': studentId,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'changedByUid': changedByUid,
      'changedByRole': changedByRole,
      'changedByName': changedByName,
      'reason': reason,
      'teacherUid': teacherUid,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AttendanceAuditModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    return AttendanceAuditModel(
      auditId: docId ?? map['auditId'] as String? ?? '',
      attendanceSessionId: map['attendanceSessionId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      oldStatus: map['oldStatus'] as String? ?? '',
      newStatus: map['newStatus'] as String? ?? '',
      changedByUid: map['changedByUid'] as String? ?? '',
      changedByRole: map['changedByRole'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      teacherUid: map['teacherUid'] as String? ?? '',
      createdAt: parsedCreatedAt,
    );
  }
}
