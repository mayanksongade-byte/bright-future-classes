import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String studentId;
  final String classId;
  final String date; // YYYY-MM-DD format
  final String status; // 'present' or 'absent'
  final String markedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    this.createdAt,
    this.updatedAt,
  });

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

    return AttendanceModel(
      attendanceId: docId ?? map['attendanceId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      status: map['status'] as String? ?? 'present',
      markedBy: map['markedBy'] as String? ?? '',
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
      'markedBy': markedBy,
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
    String? markedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      attendanceId: attendanceId ?? this.attendanceId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
