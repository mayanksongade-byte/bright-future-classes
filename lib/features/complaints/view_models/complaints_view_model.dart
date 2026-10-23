import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/services/firestore_service.dart';

class ComplaintsViewModel extends ChangeNotifier {
  final ComplaintRepository _complaintRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final NotificationRepository _notificationRepository;
  final FirestoreService _firestoreService;

  ComplaintsViewModel({
    ComplaintRepository? complaintRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
    NotificationRepository? notificationRepository,
    FirestoreService? firestoreService,
  })  : _complaintRepository = complaintRepository ?? ComplaintRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository(),
        _firestoreService = firestoreService ?? FirestoreService();

  List<ComplaintModel> _complaints = [];
  List<ClassModel> _classes = [];
  List<StudentModel> _students = [];
  Map<String, String> _studentNameMap = {};
  Map<String, String> _classNameMap = {};

  // Remembered role/userId so refresh calls use the correct scope
  String _lastRole = 'admin';
  String _lastUserId = '';

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

  String? _selectedStudentFilter;
  String? get selectedStudentFilter => _selectedStudentFilter;

  List<ClassModel> get classes => List.unmodifiable(_classes);
  List<StudentModel> get students => List.unmodifiable(_students);
  Map<String, String> get studentNameMap => _studentNameMap;
  Map<String, String> get classNameMap => _classNameMap;

  int get totalComplaints => _complaints.where((c) => !c.isArchived).length;
  int get openCount => _complaints.where((c) => !c.isArchived && c.status.toLowerCase() == 'open').length;
  int get inReviewCount => _complaints.where((c) {
    if (c.isArchived) return false;
    final s = c.status.toLowerCase();
    return s == 'under review' || s == 'in review';
  }).length;
  int get highPriorityCount => _complaints.where((c) => !c.isArchived && c.priority.toLowerCase() == 'high').length;
  int get resolvedCount => _complaints.where((c) => !c.isArchived && c.status.toLowerCase() == 'resolved').length;
  int get closedCount => _complaints.where((c) => !c.isArchived && c.status.toLowerCase() == 'closed').length;

  List<ComplaintModel> get filteredComplaints {
    var list = List<ComplaintModel>.from(_complaints);

    if (_selectedStatusFilter == 'Archived') {
      list = list.where((c) => c.isArchived).toList();
    } else {
      list = list.where((c) => !c.isArchived).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((c) {
        final titleMatch = c.title.toLowerCase().contains(q);
        final idMatch = c.complaintId.toLowerCase().contains(q);
        final studentName = (_studentNameMap[c.studentId] ?? '').toLowerCase();
        final className = (_classNameMap[c.classId] ?? '').toLowerCase();
        return titleMatch || idMatch || studentName.contains(q) || className.contains(q);
      }).toList();
    }

    if (_selectedTypeFilter != 'All') {
      list = list
          .where((c) => c.type.toLowerCase() == _selectedTypeFilter.toLowerCase())
          .toList();
    }

    if (_selectedStatusFilter != 'All' && _selectedStatusFilter != 'Archived') {
      final filterLower = _selectedStatusFilter.toLowerCase();
      list = list.where((c) {
        final st = c.status.toLowerCase();
        if (filterLower == 'under review') {
          return st == 'under review' || st == 'in review';
        }
        return st == filterLower;
      }).toList();
    }

    if (_selectedPriorityFilter != 'All') {
      list = list
          .where((c) => c.priority.toLowerCase() == _selectedPriorityFilter.toLowerCase())
          .toList();
    }

    if (_selectedClassFilter != null && _selectedClassFilter!.isNotEmpty) {
      list = list.where((c) => c.classId == _selectedClassFilter).toList();
    }

    if (_selectedStudentFilter != null && _selectedStudentFilter!.isNotEmpty) {
      list = list.where((c) => c.studentId == _selectedStudentFilter).toList();
    }

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
    if (_selectedStudentFilter != null && classId != null) {
      final isValid = _students.any((s) => s.studentId == _selectedStudentFilter && s.classId == classId);
      if (!isValid) {
        _selectedStudentFilter = null;
      }
    } else if (classId == null) {
      _selectedStudentFilter = null;
    }
    notifyListeners();
  }

  void setStudentFilter(String? studentId) {
    _selectedStudentFilter = studentId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTypeFilter = 'All';
    _selectedStatusFilter = 'All';
    _selectedPriorityFilter = 'All';
    _selectedClassFilter = null;
    _selectedStudentFilter = null;
    notifyListeners();
  }

