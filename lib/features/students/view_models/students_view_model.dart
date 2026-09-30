import 'package:flutter/material.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../data/repositories/student_repository.dart';

class StudentsViewModel extends ChangeNotifier {
  final StudentRepository _studentRepository;
  final FeeRepository _feeRepository;

  StudentsViewModel({
    StudentRepository? studentRepository,
    FeeRepository? feeRepository,
  })  : _studentRepository = studentRepository ?? StudentRepository(),
        _feeRepository = feeRepository ?? FeeRepository();

  List<StudentModel> _students = [];
  List<StudentModel> get students => List.unmodifiable(_students);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  int get totalStudents => _students.length;

  Future<void> fetchStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _studentRepository.getStudents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createStudent({
    required String studentId,
    required String name,
    required String phone,
    required String parentName,
    required String parentPhone,
    required double totalFees,
    double discount = 0.0,
    String? classId,
    String status = 'active',
  }) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final student = StudentModel(
        studentId: studentId.trim(),
        name: name.trim(),
        phone: phone.trim(),
        parentName: parentName.trim(),
        parentPhone: parentPhone.trim(),
        classId: (classId != null && classId.trim().isNotEmpty)
            ? classId.trim()
            : null,
        status: status,
      );

      await _studentRepository.createStudent(student);

      final fee = FeeModel(
        feeId: student.studentId,
        studentId: student.studentId,
        classId: student.classId ?? '',
        academicYear: '2026-27',
        totalAmount: totalFees,
        discountAmount: discount,
      );
      await _feeRepository.saveFee(fee);

      _successMessage = 'Student and fee record added successfully';
      _isActionLoading = false;
      await fetchStudents();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _studentRepository.deleteStudent(studentId);

      _successMessage = 'Student deleted successfully';
      _isActionLoading = false;
      await fetchStudents();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
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
