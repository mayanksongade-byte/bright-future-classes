import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/notice_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../data/services/firestore_service.dart';

class NoticesViewModel extends ChangeNotifier {
  final NoticeRepository _noticeRepository;
  final ClassRepository _classRepository;
  final TeacherRepository _teacherRepository;
  final NotificationRepository _notificationRepository;
  final FirestoreService _firestoreService;

  NoticesViewModel({
    NoticeRepository? noticeRepository,
    ClassRepository? classRepository,
    TeacherRepository? teacherRepository,
    NotificationRepository? notificationRepository,
    FirestoreService? firestoreService,
  })  : _noticeRepository = noticeRepository ?? NoticeRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository(),
        _firestoreService = firestoreService ?? FirestoreService();

  List<NoticeModel> _notices = [];
  List<ClassModel> _classes = [];
  List<TeacherModel> _teachers = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedTypeFilter = 'All';
  String get selectedTypeFilter => _selectedTypeFilter;

  String _selectedStatusFilter = 'All';
  String get selectedStatusFilter => _selectedStatusFilter;

  String _selectedPriorityFilter = 'All';
  String get selectedPriorityFilter => _selectedPriorityFilter;

  String? _selectedClassFilter;
  String? get selectedClassFilter => _selectedClassFilter;

  List<ClassModel> get classes => List.unmodifiable(_classes);

  int get totalNotices => _notices.length;
  int get publishedCount =>
      _notices.where((n) => n.computedStatus == 'published').length;
  int get scheduledCount =>
      _notices.where((n) => n.computedStatus == 'scheduled').length;
  int get draftCount =>
      _notices.where((n) => n.computedStatus == 'draft').length;
  int get expiredCount =>
      _notices.where((n) => n.computedStatus == 'expired').length;

  List<NoticeModel> get filteredNotices {
    var list = List<NoticeModel>.from(_notices);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.description.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedTypeFilter != 'All') {
      list = list
          .where((n) => n.type.toLowerCase() == _selectedTypeFilter.toLowerCase())
          .toList();
    }

    if (_selectedStatusFilter != 'All') {
      list = list
          .where((n) => n.computedStatus.toLowerCase() == _selectedStatusFilter.toLowerCase())
          .toList();
    }

    if (_selectedPriorityFilter != 'All') {
      list = list
          .where((n) => n.priority.toLowerCase() == _selectedPriorityFilter.toLowerCase())
          .toList();
    }

    if (_selectedClassFilter != null && _selectedClassFilter!.isNotEmpty) {
      list = list.where((n) {
        if (n.targetAudience == 'all_teachers') return true;
        return n.classIds.contains(_selectedClassFilter);
      }).toList();
    }

