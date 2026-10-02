import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/student_repository.dart';

class ComplaintsViewModel extends ChangeNotifier {
  final ComplaintRepository _complaintRepository;
  final ClassRepository _classRepository;
  final StudentRepository _studentRepository;

  ComplaintsViewModel({
    ComplaintRepository? complaintRepository,
    ClassRepository? classRepository,
    StudentRepository? studentRepository,
  })  : _complaintRepository = complaintRepository ?? ComplaintRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _studentRepository = studentRepository ?? StudentRepository();

  List<ComplaintModel> _complaints = [];
  List<ClassModel> _classes = [];
  List<StudentModel> _students = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedTypeFilter = 'All';
  String get selectedTypeFilter => _selectedTypeFilter;

  String _selectedStatusFilter = 'All';
  String get selectedStatusFilter => _selectedStatusFilter;

  String _selectedPriorityFilter = 'All';
  String get selectedPriorityFilter => _selectedPriorityFilter;

  String? _selectedClassFilter;
  String? get selectedClassFilter => _selectedClassFilter;

  String? _selectedStudentFilter;
  String? get selectedStudentFilter => _selectedStudentFilter;

  List<ClassModel> get classes => List.unmodifiable(_classes);
  List<StudentModel> get students => List.unmodifiable(_students);

  int get totalComplaints => _complaints.length;
  int get openCount => _complaints.where((c) => c.status == 'Open').length;
  int get inReviewCount => _complaints.where((c) => c.status == 'In Review').length;
  int get resolvedCount => _complaints.where((c) => c.status == 'Resolved').length;
  int get closedCount => _complaints.where((c) => c.status == 'Closed').length;

  List<ComplaintModel> get filteredComplaints {
    var list = List<ComplaintModel>.from(_complaints);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      // Support search by complaint title, student name, complaint ID
      final studentMap = {for (var s in _students) s.studentId: s.name.toLowerCase()};
      
      list = list.where((c) {
        final titleMatch = c.title.toLowerCase().contains(q);
        final idMatch = c.complaintId.toLowerCase().contains(q);
        final studentName = studentMap[c.studentId] ?? '';
        final studentMatch = studentName.contains(q);
        return titleMatch || idMatch || studentMatch;
      }).toList();
    }

    if (_selectedTypeFilter != 'All') {
      list = list
          .where((c) => c.type.toLowerCase() == _selectedTypeFilter.toLowerCase())
          .toList();
    }

    if (_selectedStatusFilter != 'All') {
      list = list
          .where((c) => c.status.toLowerCase() == _selectedStatusFilter.toLowerCase())
          .toList();
    }

    if (_selectedPriorityFilter != 'All') {
      list = list
          .where((c) => c.priority.toLowerCase() == _selectedPriorityFilter.toLowerCase())
          .toList();
    }

    if (_selectedClassFilter != null && _selectedClassFilter!.isNotEmpty) {
      list = list.where((c) => c.classId == _selectedClassFilter).toList();
    }

    if (_selectedStudentFilter != null && _selectedStudentFilter!.isNotEmpty) {
      list = list.where((c) => c.studentId == _selectedStudentFilter).toList();
    }

    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _selectedPriorityFilter = priority;
    notifyListeners();
  }

  void setClassFilter(String? classId) {
    _selectedClassFilter = classId;
    // Reset student filter if student no longer belongs to new class
    if (_selectedStudentFilter != null && classId != null) {
      final isValid = _students.any((s) => s.studentId == _selectedStudentFilter && s.classId == classId);
      if (!isValid) {
        _selectedStudentFilter = null;
      }
    } else if (classId == null) {
      _selectedStudentFilter = null;
    }
    notifyListeners();
  }

  void setStudentFilter(String? studentId) {
    _selectedStudentFilter = studentId;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTypeFilter = 'All';
    _selectedStatusFilter = 'All';
    _selectedPriorityFilter = 'All';
    _selectedClassFilter = null;
    _selectedStudentFilter = null;
    notifyListeners();
  }

  Future<void> fetchComplaintsData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _complaintRepository.getComplaints(),
        _classRepository.getClasses(),
        _studentRepository.getStudents(),
      ]);

      _complaints = results[0] as List<ComplaintModel>;
      
      final rawClasses = results[1] as List<ClassModel>;
      final uniqueMap = <String, ClassModel>{};
      for (var c in rawClasses) {
        uniqueMap[c.classId] = c;
      }
      _classes = uniqueMap.values.toList();
      _classes.sort((a, b) => a.className.compareTo(b.className));

      _students = results[2] as List<StudentModel>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load complaints. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ComplaintModel?> getComplaintById(String complaintId) async {
    return await _complaintRepository.getComplaintById(complaintId);
  }

  Future<bool> createComplaint({
    required String studentId,
    required String classId,
    required String type,
    required String title,
    required String description,
    required String priority,
    required String createdBy,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (studentId.isEmpty) {
      _errorMessage = 'Please select a student.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter complaint title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter complaint description.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final complaintId = _complaintRepository.generateComplaintId();
      final complaint = ComplaintModel(
        complaintId: complaintId,
        studentId: studentId,
        classId: classId,
        type: type,
        title: cleanTitle,
        description: cleanDesc,
        priority: priority,
        status: 'Open',
        resolutionNote: '',
        createdBy: createdBy,
        createdByRole: 'admin',
      );

      await _complaintRepository.createComplaint(complaint);
      _successMessage = 'Complaint created successfully.';
      _isSaving = false;
      await fetchComplaintsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to create complaint. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComplaint({
    required String complaintId,
    required String studentId,
    required String classId,
    required String type,
    required String title,
    required String description,
    required String priority,
    required String status,
    String? resolutionNote,
  }) async {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();

    if (classId.isEmpty) {
      _errorMessage = 'Please select a class.';
      notifyListeners();
      return false;
    }
    if (studentId.isEmpty) {
      _errorMessage = 'Please select a student.';
      notifyListeners();
      return false;
    }
    if (cleanTitle.isEmpty) {
      _errorMessage = 'Please enter complaint title.';
      notifyListeners();
      return false;
    }
    if (cleanDesc.isEmpty) {
      _errorMessage = 'Please enter complaint description.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existing = await _complaintRepository.getComplaintById(complaintId);
      if (existing == null) {
        _errorMessage = 'Complaint not found.';
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final updated = existing.copyWith(
        studentId: studentId,
        classId: classId,
        type: type,
        title: cleanTitle,
        description: cleanDesc,
        priority: priority,
        status: status,
        resolutionNote: resolutionNote != null ? resolutionNote.trim() : existing.resolutionNote,
      );

      await _complaintRepository.updateComplaint(updated);
      _successMessage = 'Complaint updated successfully.';
      _isSaving = false;
      await fetchComplaintsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to update complaint. Please try again.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComplaint(String complaintId) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _complaintRepository.deleteComplaint(complaintId);
      _successMessage = 'Complaint deleted successfully.';
      _isSaving = false;
      await fetchComplaintsData();
      return true;
    } catch (e) {
      _errorMessage = 'Unable to delete complaint. Please try again.';
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
