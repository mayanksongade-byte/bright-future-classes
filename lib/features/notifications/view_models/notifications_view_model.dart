import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsViewModel extends ChangeNotifier {
  final NotificationRepository _notificationRepository;

  NotificationsViewModel({NotificationRepository? notificationRepository})
      : _notificationRepository =
            notificationRepository ?? NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedTab = 'All'; // All, Unread
  String get selectedTab => _selectedTab;

  String _selectedCategory = 'All'; // All, Teacher, Student, Fees, Attendance, Tests, Homework, Complaints, System
  String get selectedCategory => _selectedCategory;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get filteredNotifications {
    var list = List<NotificationModel>.from(_notifications);

    // Tab filter
    if (_selectedTab == 'Unread') {
      list = list.where((n) => !n.isRead).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      list = list.where((n) {
        final t = n.type.toLowerCase();
        switch (_selectedCategory.toLowerCase()) {
          case 'teacher':
            return t.contains('teacher') || t == 'class_request';
          case 'student':
            return t.contains('student');
          case 'fees':
            return t.contains('fee');
          case 'attendance':
            return t.contains('attendance');
          case 'tests':
            return t.contains('test');
          case 'homework':
            return t.contains('homework');
          case 'complaints':
            return t.contains('complaint');
          case 'system':
            return t.contains('system');
          default:
            return true;
        }
      }).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.message.toLowerCase().contains(q);
      }).toList();
    }

    // Sort newest first
    list.sort((a, b) {
      final dateA = a.createdAt ?? DateTime(2025);
      final dateB = b.createdAt ?? DateTime(2025);
      return dateB.compareTo(dateA);
    });

    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications =
          await _notificationRepository.getNotificationsForRecipient(user.uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load notifications. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final idx = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (idx != -1 && !_notifications[idx].isRead) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
        notifyListeners();
        await _notificationRepository.markAsRead(notificationId);
      }
    } catch (_) {
      // Revert or re-fetch on failure
      fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
      await _notificationRepository.markAllAsRead(user.uid);
    } catch (_) {
      fetchNotifications();
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      notifyListeners();
      await _notificationRepository.deleteNotification(notificationId);
      return true;
    } catch (_) {
      fetchNotifications();
      return false;
    }
  }
}
