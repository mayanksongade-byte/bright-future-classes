import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationId;
  final String recipientId;
  final String recipientRole; // admin, teacher, student
  final String title;
  final String message;
  final String type; // teacher_leave_request, fee_payment_added, etc.
  final String priority; // Low, Normal, High
  final bool isRead;
  final DateTime? createdAt;
  final String? referenceId;
  final String? referenceType;
  final String? route;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    this.recipientRole = 'admin',
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'Normal',
    this.isRead = false,
    this.createdAt,
    this.referenceId,
    this.referenceType,
    this.route,
    this.metadata = const {},
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    Map<String, dynamic> parsedMetadata = {};
    final rawMeta = map['metadata'];
    if (rawMeta is Map) {
      parsedMetadata = Map<String, dynamic>.from(rawMeta);
    }

    return NotificationModel(
      notificationId: docId ?? map['notificationId'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      recipientRole: map['recipientRole'] as String? ?? 'admin',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'system',
      priority: map['priority'] as String? ?? 'Normal',
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parsedCreatedAt,
      referenceId: map['referenceId'] as String?,
      referenceType: map['referenceType'] as String?,
      route: map['route'] as String?,
      metadata: parsedMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'referenceId': referenceId,
      'referenceType': referenceType,
      'route': route,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? recipientId,
    String? recipientRole,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
    String? referenceId,
    String? referenceType,
    String? route,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      route: route ?? this.route,
      metadata: metadata ?? this.metadata,
    );
  }
}
