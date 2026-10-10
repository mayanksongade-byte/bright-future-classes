import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String classId;
  final String date; // YYYY-MM-DD format
  final String status; // 'present' or 'absent'
  final String originalStatus;
  final String markedBy; // UID
  final String markedByRole; // 'admin' or 'teacher'
  final String markedByName; // Name of submitter
  final bool teacherEditUsed;
  final bool isAdminChanged;
  final String? adminChangeReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    String? originalStatus,
    required this.markedBy,
    this.markedByRole = 'teacher',
    this.markedByName = '',
    this.teacherEditUsed = false,
    this.isAdminChanged = false,
    this.adminChangeReason,
    this.createdAt,
    this.updatedAt,
  }) : originalStatus = originalStatus ?? status;

  static String generateId(String classId, String studentId, String date) {
    return '${classId}_${studentId}_$date';
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    final currentStatus = map['status'] as String? ?? 'present';
    final origStatus = map['originalStatus'] as String? ?? currentStatus;

    return AttendanceModel(
      attendanceId: docId ?? map['attendanceId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      status: currentStatus,
      originalStatus: origStatus,
      markedBy: map['markedBy'] as String? ?? '',
      markedByRole: map['markedByRole'] as String? ?? 'teacher',
      markedByName: map['markedByName'] as String? ?? '',
      teacherEditUsed: map['teacherEditUsed'] as bool? ?? false,
      isAdminChanged: map['isAdminChanged'] as bool? ?? false,
      adminChangeReason: map['adminChangeReason'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'studentId': studentId,
      'classId': classId,
      'date': date,
      'status': status,
      'originalStatus': originalStatus,
      'markedBy': markedBy,
      'markedByRole': markedByRole,
      'markedByName': markedByName,
      'teacherEditUsed': teacherEditUsed,
      'isAdminChanged': isAdminChanged,
      'adminChangeReason': adminChangeReason,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendanceModel copyWith({
    String? attendanceId,
    String? studentId,
    String? classId,
    String? date,
    String? status,
    String? originalStatus,
    String? markedBy,
    String? markedByRole,
    String? markedByName,
    bool? teacherEditUsed,
    bool? isAdminChanged,
    String? adminChangeReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
      originalStatus: originalStatus ?? this.originalStatus,
      markedBy: markedBy ?? this.markedBy,
      markedByRole: markedByRole ?? this.markedByRole,
      markedByName: markedByName ?? this.markedByName,
      teacherEditUsed: teacherEditUsed ?? this.teacherEditUsed,
      isAdminChanged: isAdminChanged ?? this.isAdminChanged,
      adminChangeReason: adminChangeReason ?? this.adminChangeReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
