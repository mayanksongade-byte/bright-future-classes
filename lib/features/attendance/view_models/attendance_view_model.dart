import 'package:flutter/material.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
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
