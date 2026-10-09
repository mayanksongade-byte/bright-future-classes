import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/attendance_audit_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;

  AttendanceViewModel({
    AttendanceRepository? attendanceRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
    TeacherRepository? teacherRepository,
  })  : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository();

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  ClassModel? _selectedClass;
  ClassModel? get selectedClass => _selectedClass;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  List<StudentModel> _students = [];
  List<StudentModel> get students => List.unmodifiable(_students);

  // Map of studentId -> 'present' or 'absent'
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

  List<Map<String, dynamic>> _submittedSessions = [];
  List<Map<String, dynamic>> get submittedSessions => List.unmodifiable(_submittedSessions);

  List<AttendanceAuditModel> _sessionAudits = [];
  List<AttendanceAuditModel> get sessionAudits => List.unmodifiable(_sessionAudits);

  int get totalStudents => _students.length;

  int get presentCount =>
      _attendanceMap.values.where((status) => status == 'present').length;

  int get absentCount =>
      _attendanceMap.values.where((status) => status == 'absent').length;

  double get attendancePercentage {
    if (totalStudents == 0) return 0.0;
    return (presentCount / totalStudents) * 100.0;
  }

  String get formattedDate {
    return '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  void setAdminTab(int index) {
    _adminTabIndex = index;
    if (index == 1) {
      loadSubmittedSessions();
    }
    notifyListeners();
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

      // Group by classId_date
      Map<String, List<AttendanceModel>> group = {};
      for (var att in allAttendance) {
        final key = '${att.classId}_${att.date}';
        group.putIfAbsent(key, () => []).add(att);
      }

      List<Map<String, dynamic>> sessions = [];
      group.forEach((key, attList) {
        final classId = attList.first.classId;
        final date = attList.first.date;
        final teacherUid = attList.first.markedBy;
        final className = classMap[classId] ?? 'Class $classId';
        final teacherName = teacherMap[teacherUid] ?? 'Teacher';

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

      sessions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
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
    if (reason.trim().isEmpty) {
      _errorMessage = 'Reason is required to change attendance.';
      notifyListeners();
      return false;
    }

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
        changedByName: currentUser.displayName ?? 'Admin',
        reason: reason.trim(),
        teacherUid: attendance.markedBy,
      );

      final updatedAttendance = attendance.copyWith(
        status: newStatus.toLowerCase(),
        isAdminChanged: true,
        adminChangeReason: reason.trim(),
      );

      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      final notification = NotificationModel(
        notificationId: notificationId,
        recipientId: attendance.markedBy,
        recipientRole: 'teacher',
        type: 'attendance_updated',
        title: 'Attendance Updated by Admin',
        message: 'Admin updated attendance for ${student.name} in Class $className on ${attendance.date}: ${oldStatus.toUpperCase()} → ${newStatus.toUpperCase()}.',
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

      final existingAttendance = await _attendanceRepository
          .getAttendanceForClassAndDate(_selectedClass!.classId, formattedDate);

      for (var att in existingAttendance) {
        _attendanceMap[att.studentId] = att.status;
      }

      for (var student in _students) {
        _attendanceMap.putIfAbsent(student.studentId, () => 'present');
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
    _attendanceMap[studentId] = status;
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

  Future<bool> saveAttendance(String currentUserId) async {
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
        ));
      }

      await _attendanceRepository.saveAttendanceBatch(batchList);

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
      _attendanceHistory.where((a) => a.status == 'present').length;

  int get absentCount =>
      _attendanceHistory.where((a) => a.status == 'absent').length;

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
