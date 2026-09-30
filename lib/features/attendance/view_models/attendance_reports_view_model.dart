import 'package:flutter/material.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';

class ClassReportItem {
  final ClassModel classModel;
  final int totalStudents;
  final int presentCount;
  final int absentCount;

  ClassReportItem({
    required this.classModel,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
  });

  double get attendancePercentage {
    final total = presentCount + absentCount;
    if (total == 0) return 0.0;
    return (presentCount / total) * 100.0;
  }
}

class StudentReportItem {
  final StudentModel student;
  final ClassModel? classModel;
  final int presentDays;
  final int absentDays;

  StudentReportItem({
    required this.student,
    this.classModel,
    required this.presentDays,
    required this.absentDays,
  });

  int get totalMarkedDays => presentDays + absentDays;

  double get attendancePercentage {
    if (totalMarkedDays == 0) return 0.0;
    return (presentDays / totalMarkedDays) * 100.0;
  }
}

class AttendanceReportsViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository;
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;

  AttendanceReportsViewModel({
    AttendanceRepository? attendanceRepository,
    StudentRepository? studentRepository,
    ClassRepository? classRepository,
    ClassModel? initialClass,
  })  : _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _classRepository = classRepository ?? ClassRepository() {
    _selectedClass = initialClass;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  ClassModel? _selectedClass; // null means All Classes
  ClassModel? get selectedClass => _selectedClass;

  bool _isMonthly = false;
  bool get isMonthly => _isMonthly;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime get selectedMonth => _selectedMonth;

  List<AttendanceModel> _allAttendance = [];
  List<StudentModel> _allStudents = [];

  int _totalStudentsSummary = 0;
  int get totalStudentsSummary => _totalStudentsSummary;

  int _presentSummary = 0;
  int get presentSummary => _presentSummary;

  int _absentSummary = 0;
  int get absentSummary => _absentSummary;

  double get overallAttendancePercentage {
    final total = _presentSummary + _absentSummary;
    if (total == 0) return 0.0;
    return (_presentSummary / total) * 100.0;
  }

  List<ClassReportItem> _classReports = [];
  List<ClassReportItem> get classReports => List.unmodifiable(_classReports);

  List<StudentReportItem> _studentReports = [];
  List<StudentReportItem> get studentReports => List.unmodifiable(_studentReports);

  String get dateQueryString {
    return '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String get monthQueryPrefix {
    return '${_selectedMonth.year.toString().padLeft(4, '0')}-'
        '${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  Future<void> loadReportData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawClasses = await _classRepository.getClasses();
      final uniqueMap = <String, ClassModel>{};
      for (var c in rawClasses) {
        uniqueMap[c.classId] = c;
      }
      _classes = uniqueMap.values.toList();
      _classes.sort((a, b) => a.className.compareTo(b.className));

      if (_selectedClass != null) {
        _selectedClass = uniqueMap[_selectedClass!.classId] ?? _selectedClass;
      }

      _allStudents = await _studentRepository.getStudents();
      _allAttendance = await _attendanceRepository.getAllAttendance();

      _computeReports();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load attendance reports. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMode(bool isMonthly) {
    _isMonthly = isMonthly;
    _computeReports();
    notifyListeners();
  }

  void selectClass(ClassModel? classModel) {
    _selectedClass = classModel;
    _computeReports();
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _computeReports();
    notifyListeners();
  }

  void selectMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    _computeReports();
    notifyListeners();
  }

  void _computeReports() {
    var filteredStudents = _allStudents.where((s) => s.status.toLowerCase() == 'active');
    if (_selectedClass != null) {
      filteredStudents = filteredStudents.where((s) => s.classId == _selectedClass!.classId);
    }
    final studentIds = filteredStudents.map((s) => s.studentId).toSet();

    List<AttendanceModel> relevantAttendance = [];
    if (_isMonthly) {
      relevantAttendance = _allAttendance
          .where((a) => a.date.startsWith(monthQueryPrefix) && studentIds.contains(a.studentId))
          .toList();
    } else {
      relevantAttendance = _allAttendance
          .where((a) => a.date == dateQueryString && studentIds.contains(a.studentId))
          .toList();
    }

    _totalStudentsSummary = filteredStudents.length;
    _presentSummary = relevantAttendance.where((a) => a.status == 'present').length;
    _absentSummary = relevantAttendance.where((a) => a.status == 'absent').length;

    // Class-wise reports
    final classMap = {for (var c in _classes) c.classId: c};
    final classStudentMap = <String, List<StudentModel>>{};
    for (var s in _allStudents.where((s) => s.status.toLowerCase() == 'active')) {
      if (s.classId != null) {
        classStudentMap.putIfAbsent(s.classId!, () => []).add(s);
      }
    }

    _classReports = [];
    classStudentMap.forEach((classId, studentsInClass) {
      if (_selectedClass == null || _selectedClass!.classId == classId) {
        final cModel = classMap[classId];
        if (cModel != null) {
          final sIds = studentsInClass.map((s) => s.studentId).toSet();
          final attForClass = relevantAttendance.where((a) => sIds.contains(a.studentId));
          final pCount = attForClass.where((a) => a.status == 'present').length;
          final aCount = attForClass.where((a) => a.status == 'absent').length;

          _classReports.add(ClassReportItem(
            classModel: cModel,
            totalStudents: studentsInClass.length,
            presentCount: pCount,
            absentCount: aCount,
          ));
        }
      }
    });

    // Student-wise reports
    final studentAttendanceMap = <String, Map<String, int>>{};
    for (var a in relevantAttendance) {
      studentAttendanceMap.putIfAbsent(a.studentId, () => {'present': 0, 'absent': 0});
      if (a.status == 'present') {
        studentAttendanceMap[a.studentId]!['present'] = (studentAttendanceMap[a.studentId]!['present'] ?? 0) + 1;
      } else if (a.status == 'absent') {
        studentAttendanceMap[a.studentId]!['absent'] = (studentAttendanceMap[a.studentId]!['absent'] ?? 0) + 1;
      }
    }

    _studentReports = filteredStudents.map((student) {
      final counts = studentAttendanceMap[student.studentId] ?? {'present': 0, 'absent': 0};
      return StudentReportItem(
        student: student,
        classModel: student.classId != null ? classMap[student.classId] : null,
        presentDays: counts['present'] ?? 0,
        absentDays: counts['absent'] ?? 0,
      );
    }).toList();

    _studentReports.sort((a, b) => a.student.name.compareTo(b.student.name));
  }
}
