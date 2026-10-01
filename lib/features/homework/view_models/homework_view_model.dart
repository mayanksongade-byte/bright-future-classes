import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/homework_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/homework_repository.dart';

class HomeworkItem {
  final HomeworkModel homework;
  final ClassModel? classModel;

  HomeworkItem({
    required this.homework,
    this.classModel,
  });
}

class HomeworkViewModel extends ChangeNotifier {
  final HomeworkRepository _homeworkRepository;
  final ClassRepository _classRepository;

  HomeworkViewModel({
    HomeworkRepository? homeworkRepository,
    ClassRepository? classRepository,
  })  : _homeworkRepository = homeworkRepository ?? HomeworkRepository(),
        _classRepository = classRepository ?? ClassRepository();

  List<HomeworkItem> _homeworkItems = [];
  List<HomeworkItem> get homeworkItems {
    var list = _homeworkItems;
    if (_selectedClassIdFilter != null && _selectedClassIdFilter!.isNotEmpty) {
      list = list.where((item) => item.homework.classId == _selectedClassIdFilter).toList();
    }
    if (_selectedStatusFilter != 'All') {
      list = list.where((item) => item.homework.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
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

  String? _selectedClassIdFilter;
  String? get selectedClassIdFilter => _selectedClassIdFilter;

  String _selectedStatusFilter = 'All';
  String get selectedStatusFilter => _selectedStatusFilter;

  void setClassFilter(String? classId) {
    _selectedClassIdFilter = classId;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  Future<void> fetchHomeworkData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final classes = await _classRepository.getClasses();
      final classMap = {for (var c in classes) c.classId: c};
      _classes = classes;

      final homeworkList = await _homeworkRepository.getAllHomework();
      _homeworkItems = homeworkList.map((hw) {
        return HomeworkItem(
          homework: hw,
          classModel: classMap[hw.classId],
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load homework. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createHomework({
    required String classId,
    required String title,
    required String description,
    required String assignedDate,
    required String dueDate,
    required String createdBy,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter a homework title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter a description.';
      notifyListeners();
      return false;
    }

    final assigned = DateTime.tryParse(assignedDate);
    final due = DateTime.tryParse(dueDate);
    if (assigned != null && due != null) {
      if (due.isBefore(DateTime(assigned.year, assigned.month, assigned.day))) {
        _errorMessage = 'Due date cannot be earlier than assigned date.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final homeworkId = _homeworkRepository.generateHomeworkId();
      final homework = HomeworkModel(
        homeworkId: homeworkId,
        classId: classId,
        title: cleanTitle,
        description: cleanDesc,
        assignedDate: assignedDate,
        dueDate: dueDate,
        status: 'active',
        createdBy: createdBy,
      );

      await _homeworkRepository.saveHomework(homework);
      _successMessage = 'Homework created successfully.';
      _isSaving = false;
      await fetchHomeworkData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create homework. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHomework({
    required String homeworkId,
    required String classId,
    required String title,
    required String description,
    required String assignedDate,
    required String dueDate,
    required String status,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter a homework title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter a description.';
      notifyListeners();
      return false;
    }

    final assigned = DateTime.tryParse(assignedDate);
    final due = DateTime.tryParse(dueDate);
    if (assigned != null && due != null) {
      if (due.isBefore(DateTime(assigned.year, assigned.month, assigned.day))) {
        _errorMessage = 'Due date cannot be earlier than assigned date.';
        notifyListeners();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _homeworkRepository.getHomework(homeworkId);
      if (existing == null) {
        _errorMessage = 'Homework not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updated = existing.copyWith(
        classId: classId,
        title: cleanTitle,
        description: cleanDesc,
        assignedDate: assignedDate,
        dueDate: dueDate,
        status: status,
      );

      await _homeworkRepository.updateHomework(updated);
      _successMessage = 'Homework updated successfully.';
      _isSaving = false;
      await fetchHomeworkData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update homework. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHomework(String homeworkId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _homeworkRepository.deleteHomework(homeworkId);
      _successMessage = 'Homework deleted successfully.';
      _isSaving = false;
      await fetchHomeworkData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete homework. Please try again.';
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
