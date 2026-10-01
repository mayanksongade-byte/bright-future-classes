import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/mark_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/test_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/test_repository.dart';

class TestItem {
  final TestModel test;
  final ClassModel? classModel;
  final List<MarkModel> marks;
  final List<StudentModel> studentsInClass;

  TestItem({
    required this.test,
    this.classModel,
    required this.marks,
    required this.studentsInClass,
  });

  int get totalStudents => studentsInClass.length;

  int get marksEnteredCount {
    return marks.where((m) => m.marks != null || m.isAbsent).length;
  }

  String get status {
    if (totalStudents == 0) return 'Marks Not Entered';
    if (marksEnteredCount == 0) return 'Marks Not Entered';
    if (marksEnteredCount < totalStudents) return 'Partially Entered';
    return 'Completed';
  }
}

class TestResultRow {
  final StudentModel student;
  final MarkModel? mark;
  final double totalMarks;
  final double? passingMarks;

  TestResultRow({
    required this.student,
    this.mark,
    required this.totalMarks,
    this.passingMarks,
  });

  bool get isAbsent => mark?.isAbsent ?? false;
  double? get marksValue => mark?.marks;

  String get marksDisplay {
    if (isAbsent) return 'Absent';
    if (marksValue == null) return '--';
    return '${marksValue!.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '')}/${totalMarks.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '')}';
  }

  double get percentage {
    if (isAbsent || marksValue == null || totalMarks <= 0) return 0.0;
    return (marksValue! / totalMarks) * 100.0;
  }

  String get percentageDisplay {
    if (isAbsent || marksValue == null) return '--';
    return '${percentage.toStringAsFixed(1)}%';
  }

  String get result {
    if (isAbsent) return 'Absent';
    if (marksValue == null) return 'Pending';
    if (passingMarks != null) {
      return marksValue! >= passingMarks! ? 'Pass' : 'Fail';
    }
    return 'Pass';
  }
}

class TestsViewModel extends ChangeNotifier {
  final TestRepository _testRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;

  TestsViewModel({
    TestRepository? testRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
  })  : _testRepository = testRepository ?? TestRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository();

  List<TestItem> _testItems = [];
  List<TestItem> get testItems {
    var list = _testItems;
    if (_classFilter != null && _classFilter!.isNotEmpty) {
      list = list.where((item) => item.test.classId == _classFilter).toList();
    }
    if (_subjectFilter != null && _subjectFilter!.trim().isNotEmpty) {
      final q = _subjectFilter!.trim().toLowerCase();
      list = list.where((item) => item.test.subject.toLowerCase().contains(q)).toList();
    }
    if (_nameFilter != null && _nameFilter!.trim().isNotEmpty) {
      final q = _nameFilter!.trim().toLowerCase();
      list = list.where((item) => item.test.testName.toLowerCase().contains(q)).toList();
    }
    if (_dateFilter != null && _dateFilter!.isNotEmpty) {
      list = list.where((item) => item.test.testDate == _dateFilter).toList();
    }
    return list;
  }

