import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';

class TeacherViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  TeacherViewModel({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  TeacherModel? _teacherModel;
  TeacherModel? get teacherModel => _teacherModel;

  List<ClassModel> _assignedClasses = [];
  List<ClassModel> get assignedClasses => List.unmodifiable(_assignedClasses);

  Map<String, int> _classStudentCounts = {};
  Map<String, int> get classStudentCounts =>
      Map.unmodifiable(_classStudentCounts);

  int _totalStudents = 0;
  int get totalStudents => _totalStudents;

  int get assignedClassesCount => _assignedClasses.length;

  String get teacherDisplayName {
    if (_teacherModel != null && _teacherModel!.name.trim().isNotEmpty) {
      return _teacherModel!.name.trim();
    }
    if (_userModel != null && _userModel!.name.trim().isNotEmpty) {
      return _userModel!.name.trim();
    }
    return 'Teacher';
  }

  String? get teacherUserId {
    if (_teacherModel != null &&
        _teacherModel!.userId != null &&
        _teacherModel!.userId!.trim().isNotEmpty) {
      return _teacherModel!.userId!.trim();
    }
    if (_userModel != null && _userModel!.userId.trim().isNotEmpty) {
      return _userModel!.userId.trim();
    }
    return null;
  }

  Future<void> loadTeacherDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentFirebaseUser = _authService.currentUser;
      if (currentFirebaseUser == null) {
        _errorMessage = 'Session expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final uid = currentFirebaseUser.uid;

      // 1. Read users/{uid} to obtain teacherId
      final userDoc = await _firestoreService.getUserDocument(uid);
      _userModel = UserModel.fromMap(uid, userDoc);

      final teacherId = userDoc?['teacherId'] as String? ?? uid;

      // 2. Read exactly teachers/{teacherId}
      final teacherData = await _firestoreService.getTeacherDocument(teacherId);
      if (teacherData != null) {
        _teacherModel = TeacherModel.fromMap(teacherData, teacherId);
      } else {
        // Fallback: try reading teachers/{uid}
        final fallbackData = await _firestoreService.getTeacherDocument(uid);
        if (fallbackData != null) {
          _teacherModel = TeacherModel.fromMap(fallbackData, uid);
        } else {
          _teacherModel = null;
        }
      }

      // 3. Obtain classIds from teacher document
      final List<String> assignedClassIds = _teacherModel?.classIds ?? [];

      if (assignedClassIds.isNotEmpty) {
        // 4. Load only assigned class documents using their exact class IDs
        List<ClassModel> classes = [];
        for (var classId in assignedClassIds) {
          final classData = await _firestoreService.getClassDocument(classId);
          if (classData != null) {
            classes.add(ClassModel.fromMap(classData, classId));
          }
        }
        _assignedClasses = classes;

        // 5. Load students only for each assigned class using targeted queries
        final Map<String, int> counts = {};
        int total = 0;

        for (var cls in _assignedClasses) {
          final studentDocs = await _firestoreService
              .getStudentsDocumentsByClassId(cls.classId);
          final studentsInClass = studentDocs
              .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
              .toList();
          counts[cls.classId] = studentsInClass.length;
          total += studentsInClass.length;
        }

        _classStudentCounts = counts;
        _totalStudents = total;
      } else {
        _assignedClasses = [];
        _classStudentCounts = {};
        _totalStudents = 0;
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
