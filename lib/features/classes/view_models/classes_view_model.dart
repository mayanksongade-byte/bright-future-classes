import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';

class ClassesViewModel extends ChangeNotifier {
  final ClassRepository _classRepository;
  final TeacherRepository _teacherRepository;
  final StudentRepository _studentRepository;

  ClassesViewModel({
    ClassRepository? classRepository,
    TeacherRepository? teacherRepository,
    StudentRepository? studentRepository,
  })  : _classRepository = classRepository ?? ClassRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _studentRepository = studentRepository ?? StudentRepository();

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  List<TeacherModel> _allTeachers = [];
  List<StudentModel> _allStudents = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  int get totalClasses => _classes.length;

  Future<void> fetchClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _classes = await _classRepository.getClasses();
      _allTeachers = await _teacherRepository.getTeachers();
      _allStudents = await _studentRepository.getStudents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TeacherModel> getTeachersForClass(String classId) {
    return _allTeachers.where((t) => t.classIds.contains(classId)).toList();
  }

  List<StudentModel> getStudentsForClass(String classId) {
    return _allStudents.where((s) => s.classId == classId).toList();
  }

  Future<bool> createClass({
    required String className,
    required String standard,
    required String medium,
    required String academicYear,
    String status = 'active',
  }) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final newClass = ClassModel(
        classId: '',
        className: className.trim(),
        standard: standard.trim(),
        medium: medium.trim(),
        academicYear: academicYear.trim(),
        status: status,
      );

      await _classRepository.createClass(newClass);

      _successMessage = 'Class created successfully';
      _isActionLoading = false;
      await fetchClasses();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateClass({
    required String classId,
    required String className,
    required String standard,
    required String medium,
    required String academicYear,
    required String status,
    DateTime? createdAt,
  }) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updatedClass = ClassModel(
        classId: classId,
        className: className.trim(),
        standard: standard.trim(),
        medium: medium.trim(),
        academicYear: academicYear.trim(),
        status: status,
        createdAt: createdAt,
      );

      await _classRepository.updateClass(updatedClass);

      _successMessage = 'Class updated successfully';
      _isActionLoading = false;
      await fetchClasses();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(String classId) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _classRepository.deleteClass(classId);

      _successMessage = 'Class deleted successfully';
      _isActionLoading = false;
      await fetchClasses();
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
