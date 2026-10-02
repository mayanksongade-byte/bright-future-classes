import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/homework_model.dart';
import '../../../data/models/mark_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/test_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../data/repositories/homework_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../data/repositories/test_repository.dart';

class ReportsViewModel extends ChangeNotifier {
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;
  final ClassRepository _classRepository;
  final AttendanceRepository _attendanceRepository;
  final FeeRepository _feeRepository;
  final HomeworkRepository _homeworkRepository;
  final TestRepository _testRepository;
  final ComplaintRepository _complaintRepository;

  ReportsViewModel({
    StudentRepository? studentRepository,
    TeacherRepository? teacherRepository,
    ClassRepository? classRepository,
    AttendanceRepository? attendanceRepository,
    FeeRepository? feeRepository,
    HomeworkRepository? homeworkRepository,
    TestRepository? testRepository,
    ComplaintRepository? complaintRepository,
  })  : _studentRepository = studentRepository ?? StudentRepository(),
        _teacherRepository = teacherRepository ?? TeacherRepository(),
        _classRepository = classRepository ?? ClassRepository(),
        _attendanceRepository = attendanceRepository ?? AttendanceRepository(),
        _feeRepository = feeRepository ?? FeeRepository(),
        _homeworkRepository = homeworkRepository ?? HomeworkRepository(),
        _testRepository = testRepository ?? TestRepository(),
        _complaintRepository = complaintRepository ?? ComplaintRepository();

  List<StudentModel> _students = [];
  List<TeacherModel> _teachers = [];
  List<ClassModel> _classes = [];
  List<dynamic> _attendanceList = [];
  List<FeeModel> _fees = [];
  List<dynamic> _payments = [];
  List<HomeworkModel> _homeworkList = [];
  List<TestModel> _tests = [];
  Map<String, List<MarkModel>> _marksMap = {};
  List<ComplaintModel> _complaints = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedSection = 'Overview';
  String get selectedSection => _selectedSection;

  String? _filterClassId;
  String? get filterClassId => _filterClassId;

  String _filterStatus = 'All';
  String get filterStatus => _filterStatus;

  String? _filterStudentId;
  String? get filterStudentId => _filterStudentId;

  String _filterType = 'All';
  String get filterType => _filterType;

  String _filterPriority = 'All';
  String get filterPriority => _filterPriority;

  String _filterFeeStatus = 'All';
  String get filterFeeStatus => _filterFeeStatus;

  String _filterAcademicYear = 'All';
  String get filterAcademicYear => _filterAcademicYear;

  String _filterTestSubject = 'All';
  String get filterTestSubject => _filterTestSubject;

  String? _filterDate;
  String? get filterDate => _filterDate;

  List<ClassModel> get classes => List.unmodifiable(_classes);
  List<StudentModel> get students => List.unmodifiable(_students);

  void setSelectedSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  void setFilterClassId(String? classId) {
    _filterClassId = classId;
    if (_filterStudentId != null && classId != null) {
      final valid = _students.any((s) => s.studentId == _filterStudentId && s.classId == classId);
      if (!valid) _filterStudentId = null;
    } else if (classId == null) {
      _filterStudentId = null;
    }
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterStudentId(String? studentId) {
    _filterStudentId = studentId;
    notifyListeners();
  }

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterPriority(String priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterFeeStatus(String feeStatus) {
    _filterFeeStatus = feeStatus;
    notifyListeners();
  }

  void setFilterAcademicYear(String year) {
    _filterAcademicYear = year;
    notifyListeners();
  }

  void setFilterTestSubject(String subject) {
    _filterTestSubject = subject;
    notifyListeners();
  }

  void setFilterDate(String? date) {
    _filterDate = date;
    notifyListeners();
  }

  void clearFilters() {
    _filterClassId = null;
    _filterStatus = 'All';
    _filterStudentId = null;
    _filterType = 'All';
    _filterPriority = 'All';
    _filterFeeStatus = 'All';
    _filterAcademicYear = 'All';
    _filterTestSubject = 'All';
    _filterDate = null;
    notifyListeners();
  }

  Future<void> fetchReportsData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _studentRepository.getStudents(),
        _teacherRepository.getTeachers(),
        _classRepository.getClasses(),
        _attendanceRepository.getAllAttendance(),
        _feeRepository.getAllFees(),
        _feeRepository.getAllPayments(),
        _homeworkRepository.getAllHomework(),
        _testRepository.getAllTests(),
        _complaintRepository.getComplaints(),
      ]);

      _students = results[0] as List<StudentModel>;
      _teachers = results[1] as List<TeacherModel>;
      
      final rawClasses = results[2] as List<ClassModel>;
      final uniqueMap = <String, ClassModel>{};
      for (var c in rawClasses) {
        uniqueMap[c.classId] = c;
      }
      _classes = uniqueMap.values.toList();
      _classes.sort((a, b) => a.className.compareTo(b.className));

      _attendanceList = results[3] as List<dynamic>;
      _fees = results[4] as List<FeeModel>;
      _payments = results[5] as List<dynamic>;
      _homeworkList = results[6] as List<HomeworkModel>;
      _tests = results[7] as List<TestModel>;
      _complaints = results[8] as List<ComplaintModel>;