  List<ClassModel> _classes = [];
  List<ClassModel> get classes => List.unmodifiable(_classes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _classFilter;
  String? get classFilter => _classFilter;

  String? _subjectFilter;
  String? get subjectFilter => _subjectFilter;

  String? _nameFilter;
  String? get nameFilter => _nameFilter;

  String? _dateFilter;
  String? get dateFilter => _dateFilter;

  void setClassFilter(String? classId) {
    _classFilter = classId;
    notifyListeners();
  }

  void setSubjectFilter(String? subject) {
    _subjectFilter = subject;
    notifyListeners();
  }

  void setNameFilter(String? name) {
    _nameFilter = name;
    notifyListeners();
  }

  void setDateFilter(String? date) {
    _dateFilter = date;
    notifyListeners();
  }

  void clearFilters() {
    _classFilter = null;
    _subjectFilter = null;
    _nameFilter = null;
    _dateFilter = null;
    notifyListeners();
  }

  Future<void> fetchTestsData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _classes = await _classRepository.getClasses();
      final classMap = {for (var c in _classes) c.classId: c};

      final allStudents = await _studentRepository.getStudents();
      final activeStudents = allStudents
          .where((s) => s.status.toLowerCase() == 'active')
          .toList();
      final classStudentMap = <String, List<StudentModel>>{};
      for (var s in activeStudents) {
        if (s.classId != null) {
          classStudentMap.putIfAbsent(s.classId!, () => []).add(s);
        }
      }

      final tests = await _testRepository.getAllTests();
      final testItemsList = <TestItem>[];

      for (var test in tests) {
        final marks = await _testRepository.getMarksForTest(test.testId);
        final studentsInClass = classStudentMap[test.classId] ?? [];
        testItemsList.add(TestItem(
          test: test,
          classModel: classMap[test.classId],
          marks: marks,
          studentsInClass: studentsInClass,
        ));
      }

      _testItems = testItemsList;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load tests. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTest({
    required String testName,
    required String classId,
    required String subject,
    required String testDate,
    required double totalMarks,
    double? passingMarks,
    required String description,
    required String createdBy,
  }) async {
    final cleanName = testName.trim();
    final cleanSubject = subject.trim();
    final cleanDesc = description.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Test name cannot be empty.';
      notifyListeners();
      return false;
    }
    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanSubject.isEmpty) {
      _errorMessage = 'Subject cannot be empty.';
      notifyListeners();
      return false;
    }
    if (testDate.isEmpty) {
      _errorMessage = 'Test date is required.';
      notifyListeners();
      return false;
    }
    if (totalMarks <= 0) {
      _errorMessage = 'Total marks must be greater than 0.';
      notifyListeners();
      return false;
    }
    if (passingMarks != null) {
      if (passingMarks < 0) {
        _errorMessage = 'Passing marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (passingMarks > totalMarks) {
        _errorMessage = 'Passing marks cannot be greater than total marks.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final testId = _testRepository.generateTestId();
      final test = TestModel(
        testId: testId,
        testName: cleanName,
        classId: classId,
        subject: cleanSubject,
        testDate: testDate,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: cleanDesc,
        createdBy: createdBy,
      );

      await _testRepository.saveTest(test);
      _successMessage = 'Test created successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTest({
    required String testId,
    required String testName,
    required String classId,
    required String subject,
    required String testDate,
    required double totalMarks,
    double? passingMarks,
    required String description,
  }) async {
    final cleanName = testName.trim();
    final cleanSubject = subject.trim();
    final cleanDesc = description.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Test name cannot be empty.';
      notifyListeners();
      return false;
    }
    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanSubject.isEmpty) {
      _errorMessage = 'Subject cannot be empty.';
      notifyListeners();
      return false;
    }
    if (testDate.isEmpty) {
      _errorMessage = 'Test date is required.';
      notifyListeners();
      return false;
    }
    if (totalMarks <= 0) {
      _errorMessage = 'Total marks must be greater than 0.';
      notifyListeners();
      return false;
    }
    if (passingMarks != null) {
      if (passingMarks < 0) {
        _errorMessage = 'Passing marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (passingMarks > totalMarks) {
        _errorMessage = 'Passing marks cannot be greater than total marks.';
        notifyListeners();
        return false;
      }
    }

    // Check if totalMarks is reduced below any already-entered student marks
    final existingMarks = await _testRepository.getMarksForTest(testId);
    for (var m in existingMarks) {
      if (!m.isAbsent && m.marks != null && m.marks! > totalMarks) {
        _errorMessage =
            'Total marks cannot be reduced below already entered student marks (${m.marks}).';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existingTest = await _testRepository.getTest(testId);
      if (existingTest == null) {
        _errorMessage = 'Test not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updated = existingTest.copyWith(
        testName: cleanName,
        classId: classId,
        subject: cleanSubject,
        testDate: testDate,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: cleanDesc,
      );

      await _testRepository.updateTest(updated);
      _successMessage = 'Test updated successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTest(String testId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _testRepository.deleteTest(testId);
      _successMessage = 'Test deleted successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete test. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveStudentMarks({
    required TestModel test,
    required Map<String, String> marksInputMap, // studentId -> text
    required Map<String, bool> absentMap, // studentId -> bool
  }) async {
    // Validate marks inputs
    for (var entry in marksInputMap.entries) {
      final studentId = entry.key;
      final isAbs = absentMap[studentId] ?? false;
      if (isAbs) continue;

      final valStr = entry.value.trim();
      if (valStr.isEmpty) continue;

      final parsed = double.tryParse(valStr);
      if (parsed == null) {
        _errorMessage = 'Please enter valid numeric marks.';
        notifyListeners();
        return false;
      }
      if (parsed < 0) {
        _errorMessage = 'Marks cannot be negative.';
        notifyListeners();
        return false;
      }
      if (parsed > test.totalMarks) {
        _errorMessage =
            'Marks cannot exceed total marks (${test.totalMarks.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '')}).';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final List<MarkModel> batch = [];
      for (var entry in marksInputMap.entries) {
        final studentId = entry.key;
        final isAbs = absentMap[studentId] ?? false;
        final valStr = entry.value.trim();

        double? mVal;
        if (!isAbs && valStr.isNotEmpty) {
          mVal = double.tryParse(valStr);
        }

        // Only save if either marks entered or absent is true, or if we want to update
        if (isAbs || mVal != null) {
          final markId = MarkModel.generateId(test.testId, studentId);
          batch.add(MarkModel(
            markId: markId,
            testId: test.testId,
            studentId: studentId,
            classId: test.classId,
            marks: isAbs ? null : mVal,
            isAbsent: isAbs,
          ));
        }
      }

      if (batch.isNotEmpty) {
        await _testRepository.saveMarksBatch(batch);
      }

      _successMessage = 'Marks saved successfully.';
      _isSaving = false;
      await fetchTestsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to save marks. Please try again.';
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