    // Sort: Pinned notices first, then newest publishDate/createdAt
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return b.isPinned ? 1 : -1;
      }
      final dateA = a.createdAt ?? a.publishDate;
      final dateB = b.createdAt ?? b.publishDate;
      return dateB.compareTo(dateA);
    });

    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _selectedPriorityFilter = priority;
    notifyListeners();
  }

  void setClassFilter(String? classId) {
    _selectedClassFilter = classId;
    notifyListeners();
  }

  Future<TeacherModel?> _resolveTeacher(String uid) async {
    try {
      final userDoc = await _firestoreService.getUserDocument(uid);
      final customTeacherId = userDoc?['teacherId'] as String? ?? '';
      final customUserId = userDoc?['userId'] as String? ?? '';

      final candidateIds = <String>{};
      if (customTeacherId.isNotEmpty) candidateIds.add(customTeacherId);
      candidateIds.add(uid);
      if (customUserId.isNotEmpty) candidateIds.add(customUserId);

      for (final candidateId in candidateIds) {
        final teacherData = await _firestoreService.getTeacherDocument(candidateId);
        if (teacherData != null) {
          return TeacherModel.fromMap(teacherData, candidateId);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchNoticesData({String? role, String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = userId ?? currentUser?.uid ?? '';

      String userRole = role ?? 'admin';
      if (currentUser != null && role == null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        userRole = (userDoc?['role'] as String? ?? 'admin').toLowerCase();
      }

      if (userRole == 'teacher') {
        // Teachers cannot list all teachers (permission-denied).
        // Fetch only notices and classes; resolve own teacher profile separately.
        final results = await Future.wait([
          _noticeRepository.getNotices(),
          _classRepository.getClasses(),
        ]);

        final allNotices = results[0] as List<NoticeModel>;
        final rawClasses = results[1] as List<ClassModel>;

        final uniqueMap = <String, ClassModel>{};
        for (var c in rawClasses) {
          uniqueMap[c.classId] = c;
        }
        var resolvedClasses = uniqueMap.values.toList();
        resolvedClasses.sort((a, b) => a.className.compareTo(b.className));

        final teacher = await _resolveTeacher(uid);
        final assignedClassIds = teacher?.classIds ?? [];

        // Build a set of canonical class document IDs assigned to this teacher.
        final Set<String> teacherClassDocIds = {};
        for (var cId in assignedClassIds) {
          if (cId.trim().isNotEmpty) teacherClassDocIds.add(cId.trim());
        }

        // Also map class names for class IDs stored as names (backward compat).
        final Set<String> teacherClassIdentifiers = {};
        for (var cId in teacherClassDocIds) {
          teacherClassIdentifiers.add(cId.toLowerCase());
        }
        for (var cls in resolvedClasses) {
          if (teacherClassDocIds.contains(cls.classId) || teacherClassDocIds.contains(cls.className)) {
            if (cls.classId.trim().isNotEmpty) teacherClassIdentifiers.add(cls.classId.trim().toLowerCase());
            if (cls.className.trim().isNotEmpty) teacherClassIdentifiers.add(cls.className.trim().toLowerCase());
          }
        }

        _classes = resolvedClasses
            .where((c) => teacherClassIdentifiers.contains(c.classId.trim().toLowerCase()) || teacherClassIdentifiers.contains(c.className.trim().toLowerCase()))
            .toList();

        _notices = allNotices.where((n) {
          // Show if teacher created the notice
          final isCreator = n.createdBy == uid ||
              (teacher != null && (n.createdBy == teacher.teacherId || n.createdBy == teacher.userId));
          // Show if notice is for all teachers
          final isAllTeachers = n.targetAudience == 'all_teachers';
          // Show if notice targets one of teacher's classes
          final isTargetedClass = n.classIds.any(
              (cId) => teacherClassIdentifiers.contains(cId.trim().toLowerCase()));
          // Hide drafts unless teacher is the creator
          if (n.computedStatus == 'draft' && !isCreator) return false;
          return isCreator || isAllTeachers || isTargetedClass;
        }).toList();

        // Teachers list not needed for display; keep empty
        _teachers = [];
      } else {
        // Admin: fetch everything
        final results = await Future.wait([
          _noticeRepository.getNotices(),
          _classRepository.getClasses(),
          _teacherRepository.getTeachers(),
        ]);

        final allNotices = results[0] as List<NoticeModel>;
        final rawClasses = results[1] as List<ClassModel>;
        _teachers = results[2] as List<TeacherModel>;

        final uniqueMap = <String, ClassModel>{};
        for (var c in rawClasses) {
          uniqueMap[c.classId] = c;
        }
        var resolvedClasses = uniqueMap.values.toList();
        resolvedClasses.sort((a, b) => a.className.compareTo(b.className));

        _classes = resolvedClasses;
        _notices = allNotices;
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = 'Permission denied. Unable to fetch notices.';
      } else if (e.code == 'network-request-failed') {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else {
        _errorMessage = 'Database error (${e.code}): ${e.message}';
      }
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[NoticesViewModel] fetchNoticesData FirebaseException: $e');
      }
    } catch (e) {
      _errorMessage = 'Unable to load notices. Please try again.';
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[NoticesViewModel] fetchNoticesData error: $e');
      }
    }
  }

  Future<NoticeModel?> getNoticeById(String noticeId) async {
    return await _noticeRepository.getNoticeById(noticeId);
  }

  Future<void> markNoticeAsRead(String noticeId, String userId) async {
    if (userId.isEmpty) return;
    try {
      await _noticeRepository.markNoticeAsRead(noticeId, userId);
      final idx = _notices.indexWhere((n) => n.noticeId == noticeId);
      if (idx != -1 && !_notices[idx].readUserIds.contains(userId)) {
        final updatedReadUserIds = List<String>.from(_notices[idx].readUserIds)..add(userId);
        _notices[idx] = _notices[idx].copyWith(readUserIds: updatedReadUserIds);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> createNotice({
    required String title,
    required String description,
    required String type,
    required String priority,
    required String targetAudience,
    required List<String> classIds,
    required DateTime publishDate,
    required DateTime expiryDate,
    required String createdBy,
    required String createdByName,
    required String createdByRole,
    String statusOverride = '',
    bool isPinned = false,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (cleanTitle.isEmpty || cleanTitle.length < 3) {
      _errorMessage = 'Title must be at least 3 characters.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.length > 100) {
      _errorMessage = 'Title cannot exceed 100 characters.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty || cleanDesc.length < 5) {
      _errorMessage = 'Message must be at least 5 characters.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.length > 2000) {
      _errorMessage = 'Message cannot exceed 2000 characters.';
      notifyListeners();
      return false;
    }
    if (targetAudience == 'selected_classes' && classIds.isEmpty) {
      _errorMessage = 'Please select at least one class.';
      notifyListeners();
      return false;
    }
    if (expiryDate.isBefore(DateTime(publishDate.year, publishDate.month, publishDate.day))) {
      _errorMessage = 'Expiry date cannot be before publish date.';
      notifyListeners();
      return false;
    }

    List<ClassModel> classesForValidation = _classes;
    if (classesForValidation.isEmpty) {
      try {
        classesForValidation = await _classRepository.getClasses();
      } catch (_) {}
    }

    if (createdByRole.toLowerCase() == 'teacher') {
      final teacher = await _resolveTeacher(createdBy);
      final assignedClassIds = teacher?.classIds ?? [];

      final Set<String> teacherClassIdentifiers = {};
      for (var cId in assignedClassIds) {
        if (cId.trim().isNotEmpty) teacherClassIdentifiers.add(cId.trim().toLowerCase());
      }
      for (var cls in classesForValidation) {
        if (assignedClassIds.contains(cls.classId) || assignedClassIds.contains(cls.className)) {
          if (cls.classId.trim().isNotEmpty) teacherClassIdentifiers.add(cls.classId.trim().toLowerCase());
          if (cls.className.trim().isNotEmpty) teacherClassIdentifiers.add(cls.className.trim().toLowerCase());
        }
      }

      if (classIds.isEmpty) {
        _errorMessage = 'Please select at least one class.';
        notifyListeners();
        return false;
      }

      final hasUnauthorizedClass = classIds.any((cId) => !teacherClassIdentifiers.contains(cId.trim().toLowerCase()));
      if (hasUnauthorizedClass) {
        _errorMessage = 'You can only target classes assigned to you.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final List<String> canonicalClassIds = [];
      if (targetAudience == 'selected_classes') {
        for (var cId in classIds) {
          final matched = classesForValidation.firstWhere(
            (c) => c.classId.trim().toLowerCase() == cId.trim().toLowerCase() || c.className.trim().toLowerCase() == cId.trim().toLowerCase(),
            orElse: () => ClassModel(classId: cId, className: cId, standard: '', medium: '', academicYear: ''),
          );
          canonicalClassIds.add(matched.classId);
        }
      }

      final noticeId = _noticeRepository.generateNoticeId();
      final notice = NoticeModel(
        noticeId: noticeId,
        title: cleanTitle,
        description: cleanDesc,
        type: type,
        priority: priority,
        targetAudience: targetAudience,
        classIds: targetAudience == 'selected_classes' ? canonicalClassIds : [],
        publishDate: publishDate,
        expiryDate: expiryDate,
        statusOverride: statusOverride,
        isPinned: isPinned,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByRole: createdByRole,
        createdAt: DateTime.now(),
      );

      await _noticeRepository.createNotice(notice);

      // Dispatch in-app notifications
      try {
        List<TeacherModel> teachersForNotif = _teachers;
        List<ClassModel> classesForNotif = classesForValidation;

        if (createdByRole.toLowerCase() == 'admin') {
          // Admin: ensure teachers are loaded for recipient calculation
          if (teachersForNotif.isEmpty) {
            try {
              teachersForNotif = await _teacherRepository.getTeachers();
            } catch (e) {
              if (kDebugMode) {
                debugPrint('[NoticesViewModel] Could not load teachers for notifications: $e');
              }
            }
          }
        }

        if (classesForNotif.isEmpty) {
          try {
            classesForNotif = await _classRepository.getClasses();
          } catch (_) {}
        }

        final Set<String> recipientUserIds = {};

        if (createdByRole.toLowerCase() == 'admin') {
          // Admin publishing: notify eligible teachers
          if (targetAudience == 'all_teachers') {
            for (var t in teachersForNotif) {
              final recipientUid = t.teacherId.isNotEmpty ? t.teacherId : (t.userId ?? '');
              if (recipientUid.isNotEmpty && recipientUid != createdBy) {
                recipientUserIds.add(recipientUid);
              }
            }
          } else if (targetAudience == 'selected_classes') {
            for (var t in teachersForNotif) {
              final Set<String> tClassIds = {};
              for (var cId in t.classIds) {
                tClassIds.add(cId.trim().toLowerCase());
              }
              for (var cls in classesForNotif) {
                if (tClassIds.contains(cls.classId.trim().toLowerCase()) || tClassIds.contains(cls.className.trim().toLowerCase())) {
                  tClassIds.add(cls.classId.trim().toLowerCase());
                  tClassIds.add(cls.className.trim().toLowerCase());
                }
              }

              final isAssigned = canonicalClassIds.any((cId) => tClassIds.contains(cId.trim().toLowerCase()));
              if (isAssigned) {
                final recipientUid = t.teacherId.isNotEmpty ? t.teacherId : (t.userId ?? '');
                if (recipientUid.isNotEmpty && recipientUid != createdBy) {
                  recipientUserIds.add(recipientUid);
                }
              }
            }
          }
        }

        if (createdByRole.toLowerCase() == 'teacher') {
          // Teacher publishing: notify admin
          final adminNotifId = 'notif_notice_${noticeId}_admin';
          final targetClassNames = classesForNotif
              .where((c) => canonicalClassIds.contains(c.classId) || classIds.contains(c.classId) || classIds.contains(c.className))
              .map((c) => c.className)
              .join(', ');
          final adminNotification = NotificationModel(
            notificationId: adminNotifId,
            recipientId: 'admin',
            recipientRole: 'admin',
            title: 'New Notice Published',
            message: 'Teacher $createdByName published a notice${targetClassNames.isNotEmpty ? " for $targetClassNames" : ""}: "$cleanTitle".',
            type: 'notice_published',
            referenceId: noticeId,
            referenceType: 'notice',
            isRead: false,
          );
          await _notificationRepository.createNotification(adminNotification);
        }

        // Send notifications to each eligible teacher recipient
        for (var recipientId in recipientUserIds) {
          final notifId = 'notif_notice_${noticeId}_$recipientId';
          final notification = NotificationModel(
            notificationId: notifId,
            recipientId: recipientId,
            recipientRole: 'teacher',
            title: 'New Announcement: $cleanTitle',
            message: cleanDesc.length > 80 ? '${cleanDesc.substring(0, 80)}...' : cleanDesc,
            type: 'notice_published',
            referenceId: noticeId,
            referenceType: 'notice',
            isRead: false,
          );
          await _notificationRepository.createNotification(notification);
        }
      } catch (notifErr) {
        if (kDebugMode) {
          debugPrint('[NoticesViewModel] Error dispatching notice notifications: $notifErr');
        }
      }

      _successMessage = 'Notice created successfully.';
      _isSaving = false;
      await fetchNoticesData(role: createdByRole, userId: createdBy);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create notice. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNotice({
    required String noticeId,
    required String title,
    required String description,
    required String type,
    required String priority,
    required String targetAudience,
    required List<String> classIds,
    required DateTime publishDate,
    required DateTime expiryDate,
    required String statusOverride,
    required bool isPinned,
    String? role,
    String? userId,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter a notice title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter notice content.';
      notifyListeners();
      return false;
    }
    if (targetAudience == 'selected_classes' && classIds.isEmpty) {
      _errorMessage = 'Please select at least one class.';
      notifyListeners();
      return false;
    }
    if (expiryDate.isBefore(DateTime(publishDate.year, publishDate.month, publishDate.day))) {
      _errorMessage = 'Expiry date cannot be before publish date.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _noticeRepository.getNoticeById(noticeId);
      if (existing == null) {
        _errorMessage = 'Notice not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      List<ClassModel> classesForValidation = _classes;
      if (classesForValidation.isEmpty) {
        try {
          classesForValidation = await _classRepository.getClasses();
        } catch (_) {}
      }

      final List<String> canonicalClassIds = [];
      if (targetAudience == 'selected_classes') {
        for (var cId in classIds) {
          final matched = classesForValidation.firstWhere(
            (c) => c.classId.trim().toLowerCase() == cId.trim().toLowerCase() || c.className.trim().toLowerCase() == cId.trim().toLowerCase(),
            orElse: () => ClassModel(classId: cId, className: cId, standard: '', medium: '', academicYear: ''),
          );
          canonicalClassIds.add(matched.classId);
        }
      }

      final updated = existing.copyWith(
        title: cleanTitle,
        description: cleanDesc,
        type: type,
        priority: priority,
        targetAudience: targetAudience,
        classIds: targetAudience == 'selected_classes' ? canonicalClassIds : [],
        publishDate: publishDate,
        expiryDate: expiryDate,
        statusOverride: statusOverride,
        isPinned: isPinned,
        updatedAt: DateTime.now(),
      );

      await _noticeRepository.updateNotice(updated);
      _successMessage = 'Notice updated successfully.';
      _isSaving = false;
      await fetchNoticesData(role: role, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update notice. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotice(String noticeId, {String? userRole, String? userId}) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _noticeRepository.deleteNotice(noticeId);
      _successMessage = 'Notice deleted successfully.';
      _isSaving = false;
      await fetchNoticesData(role: userRole, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete notice. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishNotice(String noticeId) async {
    try {
      final existing = await _noticeRepository.getNoticeById(noticeId);
      if (existing != null) {
        final updated = existing.copyWith(statusOverride: '');
        await _noticeRepository.updateNotice(updated);
        await fetchNoticesData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unpublishNotice(String noticeId) async {
    try {
      final existing = await _noticeRepository.getNoticeById(noticeId);
      if (existing != null) {
        final updated = existing.copyWith(statusOverride: 'draft');
        await _noticeRepository.updateNotice(updated);
        await fetchNoticesData();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
