import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  String generateNotificationId() {
    return _notificationService.generateNotificationId();
  }

  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _notificationService.createNotification(notification);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while creating notification.');
    }
  }

  Future<List<NotificationModel>> getNotificationsForRecipient(
      String recipientId) async {
    try {
      return await _notificationService.getNotificationsForRecipient(recipientId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to load notifications.');
    }
  }

  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      return await _notificationService.getNotificationById(notificationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update notification.');
    }
  }

  Future<void> markAllAsRead(String recipientId) async {
    try {
      await _notificationService.markAllAsRead(recipientId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update notifications.');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete notification.');
    }
  }
}
