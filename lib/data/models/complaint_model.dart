import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String studentId;
  final String classId;
  final String type; // Academic, Attendance, Behavior, Fees, Other
  final String title;
  final String description;
  final String priority; // Low, Medium, High
  final String status; // Open, In Review, Resolved, Closed
  final String resolutionNote;
  final String createdBy;
  final String createdByRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplaintModel({
    required this.complaintId,
    required this.studentId,
    required this.classId,
    required this.type,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.status = 'Open',
    this.resolutionNote = '',
    required this.createdBy,
    this.createdByRole = 'admin',
    this.createdAt,
    this.updatedAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return ComplaintModel(
      complaintId: docId ?? map['complaintId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      type: map['type'] as String? ?? 'Academic',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Open',
      resolutionNote: map['resolutionNote'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdByRole: map['createdByRole'] as String? ?? 'admin',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'complaintId': complaintId,
      'studentId': studentId,
      'classId': classId,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'resolutionNote': resolutionNote,
      'createdBy': createdBy,
      'createdByRole': createdByRole,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ComplaintModel copyWith({
    String? complaintId,
    String? studentId,
    String? classId,
    String? type,
    String? title,
    String? description,
    String? priority,
    String? status,
    String? resolutionNote,
    String? createdBy,
    String? createdByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ComplaintModel(
      complaintId: complaintId ?? this.complaintId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
