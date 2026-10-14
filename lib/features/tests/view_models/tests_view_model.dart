import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/mark_audit_model.dart';
import '../../../data/models/mark_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/test_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/firestore_service.dart';

class TestItem {
  final TestModel test;
  final ClassModel? classModel;
  final List<MarkModel> marks;
  final List<MarkAuditModel> audits;
  final List<StudentModel> studentsInClass;

  TestItem({
    required this.test,
    this.classModel,
    required this.marks,
    this.audits = const [],
    required this.studentsInClass,
  });

  int get totalStudents => studentsInClass.length;

  int get marksEnteredCount {
    return marks.where((m) => m.marks != null || m.isAbsent).length;
  }

  String get status {
    if (test.isCancelled) return 'Cancelled';
    if (totalStudents == 0) return 'Marks Not Entered';
    if (marksEnteredCount == 0) return 'Marks Not Entered';
    if (marksEnteredCount < totalStudents) return 'Partially Entered';
    return 'Completed';
  }

  String get creatorAttribution {
    final name = (test.createdByName != null && test.createdByName!.isNotEmpty)
        ? test.createdByName!
        : (test.createdByRole?.toLowerCase() == 'teacher' ? 'Teacher' : 'Admin');
    final role = (test.createdByRole != null && test.createdByRole!.isNotEmpty)
        ? test.createdByRole!.toUpperCase()
        : 'ADMIN';
    return 'Created by: $name ($role)';
  }

  String get dateTimingTag {
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (test.testDate.compareTo(todayStr) > 0) {
      return 'Upcoming Test';
    } else if (test.testDate == todayStr) {
      return 'Today';
    }
    return '';
  }

  bool get isFutureExamDate {
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return test.testDate.isNotEmpty && test.testDate.trim().compareTo(todayStr) > 0;
  }

  String get editorAttribution {
    if (marksEnteredCount == 0) {
      return isFutureExamDate ? 'Marks entry available on ${test.testDate}' : 'Marks pending';
    }

    if (audits.isEmpty) {
      return 'Marks saved · Attribution unavailable';
    }

    final distinctEditors = <String, String>{};
    for (var a in audits) {
      final name = a.editedByName.isNotEmpty ? a.editedByName : 'User';
      final role = a.editedByRole.isNotEmpty ? a.editedByRole.toUpperCase() : 'USER';
      distinctEditors[name] = role;
    }

    if (distinctEditors.length == 1) {
      final entry = distinctEditors.entries.first;
      final action = audits.length > 1 ? 'Last updated by' : 'Marks entered by';
      return '$action: ${entry.key} (${entry.value})';
    } else if (distinctEditors.length > 1) {
      return 'Marks updated by ${distinctEditors.length} users';
    } else {
      final lastAudit = audits.last;
      final name = lastAudit.editedByName.isNotEmpty ? lastAudit.editedByName : 'User';
      final role = lastAudit.editedByRole.isNotEmpty ? lastAudit.editedByRole.toUpperCase() : 'USER';
      return 'Last updated by: $name ($role)';
    }
  }
}

class TestResultRow {
  final StudentModel student;
  final MarkModel? mark;
  final MarkAuditModel? latestAudit;
  final double totalMarks;
  final double? passingMarks;

  TestResultRow({
    required this.student,
    this.mark,
    this.latestAudit,
    required this.totalMarks,
    this.passingMarks,
  });

  bool get isAbsent => mark?.isAbsent ?? false;
  double? get marksValue => mark?.marks;
  String? get remarks => mark?.remarks;

  String get marksDisplay {
    if (isAbsent) return 'Absent';
    if (marksValue == null) return '--';
    return '${marksValue!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}/${totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}';
  }

  double get percentage {
    if (isAbsent || marksValue == null || totalMarks <= 0) return 0.0;
    return (marksValue! / totalMarks) * 100.0;
  }

