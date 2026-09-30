import 'package:flutter/material.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/teacher_repository.dart';

class TeachersViewModel extends ChangeNotifier {
  final TeacherRepository _teacherRepository;

  TeachersViewModel({TeacherRepository? teacherRepository})
      : _teacherRepository = teacherRepository ?? TeacherRepository();

  List<TeacherModel> _teachers = [];
  List<TeacherModel> get teachers => List.unmodifiable(_teachers);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  int get totalTeachers => _teachers.length;

  Future<void> fetchTeachers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _teachers = await _teacherRepository.getTeachers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTeacher({
    required String name,
    required String email,
    required String phone,
    required List<String> classIds,
    String status = 'active',
  }) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final teacherId = _teacherRepository.generateTeacherId();
      final teacher = TeacherModel(
        teacherId: teacherId,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        classIds: classIds,
        status: status,
      );

      await _teacherRepository.createTeacher(teacher);

      _successMessage = 'Teacher profile created successfully';
      _isActionLoading = false;
      await fetchTeachers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTeacher({
    required String teacherId,
    required String name,
    required String email,
    required String phone,
    required List<String> classIds,
    required String status,
    DateTime? createdAt,
  }) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedTeacher = TeacherModel(
        teacherId: teacherId,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        classIds: classIds,
        status: status,
        createdAt: createdAt,
      );

      await _teacherRepository.updateTeacher(updatedTeacher);

      _successMessage = 'Teacher profile updated successfully';
      _isActionLoading = false;
      await fetchTeachers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTeacher(String teacherId) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _teacherRepository.deleteTeacher(teacherId);

      _successMessage = 'Teacher deleted successfully';
      _isActionLoading = false;
      await fetchTeachers();
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
