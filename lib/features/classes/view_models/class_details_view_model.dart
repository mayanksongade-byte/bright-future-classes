import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';

class ClassDetailsViewModel extends ChangeNotifier {
  final ClassModel classModel;
  final TeacherRepository _teacherRepository;
  final StudentRepository _studentRepository;
  final AuthService _authService;
  final FirestoreService _firestoreService;

  ClassDetailsViewModel({
    required this.classModel,
    TeacherRepository? teacherRepository,
    StudentRepository? studentRepository,
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _teacherRepository = teacherRepository ?? TeacherRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService();

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
      final currentUser = _authService.currentUser;
      bool isAdmin = true;
      String? currentTeacherId;

      if (currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        final role = (userDoc?['role'] as String? ?? '').toLowerCase();
        final isActive = userDoc?['isActive'] as bool? ?? false;
        isAdmin = role == 'admin' && isActive;
        currentTeacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;
      }

      if (isAdmin) {
        // Admin path: full collection queries allowed by rules
        final allTeachers = await _teacherRepository.getTeachers();
        _assignedTeachers = allTeachers
            .where((t) => t.classIds.contains(classModel.classId))
            .toList();

        final allStudents = await _studentRepository.getStudents();
        _assignedStudents = allStudents
            .where((s) => s.classId == classModel.classId)
            .toList();
      } else {
        // Teacher path: load ALL teachers assigned to this class
        try {
          final teacherDocs =
              await _firestoreService.getTeacherDocumentsByClassId(classModel.classId);
          final teachersList = teacherDocs
              .map((doc) => TeacherModel.fromMap(doc.data(), doc.id))
              .toList();

          // Ensure current logged-in teacher is included if assigned
          if (currentUser != null && currentTeacherId != null) {
            final myTeacherDoc =
                await _firestoreService.getTeacherDocument(currentTeacherId);
            if (myTeacherDoc != null) {
              final myTeacher =
                  TeacherModel.fromMap(myTeacherDoc, currentTeacherId);
              if (myTeacher.classIds.contains(classModel.classId)) {
                if (!teachersList.any((t) => t.teacherId == myTeacher.teacherId)) {
                  teachersList.insert(0, myTeacher);
                }
              }
            }
          }
          _assignedTeachers = teachersList;
        } catch (_) {
          _assignedTeachers = [];
        }

        final studentDocs =
            await _firestoreService.getStudentsDocumentsByClassId(classModel.classId);
        _assignedStudents = studentDocs
            .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