  String get percentageDisplay {
    if (isAbsent || marksValue == null) return '--';
    return '${percentage.toStringAsFixed(1)}%';
  }

  String get result {
    if (isAbsent) return 'Absent';
    if (marksValue == null) return 'Pending';
    if (passingMarks != null) {
      return marksValue! >= passingMarks! ? 'Pass' : 'Fail';
    }
    return 'Pass';
  }
}

class TestsViewModel extends ChangeNotifier {
  final TestRepository _testRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;
  final NotificationRepository _notificationRepository;
  final FirestoreService _firestoreService;

  TestsViewModel({
    TestRepository? testRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
    TeacherRepository? teacherRepository,
    NotificationRepository? notificationRepository,
    FirestoreService? firestoreService,
  })  : _testRepository = testRepository ?? TestRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository(),
        _firestoreService = firestoreService ?? FirestoreService();

  List<TestItem> _testItems = [];
  List<TestItem> get testItems {
    var list = _testItems;
    if (_classFilter != null && _classFilter!.isNotEmpty) {
      list = list.where((item) => item.test.classId == _classFilter).toList();
    }
    if (_subjectFilter != null && _subjectFilter!.trim().isNotEmpty) {
      final q = _subjectFilter!.trim().toLowerCase();
      list = list.where((item) => item.test.subject.toLowerCase().contains(q)).toList();
    }
    if (_nameFilter != null && _nameFilter!.trim().isNotEmpty) {
      final q = _nameFilter!.trim().toLowerCase();
      list = list.where((item) => item.test.testName.toLowerCase().contains(q)).toList();
    }
    if (_dateFilter != null && _dateFilter!.isNotEmpty) {
      list = list.where((item) => item.test.testDate == _dateFilter).toList();
    }
    return list;
  }

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _classFilter;
  String? get classFilter => _classFilter;

  String? _subjectFilter;
  String? get subjectFilter => _subjectFilter;

  String? _nameFilter;
  String? get nameFilter => _nameFilter;

  String? _dateFilter;
  String? get dateFilter => _dateFilter;

  void setClassFilter(String? classId) {
    _classFilter = classId;
    notifyListeners();
  }

  void setSubjectFilter(String? subject) {
    _subjectFilter = subject;
    notifyListeners();
  }

  void setNameFilter(String? name) {
    _nameFilter = name;
    notifyListeners();
  }

  void setDateFilter(String? date) {
    _dateFilter = date;
    notifyListeners();
  }

  void clearFilters() {
    _classFilter = null;
    _subjectFilter = null;
    _nameFilter = null;
    _dateFilter = null;
    notifyListeners();
  }