      _marksMap = {};
      for (var test in _tests) {
        try {
          final marks = await _testRepository.getMarksForTest(test.testId);
          _marksMap[test.testId] = marks;
        } catch (_) {
          _marksMap[test.testId] = [];
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load report data. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  int get totalStudents => _students.length;
  int get totalTeachers => _teachers.length;
  int get totalClasses => _classes.length;

  String get pendingFeesStr {
    final paymentMap = <String, double>{};
    for (var p in _payments) {
      paymentMap[p.feeId] = (paymentMap[p.feeId] ?? 0) + p.amount;
    }
    double totalPending = 0;
    for (var f in _fees) {
      final paid = paymentMap[f.feeId] ?? 0;
      final pending = (f.finalPayable - paid).clamp(0.0, double.infinity);
      totalPending += pending;
    }
    return '₹${totalPending.toStringAsFixed(0)}';
  }

  double get overallAttendancePercentage {
    if (_attendanceList.isEmpty) return 0.0;
    final present = _attendanceList.where((a) => a.status == 'present').length;
    final absent = _attendanceList.where((a) => a.status == 'absent').length;
    final total = present + absent;
    if (total == 0) return 0.0;
    return (present / total) * 100.0;
  }

  int get totalTests => _tests.length;
  int get openComplaints => _complaints.where((c) => c.status == 'Open').length;
  int get totalHomework => _homeworkList.length;

  int get activeStudentsCount => _students.where((s) => s.status.toLowerCase() == 'active').length;
  int get inactiveStudentsCount => _students.where((s) => s.status.toLowerCase() != 'active').length;

  List<StudentModel> get filteredStudents {
    var list = _students;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((s) => s.classId == _filterClassId).toList();
    }
    if (_filterStatus != 'All') {
      list = list.where((s) => s.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
    }
    return list;
  }

  Map<String, int> get classWiseStudentCount {
    final map = <String, int>{};
    for (var cls in _classes) {
      final count = _students.where((s) => s.classId == cls.classId).length;
      map[cls.className] = count;
    }
    return map;
  }

  int get attendancePresentCount {
    var list = _attendanceList;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((a) => a.classId == _filterClassId).toList();
    }
    if (_filterDate != null && _filterDate!.isNotEmpty) {
      list = list.where((a) => a.date == _filterDate).toList();
    }
    return list.where((a) => a.status == 'present').length;
  }

  int get attendanceAbsentCount {
    var list = _attendanceList;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((a) => a.classId == _filterClassId).toList();
    }
    if (_filterDate != null && _filterDate!.isNotEmpty) {
      list = list.where((a) => a.date == _filterDate).toList();
    }
    return list.where((a) => a.status == 'absent').length;
  }

  double get filteredAttendancePercentage {
    final present = attendancePresentCount;
    final absent = attendanceAbsentCount;
    final total = present + absent;
    if (total == 0) return 0.0;
    return (present / total) * 100.0;
  }

  Map<String, Map<String, int>> get classWiseAttendanceMap {
    final map = <String, Map<String, int>>{};
    for (var cls in _classes) {
      var list = _attendanceList.where((a) => a.classId == cls.classId).toList();
      if (_filterDate != null && _filterDate!.isNotEmpty) {
        list = list.where((a) => a.date == _filterDate).toList();
      }
      final present = list.where((a) => a.status == 'present').length;
      final absent = list.where((a) => a.status == 'absent').length;
      map[cls.className] = {'present': present, 'absent': absent};
    }
    return map;
  }

