import 'package:flutter/material.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;
  final AttendanceRepository _attendanceRepository;
  final FeeRepository _feeRepository;

  AdminViewModel({
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
    TeacherRepository? teacherRepository,
    AttendanceRepository? attendanceRepository,
    FeeRepository? feeRepository,
  })  : _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _feeRepository = feeRepository ?? FeeRepository();

  int _totalStudents = 0;
  int get totalStudents => _totalStudents;

  int _totalTeachers = 0;
  int get totalTeachers => _totalTeachers;

  int _totalClasses = 0;
  int get totalClasses => _totalClasses;

  String _pendingFeesStr = '₹0';
  String get pendingFees => _pendingFeesStr;

  int _todayPresent = 0;
  int get todayPresent => _todayPresent;

  int _todayAbsent = 0;
  int get todayAbsent => _todayAbsent;

  double get todayAttendancePercentage {
    final total = _todayPresent + _todayAbsent;
    if (total == 0) return 0.0;
    return (_todayPresent / total) * 100.0;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _totalClasses = await _classRepository.getClassCount();
    } catch (_) {
      _totalClasses = 0;
    }

    try {
      _totalStudents = await _studentRepository.getStudentCount();
    } catch (_) {
      _totalStudents = 0;
    }

    try {
      _totalTeachers = await _teacherRepository.getTeacherCount();
    } catch (_) {
      _totalTeachers = 0;
    }

    try {
      final fees = await _feeRepository.getAllFees();
      final payments = await _feeRepository.getAllPayments();
      final paymentMap = <String, double>{};
      for (var p in payments) {
        paymentMap[p.feeId] = (paymentMap[p.feeId] ?? 0) + p.amount;
      }
      double totalPending = 0;
      for (var f in fees) {
        final paid = paymentMap[f.feeId] ?? 0;
        final pending = (f.finalPayable - paid).clamp(0.0, double.infinity);
        totalPending += pending;
      }
      _pendingFeesStr = '₹${totalPending.toStringAsFixed(0)}';
    } catch (_) {
      _pendingFeesStr = '₹0';
    }

    try {
      final now = DateTime.now();
      final todayStr = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final allAttendance = await _attendanceRepository.getAllAttendance();
      final todayAttendance =
          allAttendance.where((a) => a.date == todayStr).toList();
      _todayPresent =
          todayAttendance.where((a) => a.status == 'present').length;
      _todayAbsent = todayAttendance.where((a) => a.status == 'absent').length;
    } catch (_) {
      _todayPresent = 0;
      _todayAbsent = 0;
    }

    _isLoading = false;
    notifyListeners();
  }
}
