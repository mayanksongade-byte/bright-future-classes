import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String complaintId;
  final String studentId;
  final String classId;
  final String type; // Academic, Homework, Discipline, Behavior, Fees, Other
  final String title;
  final String description;
  final String priority; // Low, Medium, High
  final String status; // Open, Under Review, Resolved, Closed
  final String resolutionNote; // Action Taken Notes
  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final String incidentDate; // e.g. "2026-10-05"
  final DateTime? resolvedAt;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final String? studentResponse;
  final DateTime? studentResponseAt;
  final List<Map<String, dynamic>> activityHistory;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedBy;
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
    this.createdByName = '',
    this.createdByRole = 'admin',
    this.incidentDate = '',
    this.resolvedAt,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.studentResponse,
    this.studentResponseAt,
    this.activityHistory = const [],
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
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

    DateTime? parsedResolvedAt;
    final rawResolvedAt = map['resolvedAt'];
    if (rawResolvedAt is Timestamp) {
      parsedResolvedAt = rawResolvedAt.toDate();
    } else if (rawResolvedAt is String) {
      parsedResolvedAt = DateTime.tryParse(rawResolvedAt);
    }

    DateTime? parsedAcknowledgedAt;
    final rawAck = map['acknowledgedAt'];
    if (rawAck is Timestamp) {
      parsedAcknowledgedAt = rawAck.toDate();
    } else if (rawAck is String) {
      parsedAcknowledgedAt = DateTime.tryParse(rawAck);
    }

    DateTime? parsedStudentResponseAt;
    final rawRespAt = map['studentResponseAt'];
    if (rawRespAt is Timestamp) {
      parsedStudentResponseAt = rawRespAt.toDate();
    } else if (rawRespAt is String) {
      parsedStudentResponseAt = DateTime.tryParse(rawRespAt);
    }

    DateTime? parsedArchivedAt;
    final rawArchivedAt = map['archivedAt'];
    if (rawArchivedAt is Timestamp) {
      parsedArchivedAt = rawArchivedAt.toDate();
    } else if (rawArchivedAt is String) {
      parsedArchivedAt = DateTime.tryParse(rawArchivedAt);
    }

    List<Map<String, dynamic>> parsedActivityHistory = [];
    final rawHistory = map['activityHistory'];
    if (rawHistory is List) {
      parsedActivityHistory =
          rawHistory.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      createdByName: map['createdByName'] as String? ?? '',
      createdByRole: map['createdByRole'] as String? ?? 'admin',
      incidentDate: map['incidentDate'] as String? ?? '',
      resolvedAt: parsedResolvedAt,
      isAcknowledged: map['isAcknowledged'] as bool? ?? false,
      acknowledgedAt: parsedAcknowledgedAt,
      studentResponse: map['studentResponse'] as String?,
      studentResponseAt: parsedStudentResponseAt,
      activityHistory: parsedActivityHistory,
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: parsedArchivedAt,
      archivedBy: map['archivedBy'] as String?,
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
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'incidentDate': incidentDate,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'studentResponse': studentResponse,
      'studentResponseAt': studentResponseAt != null ? Timestamp.fromDate(studentResponseAt!) : null,
      'activityHistory': activityHistory,
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'archivedBy': archivedBy,
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
    String? createdByName,
    String? createdByRole,
    String? incidentDate,
    DateTime? resolvedAt,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    String? studentResponse,
    DateTime? studentResponseAt,
    List<Map<String, dynamic>>? activityHistory,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
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
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      incidentDate: incidentDate ?? this.incidentDate,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      studentResponse: studentResponse ?? this.studentResponse,
      studentResponseAt: studentResponseAt ?? this.studentResponseAt,
      activityHistory: activityHistory ?? this.activityHistory,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