  double get totalPayable {
    var fees = _fees;
    if (_filterAcademicYear != 'All') {
      fees = fees.where((f) => f.academicYear == _filterAcademicYear).toList();
    }
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      fees = fees.where((f) => f.classId == _filterClassId).toList();
    }
    return fees.fold(0.0, (sum, f) => sum + f.finalPayable);
  }

  double get totalPaid {
    final paymentMap = <String, double>{};
    for (var p in _payments) {
      paymentMap[p.feeId] = (paymentMap[p.feeId] ?? 0) + p.amount;
    }
    var fees = _fees;
    if (_filterAcademicYear != 'All') {
      fees = fees.where((f) => f.academicYear == _filterAcademicYear).toList();
    }
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      fees = fees.where((f) => f.classId == _filterClassId).toList();
    }
    double paidSum = 0;
    for (var f in fees) {
      paidSum += (paymentMap[f.feeId] ?? 0);
    }
    return paidSum;
  }

  double get totalPendingFees {
    return (totalPayable - totalPaid).clamp(0.0, double.infinity);
  }

  List<Map<String, dynamic>> get classWiseFeesReport {
    final paymentMap = <String, double>{};
    for (var p in _payments) {
      paymentMap[p.feeId] = (paymentMap[p.feeId] ?? 0) + p.amount;
    }

    final list = <Map<String, dynamic>>[];
    var classesToProcess = _classes;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      classesToProcess = classesToProcess.where((c) => c.classId == _filterClassId).toList();
    }

    for (var cls in classesToProcess) {
      var classFees = _fees.where((f) => f.classId == cls.classId).toList();
      if (_filterAcademicYear != 'All') {
        classFees = classFees.where((f) => f.academicYear == _filterAcademicYear).toList();
      }

      double payable = 0;
      double paid = 0;
      for (var f in classFees) {
        payable += f.finalPayable;
        paid += (paymentMap[f.feeId] ?? 0);
      }
      final pending = (payable - paid).clamp(0.0, double.infinity);
      final studentCount = _students.where((s) => s.classId == cls.classId).length;

      String status = 'Paid';
      if (payable == 0) {
        status = 'Paid';
      } else if (paid >= payable) {
        status = 'Paid';
      } else if (paid > 0) {
        status = 'Partially Paid';
      } else {
        status = 'Pending';
      }

      if (_filterFeeStatus != 'All' && status.toLowerCase() != _filterFeeStatus.toLowerCase()) {
        continue;
      }

      list.add({
        'className': cls.className,
        'studentCount': studentCount,
        'payable': payable,
        'paid': paid,
        'pending': pending,
        'status': status,
      });
    }
    return list;
  }

  List<TestModel> get filteredTests {
    var list = _tests;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((t) => t.classId == _filterClassId).toList();
    }
    if (_filterTestSubject != 'All') {
      list = list.where((t) => t.subject.toLowerCase() == _filterTestSubject.toLowerCase()).toList();
    }
    if (_filterDate != null && _filterDate!.isNotEmpty) {
      list = list.where((t) => t.testDate == _filterDate).toList();
    }
    return list;
  }

  Map<String, dynamic> get testMarksSummary {
    int totalTestsCount = filteredTests.length;
    int marksEntered = 0;
    int pendingMarks = 0;
    int passed = 0;
    int failed = 0;
    int absentCount = 0;
    double totalMarksSum = 0;
    double totalMaxMarksSum = 0;
    int scoredMarksCount = 0;

    for (var test in filteredTests) {
      final marks = _marksMap[test.testId] ?? [];
      final studentsInClass = _students.where((s) => s.classId == test.classId).toList();
      
      pendingMarks += (studentsInClass.length - marks.length).clamp(0, 999);

      for (var m in marks) {
        marksEntered++;
        if (m.isAbsent) {
          absentCount++;
        } else {
          scoredMarksCount++;
          final mVal = m.marks ?? 0.0;
          totalMarksSum += mVal;
          totalMaxMarksSum += test.totalMarks;
          if (mVal >= (test.passingMarks ?? 0.0)) {
            passed++;
          } else {
            failed++;
          }
        }
      }
    }

    double avgMarks = scoredMarksCount > 0 ? (totalMarksSum / scoredMarksCount) : 0.0;
    double avgPercentage = totalMaxMarksSum > 0 ? (totalMarksSum / totalMaxMarksSum) * 100.0 : 0.0;

    return {
      'totalTests': totalTestsCount,
      'marksEntered': marksEntered,
      'pendingMarks': pendingMarks,
      'passed': passed,
      'failed': failed,
      'absent': absentCount,
      'avgMarks': avgMarks,
      'avgPercentage': avgPercentage,
    };
  }

  List<HomeworkModel> get filteredHomework {
    var list = _homeworkList;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((h) => h.classId == _filterClassId).toList();
    }
    if (_filterStatus != 'All') {
      list = list.where((h) => h.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
    }
    if (_filterDate != null && _filterDate!.isNotEmpty) {
      list = list.where((h) => h.assignedDate == _filterDate).toList();
    }
    return list;
  }

  int get totalHomeworkCount => filteredHomework.length;
  int get activeHomeworkCount => filteredHomework.where((h) => h.status.toLowerCase() == 'active').length;
  int get completedHomeworkCount => filteredHomework.where((h) => h.status.toLowerCase() == 'completed').length;

  List<ComplaintModel> get filteredComplaints {
    var list = _complaints;
    if (_filterClassId != null && _filterClassId!.isNotEmpty) {
      list = list.where((c) => c.classId == _filterClassId).toList();
    }
    if (_filterStudentId != null && _filterStudentId!.isNotEmpty) {
      list = list.where((c) => c.studentId == _filterStudentId).toList();
    }
    if (_filterType != 'All') {
      list = list.where((c) => c.type.toLowerCase() == _filterType.toLowerCase()).toList();
    }
    if (_filterPriority != 'All') {
      list = list.where((c) => c.priority.toLowerCase() == _filterPriority.toLowerCase()).toList();
    }
    if (_filterStatus != 'All') {
      list = list.where((c) => c.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
    }
    return list;
  }

  int get totalComplaintsCount => filteredComplaints.length;
  int get openComplaintsCount => filteredComplaints.where((c) => c.status == 'Open').length;
  int get inReviewComplaintsCount => filteredComplaints.where((c) => c.status == 'In Review').length;
  int get resolvedComplaintsCount => filteredComplaints.where((c) => c.status == 'Resolved').length;
  int get closedComplaintsCount => filteredComplaints.where((c) => c.status == 'Closed').length;
}
