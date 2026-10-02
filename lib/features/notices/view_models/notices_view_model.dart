import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/notice_repository.dart';

class NoticesViewModel extends ChangeNotifier {
  final NoticeRepository _noticeRepository;
  final ClassRepository _classRepository;

  NoticesViewModel({
    NoticeRepository? noticeRepository,
    ClassRepository? classRepository,
  })  : _noticeRepository = noticeRepository ?? NoticeRepository(),
        _classRepository = classRepository ?? ClassRepository();

  List<NoticeModel> _notices = [];
  List<ClassModel> _classes = [];

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
          .where((n) => n.title.toLowerCase().contains(q))
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

    if (_selectedClassFilter != null && _selectedClassFilter!.isNotEmpty) {
      list = list.where((n) {
        if (n.targetAudience == 'all_students') return true;
        return n.classIds.contains(_selectedClassFilter);
      }).toList();
    }

    // Sort: Pinned notices first, then newest createdAt/publishDate
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

  void setClassFilter(String? classId) {
    _selectedClassFilter = classId;
    notifyListeners();
  }

  Future<void> fetchNoticesData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _noticeRepository.getNotices(),
        _classRepository.getClasses(),
      ]);

      _notices = results[0] as List<NoticeModel>;
      
      final rawClasses = results[1] as List<ClassModel>;
      final uniqueMap = <String, ClassModel>{};
      for (var c in rawClasses) {
        uniqueMap[c.classId] = c;
      }
      _classes = uniqueMap.values.toList();
      _classes.sort((a, b) => a.className.compareTo(b.className));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load notices. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<NoticeModel?> getNoticeById(String noticeId) async {
    return await _noticeRepository.getNoticeById(noticeId);
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
    String statusOverride = '',
    bool isPinned = false,
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
      final noticeId = _noticeRepository.generateNoticeId();
      final notice = NoticeModel(
        noticeId: noticeId,
        title: cleanTitle,
        description: cleanDesc,
        type: type,
        priority: priority,
        targetAudience: targetAudience,
        classIds: targetAudience == 'selected_classes' ? classIds : [],
        publishDate: publishDate,
        expiryDate: expiryDate,
        statusOverride: statusOverride,
        isPinned: isPinned,
        createdBy: createdBy,
      );

      await _noticeRepository.createNotice(notice);
      _successMessage = 'Notice created successfully.';
      _isSaving = false;
      await fetchNoticesData();
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

      final updated = existing.copyWith(
        title: cleanTitle,
        description: cleanDesc,
        type: type,
        priority: priority,
        targetAudience: targetAudience,
        classIds: targetAudience == 'selected_classes' ? classIds : [],
        publishDate: publishDate,
        expiryDate: expiryDate,
        statusOverride: statusOverride,
        isPinned: isPinned,
      );

      await _noticeRepository.updateNotice(updated);
      _successMessage = 'Notice updated successfully.';
      _isSaving = false;
      await fetchNoticesData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update notice. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotice(String noticeId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _noticeRepository.deleteNotice(noticeId);
      _successMessage = 'Notice deleted successfully.';
      _isSaving = false;
      await fetchNoticesData();
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