  /// Resolves the Teacher profile for the given Firebase Auth UID.
  /// Only reads documents the teacher is authorized to read.
  /// Does NOT fall back to listing all teachers (permission denied for teachers).
  Future<TeacherModel?> _resolveTeacher(String uid) async {
    try {
      // 1. Check user document for teacherId or userId
      final userDoc = await _firestoreService.getUserDocument(uid);
      final customTeacherId = userDoc?['teacherId'] as String? ?? '';
      final customUserId = userDoc?['userId'] as String? ?? '';

      // Candidates to check: customTeacherId, uid, customUserId
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

      if (kDebugMode) {
        debugPrint('[ComplaintsViewModel] _resolveTeacher: No teacher doc found for uid=$uid');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ComplaintsViewModel] _resolveTeacher error for uid=$uid: $e');
      }
      return null;
    }
  }

  Future<void> fetchComplaintsData({String? role, String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = userId ?? currentUser?.uid ?? '';

      String userRole = role ?? '';
      if (userRole.isEmpty) {
        if (currentUser != null) {
          final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
          userRole = (userDoc?['role'] as String? ?? 'admin').toLowerCase();
        } else {
          userRole = 'admin';
        }
      }

      // Remember for subsequent refresh calls
      _lastRole = userRole;
      _lastUserId = uid;

      if (userRole == 'teacher') {
        // Teacher workflow: Load ONLY assigned classes, students in assigned classes, and complaints for assigned classes
        final teacher = await _resolveTeacher(uid);
        final assignedClassIds = teacher?.classIds ?? [];

        if (kDebugMode) {
          debugPrint('[ComplaintsViewModel] Teacher uid=$uid, resolved teacherId=${teacher?.teacherId}, assignedClassIds=$assignedClassIds');
        }

        if (assignedClassIds.isEmpty) {
          _classes = [];
          _students = [];
          _classNameMap = {};
          _studentNameMap = {};
          _complaints = [];
        } else {
          // 1. Load each assigned class document using its ID
          final List<ClassModel> teacherClasses = [];
          for (final cId in assignedClassIds) {
            final classData = await _firestoreService.getClassDocument(cId);
            if (classData != null) {
              teacherClasses.add(ClassModel.fromMap(classData, cId));
            }
          }
          _classes = teacherClasses;
          _classes.sort((a, b) => a.className.compareTo(b.className));
          _classNameMap = {
            for (var c in _classes) c.classId: c.className,
            for (var c in _classes) c.className: c.className,
          };

          // 2. Load students only for each assigned class using targeted queries
          final List<StudentModel> teacherStudents = [];
          final Set<String> seenStudentIds = {};
          for (final cls in _classes) {
            var sDocs = await _firestoreService.getStudentsDocumentsByClassId(cls.classId);
            if (sDocs.isEmpty && cls.className != cls.classId) {
              sDocs = await _firestoreService.getStudentsDocumentsByClassId(cls.className);
            }
            for (final doc in sDocs) {
              if (seenStudentIds.add(doc.id)) {
                teacherStudents.add(StudentModel.fromMap(doc.data(), doc.id));
              }
            }
          }
          _students = teacherStudents;
          _students.sort((a, b) => a.name.compareTo(b.name));
          _studentNameMap = {for (var s in _students) s.studentId: s.name};

          // 3. Query complaints: collect all authorized identifiers (class doc ID, className, raw classIds)
          final Set<String> queryClassIds = {};
          queryClassIds.addAll(assignedClassIds);
          for (final cls in _classes) {
            queryClassIds.add(cls.classId);
            if (cls.className.isNotEmpty) queryClassIds.add(cls.className);
          }

          _complaints = await _complaintRepository.getComplaintsForClasses(queryClassIds.toList());

          if (kDebugMode) {
            debugPrint('[ComplaintsViewModel] Fetched ${_complaints.length} complaints for queryClassIds=$queryClassIds');
          }
        }
      } else if (userRole == 'student') {
        // Student workflow: Load student complaints and student's class
        final studentDocData = await _firestoreService.getStudentDocument(uid);
        String studentId = uid;
        String? studentClassId;
        if (studentDocData != null) {
          studentId = studentDocData['studentId'] as String? ?? uid;
          studentClassId = studentDocData['classId'] as String?;
          _students = [StudentModel.fromMap(studentDocData, uid)];
          _studentNameMap = {studentId: studentDocData['name'] as String? ?? 'Student'};
        } else {
          _students = [];
          _studentNameMap = {};
        }

        _complaints = await _complaintRepository.getComplaintsForStudent(studentId);
        if (_complaints.isEmpty && uid != studentId) {
          final additional = await _complaintRepository.getComplaintsForStudent(uid);
          if (additional.isNotEmpty) {
            _complaints = additional;
          }
        }

        // Populate class names for student complaints
        final Set<String> neededClassIds = {
          if (studentClassId != null && studentClassId.isNotEmpty) studentClassId,
          for (var c in _complaints) if (c.classId.isNotEmpty) c.classId,
        };
        final List<ClassModel> studentClasses = [];
        for (final cId in neededClassIds) {
          final classData = await _firestoreService.getClassDocument(cId);
          if (classData != null) {
            studentClasses.add(ClassModel.fromMap(classData, cId));
          }
        }
        _classes = studentClasses;
        _classNameMap = {
          for (var c in _classes) c.classId: c.className,
          for (var c in _classes) c.className: c.className,
        };
      } else {
        // Admin workflow: Load all classes, students, and complaints
        final results = await Future.wait([
          _classRepository.getClasses(),
          _studentRepository.getStudents(),
          _complaintRepository.getComplaints(),
        ]);

        final rawClasses = results[0] as List<ClassModel>;
        final uniqueMap = <String, ClassModel>{};
        for (var c in rawClasses) {
          uniqueMap[c.classId] = c;
        }
        _classes = uniqueMap.values.toList();
        _classes.sort((a, b) => a.className.compareTo(b.className));
        _classNameMap = {
          for (var c in _classes) c.classId: c.className,
          for (var c in _classes) c.className: c.className,
        };

        _students = results[1] as List<StudentModel>;
        _students.sort((a, b) => a.name.compareTo(b.name));
        _studentNameMap = {for (var s in _students) s.studentId: s.name};

        _complaints = results[2] as List<ComplaintModel>;
      }

      _complaints.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2025);
        final dateB = b.createdAt ?? DateTime(2025);
        return dateB.compareTo(dateA);
      });

      if (kDebugMode) {
        debugPrint('[ComplaintsViewModel] Final complaints count: ${_complaints.length}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ComplaintsViewModel] Error fetching complaints: $e');
      _errorMessage = 'Unable to load complaints. Please try again.\n${e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '')}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ComplaintModel?> getComplaintById(String complaintId) async {
    return await _complaintRepository.getComplaintById(complaintId);
  }

  Future<bool> createComplaint({
    required String studentId,
    required String classId,
    required String type,
    required String title,
    required String description,
    required String priority,
    required String incidentDate,
    String resolutionNote = '',
    required String createdBy,
    required String createdByName,
    required String createdByRole,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (studentId.isEmpty) {
      _errorMessage = 'Please select a student.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter issue title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter issue description.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final complaintId = _complaintRepository.generateComplaintId();
      final now = DateTime.now();
      final todayFormatted = '${now.day} ${_monthName(now.month)} ${now.year}';

      final history = [
        {
          'event': 'Complaint reported ($todayFormatted)',
          'timestamp': now.toIso8601String(),
          'by': createdByName,
        }
      ];

      final complaint = ComplaintModel(
        complaintId: complaintId,
        studentId: studentId,
        classId: classId,
        type: type,
        title: cleanTitle,
        description: cleanDesc,
        priority: priority,
        status: 'Open',
        resolutionNote: resolutionNote.trim(),
        createdBy: createdBy,
        createdByName: createdByName,
        createdByRole: createdByRole,
        incidentDate: incidentDate.isNotEmpty ? incidentDate : todayFormatted,
        activityHistory: history,
        createdAt: now,
      );

      await _complaintRepository.createComplaint(complaint);
      if (kDebugMode) {
        debugPrint('[COMPLAINT_SAVE_SUCCESS] Complaint ID: $complaintId');
      }

      final targetStudent = _students.firstWhere(
        (s) => s.studentId == studentId,
        orElse: () => StudentModel(studentId: studentId, name: '', phone: '', parentName: '', parentPhone: ''),
      );

      // 1. Student Notification (isolated)
      try {
        final notifId = 'notif_complaint_${DateTime.now().millisecondsSinceEpoch}';
        final notification = NotificationModel(
          notificationId: notifId,
          recipientId: targetStudent.userId ?? studentId,
          recipientRole: 'student',
          title: 'New Issue Reported',
          message: 'An issue "$cleanTitle" has been reported.',
          type: 'complaint_created',
          referenceId: complaintId,
          referenceType: 'complaint',
          isRead: false,
        );
        await _notificationRepository.createNotification(notification);
        if (kDebugMode) {
          debugPrint('[STUDENT_NOTIFICATION_WRITE_SUCCESS] Student notification created for ${targetStudent.studentId}');
        }
      } catch (studentNotifErr) {
        if (kDebugMode) {
          debugPrint('[STUDENT_NOTIFICATION_WRITE_FAILED] Error: $studentNotifErr');
        }
      }

      // 2. Admin Notification (isolated)
      if (createdByRole.toLowerCase() == 'teacher') {
        if (kDebugMode) {
          debugPrint('[ADMIN_NOTIFICATION_START] Creating admin notification for complaint: $complaintId');
        }
        try {
          final adminNotifId = 'notif_admin_comp_${DateTime.now().millisecondsSinceEpoch}';
          final studentName = targetStudent.name.isNotEmpty ? targetStudent.name : 'Student';
          final nowStr = '${now.day} ${_monthName(now.month)} ${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          
          final adminNotification = NotificationModel(
            notificationId: adminNotifId,
            recipientId: 'admin',
            recipientRole: 'admin',
            title: 'New Teacher Complaint',
            message: 'Teacher $createdByName filed a complaint regarding $studentName: "$cleanTitle" ($nowStr).',
            type: 'complaint_created',
            referenceId: complaintId,
            referenceType: 'complaint',
            isRead: false,
          );

          if (kDebugMode) {
            debugPrint('[ADMIN_NOTIFICATION_PAYLOAD_READY] Payload recipientRole: ${adminNotification.recipientRole}, refType: ${adminNotification.referenceType}');
          }

          await _notificationRepository.createNotification(adminNotification);

          if (kDebugMode) {
            debugPrint('[ADMIN_NOTIFICATION_WRITE_SUCCESS] Admin notification written to Firestore successfully! ID: $adminNotifId');
          }
        } catch (adminNotifErr) {
          if (kDebugMode) {
            debugPrint('[ADMIN_NOTIFICATION_WRITE_FAILED] Error creating admin notification: $adminNotifErr');
          }
        }
      }

      _successMessage = 'Complaint submitted successfully.';
      _isSaving = false;
      // Refresh with the remembered role and userId, or fallback to creator's role and uid
      await fetchComplaintsData(
        role: _lastRole.isNotEmpty ? _lastRole : createdByRole,
        userId: _lastUserId.isNotEmpty ? _lastUserId : createdBy,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create complaint. Please try again.\n$e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComplaint({
    required String complaintId,
    required String studentId,
    required String classId,
    required String type,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? resolutionNote,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (studentId.isEmpty) {
      _errorMessage = 'Please select a student.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter complaint title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter complaint description.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updated = existing.copyWith(
        studentId: studentId,
        classId: classId,
        type: type,
        title: cleanTitle,
        description: cleanDesc,
        priority: priority,
        status: status,
        resolutionNote: resolutionNote != null ? resolutionNote.trim() : existing.resolutionNote,
      );

      await _complaintRepository.updateComplaint(updated);
      _successMessage = 'Complaint updated successfully.';
      _isSaving = false;
      await fetchComplaintsData(role: _lastRole, userId: _lastUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update complaint. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveComplaint({
    required String complaintId,
    required String resolutionNote,
    required String resolvedBy,
    required String resolvedByRole,
  }) async {
    final cleanNote = resolutionNote.trim();
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final todayFormatted = '${now.day} ${_monthName(now.month)} ${now.year}';

      final history = List<Map<String, dynamic>>.from(existing.activityHistory);
      history.add({
        'event': 'Resolved by $resolvedBy (${resolvedByRole.toUpperCase()}) on $todayFormatted',
        'timestamp': now.toIso8601String(),
        'by': resolvedBy,
      });

      final currentUser = FirebaseAuth.instance.currentUser;

      final updated = existing.copyWith(
        status: 'Resolved',
        resolutionNote: cleanNote.isNotEmpty ? cleanNote : existing.resolutionNote,
        resolvedAt: now,
        resolvedById: currentUser?.uid,
        resolvedByName: resolvedBy,
        resolvedByRole: resolvedByRole,
        activityHistory: history,
        updatedAt: now,
      );

      await _complaintRepository.updateComplaint(updated);

      try {
        final notifId = 'notif_resolved_${DateTime.now().millisecondsSinceEpoch}';
        final notification = NotificationModel(
          notificationId: notifId,
          recipientId: existing.studentId,
          recipientRole: 'student',
          title: 'Issue Resolved',
          message: 'The reported issue "${existing.title}" has been marked as resolved.',
          type: 'complaint_resolved',
          referenceId: complaintId,
          referenceType: 'complaint',
          isRead: false,
        );
        await _notificationRepository.createNotification(notification);
      } catch (_) {}

      _successMessage = 'Complaint marked as resolved.';
      _isSaving = false;
      await fetchComplaintsData(role: _lastRole, userId: _lastUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to mark complaint as resolved: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitStudentResponse({
    required String complaintId,
    required String responseText,
    required String studentUid,
    required String studentName,
  }) async {
    final cleanText = responseText.trim();
    if (cleanText.isEmpty) {
      _errorMessage = 'Response text cannot be empty.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final todayFormatted = '${now.day} ${_monthName(now.month)} ${now.year}';

      final history = List<Map<String, dynamic>>.from(existing.activityHistory);
      history.add({
        'event': 'Student response submitted ($todayFormatted)',
        'timestamp': now.toIso8601String(),
        'by': studentName,
      });

      final updated = existing.copyWith(
        studentResponse: cleanText,
        studentResponseAt: now,
        status: existing.status == 'Open' ? 'Under Review' : existing.status,
        activityHistory: history,
        updatedAt: now,
      );

      await _complaintRepository.updateComplaint(updated);

      try {
        final notifId = 'notif_resp_${DateTime.now().millisecondsSinceEpoch}';
        final notification = NotificationModel(
          notificationId: notifId,
          recipientId: 'admin',
          recipientRole: 'admin',
          title: 'Student Response Submitted',
          message: 'Student $studentName submitted a response to complaint "${existing.title}".',
          type: 'complaint_responded',
          referenceId: complaintId,
          referenceType: 'complaint',
          isRead: false,
        );
        await _notificationRepository.createNotification(notification);
      } catch (_) {}

      _successMessage = 'Response submitted successfully.';
      _isSaving = false;
      await fetchComplaintsData(role: _lastRole, userId: _lastUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to submit response. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> acknowledgeComplaint({
    required String complaintId,
    required String studentUid,
    required String studentName,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final now = DateTime.now();
      final todayFormatted = '${now.day} ${_monthName(now.month)} ${now.year}';

      final history = List<Map<String, dynamic>>.from(existing.activityHistory);
      history.add({
        'event': 'Complaint acknowledged ($todayFormatted)',
        'timestamp': now.toIso8601String(),
        'by': studentName,
      });

      final updated = existing.copyWith(
        isAcknowledged: true,
        acknowledgedAt: now,
        activityHistory: history,
        updatedAt: now,
      );

      await _complaintRepository.updateComplaint(updated);
      _successMessage = 'Complaint acknowledged.';
      _isSaving = false;
      await fetchComplaintsData(role: _lastRole, userId: _lastUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Unable to acknowledge complaint: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComplaint(String complaintId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _complaintRepository.deleteComplaint(complaintId);
      _successMessage = 'Complaint deleted successfully.';
      _isSaving = false;
      await fetchComplaintsData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> archiveComplaint(String complaintId, bool archive) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final todayFormatted = '${now.day} ${_monthName(now.month)} ${now.year}';

      final history = List<Map<String, dynamic>>.from(existing.activityHistory);
      history.add({
        'event': archive ? 'Complaint archived ($todayFormatted)' : 'Complaint restored ($todayFormatted)',
        'timestamp': now.toIso8601String(),
        'by': currentUser?.email ?? 'Staff',
      });

      final updated = existing.copyWith(
        isArchived: archive,
        archivedAt: archive ? now : null,
        archivedBy: archive ? currentUser?.uid : null,
        activityHistory: history,
        updatedAt: now,
      );

      await _complaintRepository.updateComplaint(updated);
      _successMessage = archive ? 'Complaint archived successfully.' : 'Complaint restored successfully.';
      _isSaving = false;
      await fetchComplaintsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update archive status: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
