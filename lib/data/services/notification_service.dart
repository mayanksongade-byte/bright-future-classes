import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirestoreService _firestoreService;

  NotificationService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateNotificationId() {
    return _firestoreService.generateNotificationId();
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _firestoreService.saveNotificationDocument(
      notification.notificationId,
      notification.toMap(),
    );
  }

  Future<List<NotificationModel>> getNotificationsForRecipient(
      String recipientId) async {
    final docs =
        await _firestoreService.getNotificationsDocumentsForRecipient(recipientId);
    return docs
        .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<NotificationModel?> getNotificationById(String notificationId) async {
    final data = await _firestoreService.getNotificationDocument(notificationId);
    if (data != null) {
      return NotificationModel.fromMap(data, notificationId);
    }
    return null;
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestoreService.saveNotificationDocument(
      notificationId,
      {'isRead': true, 'updatedAt': FieldValue.serverTimestamp()},
    );
  }

  Future<void> markAllAsRead(String recipientId) async {
    final docs =
        await _firestoreService.getNotificationsDocumentsForRecipient(recipientId);
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in docs) {
      if (doc.data()['isRead'] != true) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestoreService.deleteNotificationDocument(notificationId);
  }
}
