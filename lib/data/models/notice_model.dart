import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeModel {
  final String noticeId;
  final String title;
  final String description;
  final String type; // general, academic, exam, holiday, fee, important, event
  final String priority; // normal, high
  final String targetAudience; // all_students, selected_classes
  final List<String> classIds;
  final DateTime publishDate;
  final DateTime expiryDate;
  final String statusOverride; // 'draft' or ''
  final bool isPinned;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NoticeModel({
    required this.noticeId,
    required this.title,
    required this.description,
    required this.type,
    this.priority = 'normal',
    required this.targetAudience,
    required this.classIds,
    required this.publishDate,
    required this.expiryDate,
    this.statusOverride = '',
    this.isPinned = false,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  String get computedStatus {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pub = DateTime(publishDate.year, publishDate.month, publishDate.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    if (statusOverride.toLowerCase() == 'draft') {
      return 'draft';
    }
    if (today.isAfter(exp)) {
      return 'expired';
    }
    if (pub.isAfter(today)) {
      return 'scheduled';
    }
    return 'published';
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    DateTime parsedPublishDate = DateTime.now();
    final rawPub = map['publishDate'];
    if (rawPub is Timestamp) {
      parsedPublishDate = rawPub.toDate();
    } else if (rawPub is String) {
      parsedPublishDate = DateTime.tryParse(rawPub) ?? DateTime.now();
    }

    DateTime parsedExpiryDate = DateTime.now().add(const Duration(days: 7));
    final rawExp = map['expiryDate'];
    if (rawExp is Timestamp) {
      parsedExpiryDate = rawExp.toDate();
    } else if (rawExp is String) {
      parsedExpiryDate = DateTime.tryParse(rawExp) ??
          DateTime.now().add(const Duration(days: 7));
    }

    // Backward compatibility for classIds vs classId
    List<String> parsedClassIds = [];
    final rawClassIds = map['classIds'];
    if (rawClassIds is List) {
      parsedClassIds = rawClassIds.map((e) => e.toString()).toSet().toList();
    } else {
      final oldClassId = map['classId'] as String?;
      if (oldClassId != null && oldClassId.isNotEmpty) {
        parsedClassIds = [oldClassId];
      }
    }

    final rawStatus = map['status'] as String? ?? '';
    final rawOverride = map['statusOverride'] as String? ?? '';
    final resolvedOverride = rawOverride.isNotEmpty
        ? rawOverride
        : (rawStatus == 'draft' ? 'draft' : '');

    final rawAudience = map['targetAudience'] as String? ?? 'all_students';
    final normalizedAudience =
        rawAudience == 'specific_class' ? 'selected_classes' : rawAudience;

    return NoticeModel(
      noticeId: docId ?? map['noticeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      priority: map['priority'] as String? ?? 'normal',
      targetAudience: normalizedAudience,
      classIds: parsedClassIds,
      publishDate: parsedPublishDate,
      expiryDate: parsedExpiryDate,
      statusOverride: resolvedOverride,
      isPinned: map['isPinned'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noticeId': noticeId,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'targetAudience': targetAudience,
      'classIds': classIds.toSet().toList(),
      'publishDate': Timestamp.fromDate(publishDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': computedStatus,
      'statusOverride': statusOverride,
      'isPinned': isPinned,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  NoticeModel copyWith({
    String? noticeId,
    String? title,
    String? description,
    String? type,
    String? priority,
    String? targetAudience,
    List<String>? classIds,
    DateTime? publishDate,
    DateTime? expiryDate,
    String? statusOverride,
    bool? isPinned,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoticeModel(
      noticeId: noticeId ?? this.noticeId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      targetAudience: targetAudience ?? this.targetAudience,
      classIds: classIds != null ? classIds.toSet().toList() : this.classIds,
      publishDate: publishDate ?? this.publishDate,
      expiryDate: expiryDate ?? this.expiryDate,
      statusOverride: statusOverride ?? this.statusOverride,
      isPinned: isPinned ?? this.isPinned,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
