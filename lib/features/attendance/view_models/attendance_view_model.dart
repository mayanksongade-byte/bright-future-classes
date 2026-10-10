import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/attendance_audit_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;
  final NotificationRepository _notificationRepository;

  AttendanceViewModel({
    AttendanceRepository? attendanceRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
    TeacherRepository? teacherRepository,
    NotificationRepository? notificationRepository,
  })  : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository();

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  ClassModel? _selectedClass;
  ClassModel? get selectedClass => _selectedClass;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<StudentModel> _students = [];
  List<StudentModel> get students => List.unmodifiable(_students);

  final Map<String, String> _attendanceMap = {};
  Map<String, String> get attendanceMap => Map.unmodifiable(_attendanceMap);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  int _adminTabIndex = 0; // 0 = Mark Attendance, 1 = Submitted Sessions
  int get adminTabIndex => _adminTabIndex;

  DateTime _submittedSessionsDate = DateTime.now();
  DateTime get submittedSessionsDate => _submittedSessionsDate;

  List<Map<String, dynamic>> _submittedSessions = [];
  List<Map<String, dynamic>> get submittedSessions => List.unmodifiable(_submittedSessions);

  List<AttendanceAuditModel> _sessionAudits = [];
  List<AttendanceAuditModel> get sessionAudits => List.unmodifiable(_sessionAudits);

  bool _isExistingSessionSubmitted = false;
  bool get isExistingSessionSubmitted => _isExistingSessionSubmitted;

  String _existingSubmitterName = '';
  String get existingSubmitterName => _existingSubmitterName;

  String _existingSubmitterRole = '';
  String get existingSubmitterRole => _existingSubmitterRole;

  String _existingSubmitterUid = '';
  String get existingSubmitterUid => _existingSubmitterUid;

  bool _existingTeacherEditUsed = false;
  bool get existingTeacherEditUsed => _existingTeacherEditUsed;

  int get totalStudents => _students.length;

  int get presentCount =>
      _attendanceMap.values.where((status) => status.toLowerCase() == 'present').length;

  int get absentCount =>
      _attendanceMap.values.where((status) => status.toLowerCase() == 'absent').length;

  double get attendancePercentage {
    if (totalStudents == 0) return 0.0;
    return (presentCount / totalStudents) * 100.0;
  }

  String get formattedDate {
    return '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String get formattedSubmittedSessionsDate {
    return '${_submittedSessionsDate.year.toString().padLeft(4, '0')}-'
        '${_submittedSessionsDate.month.toString().padLeft(2, '0')}-'
        '${_submittedSessionsDate.day.toString().padLeft(2, '0')}';
  }

  void setAdminTab(int index) {
    _adminTabIndex = index;
    if (index == 1) {
      loadSubmittedSessions();
    }
    notifyListeners();
  }

  void setSubmittedSessionsDate(DateTime date) {
    _submittedSessionsDate = date;
    loadSubmittedSessions();
  }

  Future<void> loadSubmittedSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allAttendance = await _attendanceRepository.getAllAttendance();
      final allClasses = await _classRepository.getClasses();
      final allTeachers = await _teacherRepository.getTeachers();

      final classMap = {for (var c in allClasses) c.classId: c.className};
      final teacherMap = {for (var t in allTeachers) t.teacherId: t.name};

      // Filter by selected date
      final filterDateStr = formattedSubmittedSessionsDate;
      final filteredAttendance = allAttendance.where((a) => a.date == filterDateStr).toList();

      // Group by classId_date
      Map<String, List<AttendanceModel>> group = {};
      for (var att in filteredAttendance) {
        final key = '${att.classId}_${att.date}';
        group.putIfAbsent(key, () => []).add(att);
      }

      List<Map<String, dynamic>> sessions = [];
      group.forEach((key, attList) {
        final classId = attList.first.classId;
        final date = attList.first.date;
        final teacherUid = attList.first.markedBy;
        final className = classMap[classId] ?? 'Class $classId';
        final teacherName = attList.first.markedByName.isNotEmpty
            ? attList.first.markedByName
            : (teacherMap[teacherUid] ?? 'Teacher');

        int present = attList.where((a) => a.status.toLowerCase() == 'present').length;
        int absent = attList.where((a) => a.status.toLowerCase() == 'absent').length;
        int total = present + absent;
        double pct = total > 0 ? (present / total) * 100 : 0.0;
        int adminChangesCount = attList.where((a) => a.isAdminChanged).length;

        sessions.add({
          'key': key,
          'classId': classId,
          'className': className,
          'date': date,
          'teacherUid': teacherUid,
          'teacherName': teacherName,
          'present': present,
          'absent': absent,
          'total': total,
          'percentage': pct,
          'adminChangesCount': adminChangesCount,
          'records': attList,
        });
      });

      _submittedSessions = sessions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessionAudits(String classId, String date) async {
    try {
      _sessionAudits = await _attendanceRepository.getAuditsForClassAndDate(classId, date);
      notifyListeners();
    } catch (_) {
      _sessionAudits = [];
      notifyListeners();
    }
  }

  Future<bool> changeStudentAttendanceByAdmin({
    required AttendanceModel attendance,
    required String newStatus,
    required String reason,
    required StudentModel student,
    required String className,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Admin session not found.';
      notifyListeners();
      return false;
    }

    final oldStatus = attendance.status;
    if (oldStatus.toLowerCase() == newStatus.toLowerCase()) {
      _errorMessage = 'No attendance change was made.';
      notifyListeners();
      return false;
    }

    try {
      // Resolve student's real name from _studentRepository if student.name is dummy/missing
      String studentRealName = student.name;
      if (studentRealName.isEmpty || studentRealName.startsWith('Student ') || studentRealName == attendance.studentId) {
        final allStudents = await _studentRepository.getStudents();
        final realStudent = allStudents.firstWhere(
          (s) => s.studentId == attendance.studentId,
          orElse: () => student,
        );
        if (realStudent.name.isNotEmpty && !realStudent.name.startsWith('Student ')) {
          studentRealName = realStudent.name;
        } else {
          studentRealName = 'Student (${attendance.studentId})';
        }
      }

      final adminName = (currentUser.displayName != null && currentUser.displayName!.trim().isNotEmpty)
          ? currentUser.displayName!.trim()
          : 'Admin';

      final auditId = '${attendance.classId}_${attendance.studentId}_${attendance.date}_${DateTime.now().millisecondsSinceEpoch}';
      final audit = AttendanceAuditModel(
        auditId: auditId,
        attendanceSessionId: '${attendance.classId}_${attendance.date}',
        classId: attendance.classId,
        date: attendance.date,
        studentId: attendance.studentId,
        oldStatus: oldStatus,
        newStatus: newStatus,
        changedByUid: currentUser.uid,
        changedByRole: 'admin',
        changedByName: adminName,
        reason: reason.trim(),
        teacherUid: attendance.markedBy,
      );

      final updatedAttendance = attendance.copyWith(
        status: newStatus.toLowerCase(),
        isAdminChanged: true,
        adminChangeReason: reason.trim(),
      );

      final notificationId = 'notif_${attendance.classId}_${attendance.date}_${attendance.studentId}_${oldStatus.toLowerCase()}_${newStatus.toLowerCase()}';
      final formattedMsg = '$studentRealName — $className, ${attendance.date}. Attendance changed from ${oldStatus.toUpperCase()} to ${newStatus.toUpperCase()} by $adminName.${reason.trim().isNotEmpty ? " Reason: ${reason.trim()}" : ""}';

      final notification = NotificationModel(
        notificationId: notificationId,
        recipientId: attendance.markedBy,
        recipientRole: 'teacher',
        type: 'attendance_updated',
        title: 'Attendance Updated by Admin',
        message: formattedMsg,
        referenceId: '${attendance.classId}_${attendance.date}',
        referenceType: 'attendance',
        isRead: false,
      );

      await _attendanceRepository.updateAttendanceRecordWithAudit(
        attendance: updatedAttendance,
        audit: audit,
        notification: notification,
      );

      await loadSubmittedSessions();
      _successMessage = 'Attendance updated successfully.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadClasses({bool isTeacherRole = false, String? teacherUid}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allClasses = await _classRepository.getClasses();
      if (isTeacherRole && teacherUid != null) {
        final teachers = await _teacherRepository.getTeachers();
        final teacher = teachers.firstWhere(
          (t) => t.userId == teacherUid || t.teacherId == teacherUid,
          orElse: () => teachers.first,
        );
        _classes = allClasses
            .where((c) => teacher.classIds.contains(c.classId))
            .toList();
      } else {
        _classes = allClasses;
      }

      if (_classes.isNotEmpty && _selectedClass == null) {
        _selectedClass = _classes.first;
        await loadStudentsAndAttendance();
      } else if (_classes.isEmpty) {
        _students = [];
        _attendanceMap.clear();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectClass(ClassModel classModel) async {
    if (_selectedClass?.classId == classModel.classId) return;
    _selectedClass = classModel;
    await loadStudentsAndAttendance();
  }

  Future<void> selectDate(DateTime date, BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = DateTime(date.year, date.month, date.day);

    if (chosen.isAfter(today)) {
      _errorMessage = 'Attendance cannot be marked for a future date.';
      notifyListeners();
      return;
    }

    _selectedDate = date;
    await loadStudentsAndAttendance();
  }

  Future<void> loadStudentsAndAttendance() async {
    if (_selectedClass == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allStudents = await _studentRepository.getStudents();
      _students = allStudents
          .where((s) => s.classId == _selectedClass!.classId && s.status.toLowerCase() == 'active')
          .toList();

      _attendanceMap.clear();

      final sessionExists = await _attendanceRepository.checkAttendanceSessionExists(
        _selectedClass!.classId,
        formattedDate,
      );
      final existingAttendance = await _attendanceRepository
          .getAttendanceForClassAndDate(_selectedClass!.classId, formattedDate);

      if (sessionExists || existingAttendance.isNotEmpty) {
        _isExistingSessionSubmitted = true;
        if (existingAttendance.isNotEmpty) {
          final first = existingAttendance.first;
          _existingSubmitterName = first.markedByName.isNotEmpty ? first.markedByName : 'a teacher/admin';
          _existingSubmitterRole = first.markedByRole;
          _existingSubmitterUid = first.markedBy;
          _existingTeacherEditUsed = first.teacherEditUsed;

          for (var att in existingAttendance) {
            _attendanceMap[att.studentId] = att.status.toLowerCase();
          }
        }
      } else {
        _isExistingSessionSubmitted = false;
        _existingSubmitterName = '';
        _existingSubmitterRole = '';
        _existingSubmitterUid = '';
        _existingTeacherEditUsed = false;

        for (var student in _students) {
          _attendanceMap[student.studentId] = 'present';
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatus(String studentId, String status) {
    _attendanceMap[studentId] = status.toLowerCase();
    notifyListeners();
  }

  void markAllPresent() {
    for (var student in _students) {
      _attendanceMap[student.studentId] = 'present';
    }
    notifyListeners();
  }

  void markAllAbsent() {
    for (var student in _students) {
      _attendanceMap[student.studentId] = 'absent';
    }
    notifyListeners();
  }

  Future<bool> saveAttendance(String currentUserId, {String currentUserName = 'User', String userRole = 'teacher', bool isTeacherOneTimeEdit = false}) async {
    if (_selectedClass == null) {
      _errorMessage = 'No class selected.';
      notifyListeners();
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (chosen.isAfter(today)) {
      _errorMessage = 'Attendance cannot be marked for a future date.';
      notifyListeners();
      return false;
    }

    if (_students.isEmpty) {
      _errorMessage = 'No students found in this class.';
      notifyListeners();
      return false;
    }

    for (var student in _students) {
      if (!_attendanceMap.containsKey(student.studentId)) {
        _errorMessage = 'Please mark attendance for all students.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final List<AttendanceModel> batchList = [];
      for (var student in _students) {
        final status = _attendanceMap[student.studentId] ?? 'present';
        final attendanceId = AttendanceModel.generateId(
          _selectedClass!.classId,
          student.studentId,
          formattedDate,
        );

        batchList.add(AttendanceModel(
          attendanceId: attendanceId,
          studentId: student.studentId,
          classId: _selectedClass!.classId,
          date: formattedDate,
          status: status,
          originalStatus: status,
          markedBy: currentUserId,
          markedByRole: userRole,
          markedByName: currentUserName,
        ));
      }

      final sessionData = {
        'sessionId': '${_selectedClass!.classId}_$formattedDate',
        'classId': _selectedClass!.classId,
        'className': _selectedClass!.className,
        'date': formattedDate,
        'submittedBy': currentUserId,
        'submittedByRole': userRole,
        'submittedByName': currentUserName,
      };

      await _attendanceRepository.saveAttendanceBatch(batchList, sessionData: sessionData);

      if (userRole == 'teacher') {
        final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
        final notification = NotificationModel(
          notificationId: notificationId,
          recipientId: 'admin',
          recipientRole: 'admin',
          type: 'attendance_submitted',
          title: 'Attendance Submitted',
          message: 'Teacher $currentUserName submitted attendance for Class ${_selectedClass!.className} on $formattedDate ($presentCount Present, $absentCount Absent).',
          referenceId: '${_selectedClass!.classId}_$formattedDate',
          referenceType: 'attendance',
          isRead: false,
        );
        await _notificationRepository.createNotification(notification);
      }

      await loadStudentsAndAttendance();

      _successMessage = 'Attendance saved successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
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

class StudentAttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;

  StudentAttendanceViewModel({
    AttendanceRepository? attendanceRepository,
  }) : _attendanceRepository = attendanceRepository ?? AttendanceRepository();

  List<AttendanceModel> _attendanceHistory = [];
  List<AttendanceModel> get attendanceHistory => List.unmodifiable(_attendanceHistory);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get totalClasses => _attendanceHistory.length;

  int get presentCount =>
      _attendanceHistory.where((a) => a.status.toLowerCase() == 'present').length;

  int get absentCount =>
      _attendanceHistory.where((a) => a.status.toLowerCase() == 'absent').length;

  double get attendancePercentage {
    if (totalClasses == 0) return 0.0;
    return (presentCount / totalClasses) * 100.0;
  }

  Future<void> loadStudentAttendance(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _attendanceHistory = await _attendanceRepository.getAttendanceForStudent(studentId);
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