  Future<void> fetchTestsData({String? teacherUid}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      String? activeTeacherUid = teacherUid;

      // Auto-detect if logged in user is a Teacher when teacherUid is not passed explicitly
      if ((activeTeacherUid == null || activeTeacherUid.isEmpty) && currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        final role = (userDoc?['role'] as String? ?? '').toLowerCase();
        if (role == 'teacher') {
          activeTeacherUid = currentUser.uid;
        }
      }

      List<ClassModel> availableClasses = [];
      List<String> assignedClassIds = [];

      if (activeTeacherUid != null && activeTeacherUid.isNotEmpty) {
        final userDoc = await _firestoreService.getUserDocument(activeTeacherUid);
        final customTeacherId = userDoc?['teacherId'] as String? ?? '';
        final customUserId = userDoc?['userId'] as String? ?? '';

        Map<String, dynamic>? teacherData = await _firestoreService.getTeacherDocument(activeTeacherUid);
        String resolvedDocId = activeTeacherUid;

        if (teacherData == null && customTeacherId.isNotEmpty) {
          teacherData = await _firestoreService.getTeacherDocument(customTeacherId);
          resolvedDocId = customTeacherId;
        }

        if (teacherData == null) {
          try {
            final teacherDocs = await _firestoreService.getTeachersDocuments();
            for (var doc in teacherDocs) {
              final data = doc.data();
              final uidVal = data['uid'] as String? ?? '';
              final userIdVal = data['userId'] as String? ?? '';
              final tIdVal = data['teacherId'] as String? ?? '';

              if (doc.id == activeTeacherUid ||
                  doc.id == customTeacherId ||
                  uidVal == activeTeacherUid ||
                  userIdVal == customUserId ||
                  tIdVal == customTeacherId) {
                teacherData = data;
                resolvedDocId = doc.id;
                break;
              }
            }
          } catch (_) {}
        }

        final teacher = teacherData != null
            ? TeacherModel.fromMap(teacherData, resolvedDocId)
            : null;
        assignedClassIds = teacher?.classIds ?? [];

        List<ClassModel> teacherClasses = [];
        for (var cId in assignedClassIds) {
          final cData = await _firestoreService.getClassDocument(cId);
          if (cData != null) {
            teacherClasses.add(ClassModel.fromMap(cData, cId));
          }
        }
        availableClasses = teacherClasses;
      } else {
        availableClasses = await _classRepository.getClasses();
      }

      _classes = availableClasses;

      List<StudentModel> activeStudents = [];
      if (activeTeacherUid != null && activeTeacherUid.isNotEmpty) {
        final List<StudentModel> teacherStudents = [];
        for (var cId in assignedClassIds) {
          final sDocs = await _firestoreService.getStudentsDocumentsByClassId(cId);
          for (var doc in sDocs) {
            final s = StudentModel.fromMap(doc.data(), doc.id);
            if (s.status.toLowerCase() == 'active') {
              teacherStudents.add(s);
            }
          }
        }
        activeStudents = teacherStudents;
      } else {
        final allStudents = await _studentRepository.getStudents();
        activeStudents = allStudents
            .where((s) => s.status.toLowerCase() == 'active')
            .toList();
      }

      final classStudentMap = <String, List<StudentModel>>{};
      for (var s in activeStudents) {
        if (s.classId != null) {
          classStudentMap.putIfAbsent(s.classId!, () => []).add(s);
        }
      }

      List<TestModel> tests = [];
      if (activeTeacherUid != null && activeTeacherUid.isNotEmpty) {
        final Map<String, TestModel> uniqueTestMap = {};
        for (var cId in assignedClassIds) {
          final classTests = await _testRepository.getTestsForClass(cId);
          for (var t in classTests) {
            uniqueTestMap[t.testId] = t;
          }
        }
        tests = uniqueTestMap.values.toList();
        tests.sort((a, b) => b.testDate.compareTo(a.testDate));
      } else {
        tests = await _testRepository.getAllTests();
      }

      final Map<String, ClassModel> classMap = {for (var c in _classes) c.classId: c};
      for (var test in tests) {
        if (!classMap.containsKey(test.classId) && test.classId.isNotEmpty) {
          try {
            final cData = await _firestoreService.getClassDocument(test.classId);
            if (cData != null) {
              classMap[test.classId] = ClassModel.fromMap(cData, test.classId);
            }
          } catch (_) {}
        }
      }

      final testItemsList = <TestItem>[];

      for (var test in tests) {
        final marks = await _testRepository.getMarksForTest(test.testId, classId: test.classId);
        final audits = await _testRepository.getMarkAuditsForTest(test.testId, classId: test.classId);
        final studentsInClass = classStudentMap[test.classId] ?? [];
        testItemsList.add(TestItem(
          test: test,
          classModel: classMap[test.classId],
          marks: marks,
          audits: audits,
          studentsInClass: studentsInClass,
        ));
      }

      _testItems = testItemsList;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[TestsViewModel.fetchTestsData] Error loading tests: $e');
      _errorMessage = 'Unable to load tests. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTest({
    required String testName,
    required String classId,
    required String subject,
    required String testDate,
    required double totalMarks,
    double? passingMarks,
    required String description,
    required String createdBy,
    String? createdByName,
    String? createdByRole,
  }) async {
    final cleanName = testName.trim();
    final cleanSubject = subject.trim();
    final cleanDesc = description.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Test name cannot be empty.';
      notifyListeners();
      return false;
    }
    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanSubject.isEmpty) {
      _errorMessage = 'Subject cannot be empty.';
      notifyListeners();
      return false;
    }
    if (testDate.isEmpty) {
      _errorMessage = 'Test date is required.';
      notifyListeners();
      return false;
    }
    if (totalMarks <= 0) {
      _errorMessage = 'Total marks must be greater than 0.';
      notifyListeners();
      return false;
    }
    if (passingMarks != null) {
      if (passingMarks < 0) {
        _errorMessage = 'Passing marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (passingMarks > totalMarks) {
        _errorMessage = 'Passing marks cannot be greater than total marks.';
        notifyListeners();
        return false;
      }
    }

    // Phase 2: Enforce Teacher subject and class authorization in write path
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
      final role = (userDoc?['role'] as String? ?? '').toLowerCase();
      if (role == 'teacher') {
        final teacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;
        final teacherData = await _firestoreService.getTeacherDocument(teacherId);
        final teacher = teacherData != null ? TeacherModel.fromMap(teacherData, teacherId) : null;

        if (teacher == null || !teacher.classIds.contains(classId) || !teacher.teachesSubject(cleanSubject)) {
          _errorMessage = 'Unauthorized: You are not assigned to teach $cleanSubject for this class.';
          notifyListeners();
          return false;
        }
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final testId = _testRepository.generateTestId();
      final test = TestModel(
        testId: testId,
        testName: cleanName,
        classId: classId,
        subject: cleanSubject,
        testDate: testDate,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: cleanDesc,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByRole: createdByRole,
      );

      await _testRepository.saveTest(test);

      // Phase 2: Route test-created notifications by class AND subject
      if ((createdByRole ?? '').toLowerCase() == 'admin') {
        final teachers = await _teacherRepository.getTeachers();
        final assignedTeachers = teachers.where((t) => t.classIds.contains(classId) && t.teachesSubject(cleanSubject)).toList();
        for (var t in assignedTeachers) {
          final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}_${t.teacherId}';
          final notification = NotificationModel(
            notificationId: notifId,
            recipientId: t.teacherId, // Auth UID
            recipientRole: 'teacher',
            type: 'test_created',
            title: 'New Test Created by Admin',
            message: '${createdByName ?? "Admin"} created $cleanSubject test "$cleanName" for your class.',
            referenceId: testId,
            referenceType: 'test',
            isRead: false,
          );
          await _notificationRepository.createNotification(notification);
        }
      } else {
        // Teacher created test -> notify Admin
        final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
        final notification = NotificationModel(
          notificationId: notifId,
          recipientId: 'admin',
          recipientRole: 'admin',
          type: 'test_created',
          title: 'New Test Created by Teacher',
          message: 'Teacher ${createdByName ?? "Teacher"} created $cleanSubject test "$cleanName" for Date: $testDate.',
          referenceId: testId,
          referenceType: 'test',
          isRead: false,
        );
        await _notificationRepository.createNotification(notification);
      }

      _successMessage = 'Test created successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTest({
    required String testId,
    required String testName,
    required String classId,
    required String subject,
    required String testDate,
    required double totalMarks,
    double? passingMarks,
    required String description,
  }) async {
    final cleanName = testName.trim();
    final cleanSubject = subject.trim();
    final cleanDesc = description.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Test name cannot be empty.';
      notifyListeners();
      return false;
    }
    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanSubject.isEmpty) {
      _errorMessage = 'Subject cannot be empty.';
      notifyListeners();
      return false;
    }
    if (testDate.isEmpty) {
      _errorMessage = 'Test date is required.';
      notifyListeners();
      return false;
    }
    if (totalMarks <= 0) {
      _errorMessage = 'Total marks must be greater than 0.';
      notifyListeners();
      return false;
    }
    if (passingMarks != null) {
      if (passingMarks < 0) {
        _errorMessage = 'Passing marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (passingMarks > totalMarks) {
        _errorMessage = 'Passing marks cannot be greater than total marks.';
        notifyListeners();
        return false;
      }
    }

    // Phase 2: Enforce Teacher authorization on update
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
      final role = (userDoc?['role'] as String? ?? '').toLowerCase();
      if (role == 'teacher') {
        final teacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;
        final teacherData = await _firestoreService.getTeacherDocument(teacherId);
        final teacher = teacherData != null ? TeacherModel.fromMap(teacherData, teacherId) : null;

        if (teacher == null || !teacher.classIds.contains(classId) || !teacher.teachesSubject(cleanSubject)) {
          _errorMessage = 'Unauthorized: You are not assigned to teach $cleanSubject for this class.';
          notifyListeners();
          return false;
        }
      }
    }

    // Check if totalMarks is reduced below any already-entered student marks
    final existingMarks = await _testRepository.getMarksForTest(testId);
    for (var m in existingMarks) {
      if (!m.isAbsent && m.marks != null && m.marks! > totalMarks) {
        _errorMessage =
            'Total marks cannot be reduced below already entered student marks (${m.marks}).';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existingTest = await _testRepository.getTest(testId);
      if (existingTest == null) {
        _errorMessage = 'Test not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updated = existingTest.copyWith(
        testName: cleanName,
        classId: classId,
        subject: cleanSubject,
        testDate: testDate,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: cleanDesc,
      );

      await _testRepository.updateTest(updated);
      _successMessage = 'Test updated successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelTest(String testId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _testRepository.cancelTest(testId);
      _successMessage = 'Test cancelled. Historical marks and audit records preserved.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to cancel test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTest(String testId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _testRepository.deleteTest(testId);
      _successMessage = 'Test deleted successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveStudentMarks({
    required TestModel test,
    required Map<String, String> marksInputMap, // studentId -> text
    required Map<String, bool> absentMap, // studentId -> bool
    Map<String, String> remarksInputMap = const {}, // studentId -> remark
    Map<String, String> studentNameMap = const {}, // studentId -> studentName
    required String currentUserId,
    required String currentUserName,
    required String currentUserRole,
  }) async {
    // Strict exam-date restriction: No one can save marks before scheduled testDate
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (test.testDate.isNotEmpty && test.testDate.trim().compareTo(todayStr) > 0) {
      _errorMessage = 'Marks entry available on ${test.testDate}.';
      notifyListeners();
      return false;
    }

    // Validate marks inputs
    for (var entry in marksInputMap.entries) {
      final studentId = entry.key;
      final isAbs = absentMap[studentId] ?? false;
      if (isAbs) continue;

      final valStr = entry.value.trim();
      if (valStr.isEmpty) continue;

      final parsed = double.tryParse(valStr);
      if (parsed == null) {
        _errorMessage = 'Please enter valid numeric marks.';
        notifyListeners();
        return false;
      }
      if (parsed < 0) {
        _errorMessage = 'Marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (parsed > test.totalMarks) {
        _errorMessage =
            'Marks cannot exceed total marks (${test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}).';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existingMarksList = await _testRepository.getMarksForTest(test.testId, classId: test.classId);
      final existingMarksMap = {for (var m in existingMarksList) m.studentId: m};

      final List<MarkModel> batch = [];
      final List<MarkAuditModel> auditBatch = [];

      for (var entry in marksInputMap.entries) {
        final studentId = entry.key;
        final isAbs = absentMap[studentId] ?? false;
        final valStr = entry.value.trim();
        final remarkText = (remarksInputMap[studentId] ?? '').trim();

        double? mVal;
        if (!isAbs && valStr.isNotEmpty) {
          mVal = double.tryParse(valStr);
        }

        final existing = existingMarksMap[studentId];
        final oldVal = existing?.marks;
        final oldAbs = existing?.isAbsent ?? false;
        final oldRem = existing?.remarks;

        // Check if changed
        final bool isChanged = existing == null ||
            oldVal != mVal ||
            oldAbs != isAbs ||
            (oldRem ?? '') != remarkText;

        if (isAbs || mVal != null || remarkText.isNotEmpty) {
          final markId = MarkModel.generateId(test.testId, studentId);
          final updatedMark = MarkModel(
            markId: markId,
            testId: test.testId,
            studentId: studentId,
            classId: test.classId,
            marks: isAbs ? null : mVal,
            isAbsent: isAbs,
            remarks: remarkText.isNotEmpty ? remarkText : null,
            createdAt: existing?.createdAt, // Preserve existing createdAt timestamp!
          );
          batch.add(updatedMark);

          if (isChanged) {
            final bool isInitialEntry = existing == null || (oldVal == null && !oldAbs && (oldRem == null || oldRem.isEmpty));
            final String changeType = isInitialEntry ? 'Marks Entered' : 'Marks Updated';
            final String studentName = studentNameMap[studentId] ?? '';

            final auditId = '${test.testId}_${studentId}_${DateTime.now().millisecondsSinceEpoch}';
            auditBatch.add(MarkAuditModel(
              auditId: auditId,
              testId: test.testId,
              testName: test.testName,
              classId: test.classId,
              studentId: studentId,
              studentName: studentName,
              oldMarks: oldVal,
              newMarks: isAbs ? null : mVal,
              oldIsAbsent: oldAbs,
              newIsAbsent: isAbs,
              oldRemarks: oldRem,
              newRemarks: remarkText.isNotEmpty ? remarkText : null,
              editedByUid: currentUserId,
              editedByRole: currentUserRole,
              editedByName: currentUserName,
              changeType: changeType,
            ));
          }
        }
      }

      if (batch.isNotEmpty) {
        await _testRepository.saveMarksBatchWithAudit(batch, auditBatch);

        // Targeted In-App Notifications for Marks Entry / Editing
        if (currentUserRole.toLowerCase() == 'admin') {
          final teachers = await _teacherRepository.getTeachers();
          final assignedTeachers = teachers.where((t) => t.classIds.contains(test.classId) && t.teachesSubject(test.subject)).toList();
          for (var t in assignedTeachers) {
            final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}_${t.teacherId}';
            final notification = NotificationModel(
              notificationId: notifId,
              recipientId: t.teacherId, // Auth UID e.g. X9z...
              recipientRole: 'teacher',
              type: 'marks_updated',
              title: 'Marks Updated by Admin',
              message: 'Admin $currentUserName saved/updated marks for ${auditBatch.length} student(s) in ${test.subject} test "${test.testName}".',
              referenceId: test.testId,
              referenceType: 'test',
              isRead: false,
            );
            await _notificationRepository.createNotification(notification);
          }
        } else {
          final notifId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
          final notification = NotificationModel(
            notificationId: notifId,
            recipientId: 'admin',
            recipientRole: 'admin',
            type: 'marks_updated',
            title: 'Marks Saved by Teacher',
            message: 'Teacher $currentUserName saved/updated marks for ${auditBatch.length} student(s) in ${test.subject} test "${test.testName}".',
            referenceId: test.testId,
            referenceType: 'test',
            isRead: false,
          );
          await _notificationRepository.createNotification(notification);
        }
      }

      _successMessage = 'Marks saved successfully.';
      _isSaving = false;
      try {
        await fetchTestsData();
      } catch (_) {}
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[TestsViewModel.saveStudentMarks] Failed to save marks: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
