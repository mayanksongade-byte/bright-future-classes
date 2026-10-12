import 'package:cloud_firestore/cloud_firestore.dart';

class HolidayModel {
  final String holidayId;
  final String title;
  final String type; // Festival, Public Holiday, Tuition Holiday, Vacation, Special Holiday
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final List<String> applicableClassIds; // empty = all classes
  final String note;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HolidayModel({
    required this.holidayId,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.applicableClassIds = const [],
    this.note = '',
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAllClasses => applicableClassIds.isEmpty;

  bool appliesToClass(String? classId) {
    if (isAllClasses) return true;
    if (classId == null || classId.isEmpty) return false;
    return applicableClassIds.contains(classId);
  }

  bool includesDate(String dateStr) {
    if (startDate.isEmpty) return false;
    final end = endDate.isNotEmpty ? endDate : startDate;
    return dateStr.compareTo(startDate) >= 0 && dateStr.compareTo(end) <= 0;
  }

  factory HolidayModel.fromMap(Map<String, dynamic> map, [String? docId]) {
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

    final rawClassIds = map['applicableClassIds'];
    List<String> classIdsList = [];
    if (rawClassIds is List) {
      classIdsList = rawClassIds.map((e) => e.toString()).toList();
    }

    final start = map['startDate'] as String? ?? '';
    final end = map['endDate'] as String? ?? start;

    return HolidayModel(
      holidayId: docId ?? map['holidayId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'Public Holiday',
      startDate: start,
      endDate: end,
      applicableClassIds: classIdsList,
      note: map['note'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'holidayId': holidayId,
      'title': title,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'applicableClassIds': applicableClassIds,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  HolidayModel copyWith({
    String? holidayId,
    String? title,
    String? type,
    String? startDate,
    String? endDate,
    List<String>? applicableClassIds,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HolidayModel(
      holidayId: holidayId ?? this.holidayId,
      title: title ?? this.title,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      applicableClassIds: applicableClassIds ?? this.applicableClassIds,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
