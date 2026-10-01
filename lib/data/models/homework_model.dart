import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String homeworkId;
  final String classId;
  final String title;
  final String description;
  final String assignedDate;
  final String dueDate;
  final String status; // 'active' or 'completed'
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeworkModel({
    required this.homeworkId,
    required this.classId,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.dueDate,
    this.status = 'active',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    return HomeworkModel(
      homeworkId: docId ?? map['homeworkId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      assignedDate: map['assignedDate'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeworkId': homeworkId,
      'classId': classId,
      'title': title,
      'description': description,
      'assignedDate': assignedDate,
      'dueDate': dueDate,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  HomeworkModel copyWith({
    String? homeworkId,
    String? classId,
    String? title,
    String? description,
    String? assignedDate,
    String? dueDate,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeworkModel(
      homeworkId: homeworkId ?? this.homeworkId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
