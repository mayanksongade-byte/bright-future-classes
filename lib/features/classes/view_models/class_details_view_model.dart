import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';

class ClassDetailsViewModel extends ChangeNotifier {
  final ClassModel classModel;
  final TeacherRepository _teacherRepository;
  final StudentRepository _studentRepository;

  ClassDetailsViewModel({
    required this.classModel,
    TeacherRepository? teacherRepository,
    StudentRepository? studentRepository,
  })  : _teacherRepository = teacherRepository ?? TeacherRepository(),
        _studentRepository = studentRepository ?? StudentRepository();

  List<TeacherModel> _assignedTeachers = [];
  List<TeacherModel> get assignedTeachers => List.unmodifiable(_assignedTeachers);

  List<StudentModel> _assignedStudents = [];
  List<StudentModel> get assignedStudents => List.unmodifiable(_assignedStudents);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get teacherCount => _assignedTeachers.length;
  int get studentCount => _assignedStudents.length;

  Future<void> loadClassDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allTeachers = await _teacherRepository.getTeachers();
      _assignedTeachers = allTeachers
          .where((t) => t.classIds.contains(classModel.classId))
          .toList();

      final allStudents = await _studentRepository.getStudents();
      _assignedStudents = allStudents
          .where((s) => s.classId == classModel.classId)
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
