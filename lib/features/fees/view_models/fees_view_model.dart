import 'package:flutter/material.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/fee_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../data/repositories/student_repository.dart';

class StudentFeeItem {
  final StudentModel student;
  final ClassModel? classModel;
  final FeeModel fee;
  final List<FeePaymentModel> payments;

  StudentFeeItem({
    required this.student,
    this.classModel,
    required this.fee,
    required this.payments,
  });

  double get totalPaid {
    double sum = 0.0;
    for (var p in payments) {
      sum += p.amount;
    }
    return sum;
  }

  double get pending {
    return (fee.finalPayable - totalPaid).clamp(0.0, double.infinity);
  }

  String get status {
    if (pending == 0) {
      return 'Paid';
    } else if (totalPaid > 0) {
      return 'Partially Paid';
    } else {
      return 'Pending';
    }
  }
}

class ClassFeeSummary {
  final ClassModel? classModel;
  final String classId;
  final String className;
  final List<StudentFeeItem> studentItems;

  ClassFeeSummary({
    this.classModel,
    required this.classId,
    required this.className,
    required this.studentItems,
  });

  int get studentCount => studentItems.length;

  double get totalPayable {
    double sum = 0;
    for (var item in studentItems) {
      sum += item.fee.finalPayable;
    }
    return sum;
  }

  double get totalPaid {
    double sum = 0;
    for (var item in studentItems) {
      sum += item.totalPaid;
    }
    return sum;
  }

  double get totalPending {
    return (totalPayable - totalPaid).clamp(0.0, double.infinity);
  }
}

class FeesViewModel extends ChangeNotifier {
  final FeeRepository _feeRepository;
  final StudentRepository _studentRepository;
  final ClassRepository _classRepository;

  FeesViewModel({
    FeeRepository? feeRepository,
    StudentRepository? studentRepository,
    ClassRepository? classRepository,
  })  : _feeRepository = feeRepository ?? FeeRepository(),
        _studentRepository = studentRepository ?? StudentRepository(),
        _classRepository = classRepository ?? ClassRepository();

  List<StudentFeeItem> _feeItems = [];
  List<StudentFeeItem> get feeItems {
    var list = _feeItems;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        return item.student.name.toLowerCase().contains(q) ||
            item.student.studentId.toLowerCase().contains(q);
      }).toList();
    }
    if (_selectedFilter != 'All') {
      list = list.where((item) {
        return item.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
    return list;
  }

  List<StudentFeeItem> get allFeeItems => _feeItems;

  List<ClassFeeSummary> get classFeeSummaries {
    final map = <String, List<StudentFeeItem>>{};
    for (var item in _feeItems) {
      final cid = item.student.classId ?? 'unassigned';
      map.putIfAbsent(cid, () => []).add(item);
    }

    final summaries = <ClassFeeSummary>[];
    map.forEach((cid, items) {
      if (items.isNotEmpty) {
        final classModel = items.first.classModel;
        final className =
            classModel != null ? classModel.className : 'Unassigned Class';
        summaries.add(ClassFeeSummary(
          classModel: classModel,
          classId: cid,
          className: className,
          studentItems: items,
        ));
      }
    });

    summaries.sort((a, b) => a.className.compareTo(b.className));
    return summaries;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedFilter = 'All';
  String get selectedFilter => _selectedFilter;

  double get totalPayableSum {
    double sum = 0;
    for (var i in _feeItems) {
      sum += i.fee.finalPayable;
    }
    return sum;
  }

  double get totalCollectedSum {
    double sum = 0;
    for (var i in _feeItems) {
      sum += i.totalPaid;
    }
    return sum;
  }

  double get totalPendingSum {
    double sum = 0;
    for (var i in _feeItems) {
      sum += i.pending;
    }
    return sum;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> fetchFeesData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final students = await _studentRepository.getStudents();
      final classes = await _classRepository.getClasses();
      final fees = await _feeRepository.getAllFees();
      final payments = await _feeRepository.getAllPayments();

      final classMap = {for (var c in classes) c.classId: c};
      final feeMap = {for (var f in fees) f.studentId: f};
      final paymentMap = <String, List<FeePaymentModel>>{};
      for (var p in payments) {
        paymentMap.putIfAbsent(p.feeId, () => []).add(p);
      }

      _feeItems = students.map((student) {
        final fee = feeMap[student.studentId] ??
            FeeModel(
              feeId: student.studentId,
              studentId: student.studentId,
              classId: student.classId ?? '',
              academicYear: '2026-27',
              totalAmount: 30000.0,
              discountAmount: 0.0,
            );
        final studentPayments = paymentMap[fee.feeId] ?? [];
        studentPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

        return StudentFeeItem(
          student: student,
          classModel: student.classId != null ? classMap[student.classId] : null,
          fee: fee,
          payments: studentPayments,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateFee({
    required String feeId,
    required double totalAmount,
    required double discountAmount,
    required double alreadyPaid,
  }) async {
    final newFinalPayable =
        (totalAmount - discountAmount).clamp(0.0, double.infinity);
    if (newFinalPayable < alreadyPaid) {
      _errorMessage =
          'Fee amount cannot be reduced below the amount already paid.';
      notifyListeners();
      return false;
    }

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final existingFee = await _feeRepository.getFee(feeId);
      final updatedFee = (existingFee ??
              FeeModel(
                feeId: feeId,
                studentId: feeId,
                classId: '',
                academicYear: '2026-27',
                totalAmount: totalAmount,
                discountAmount: discountAmount,
              ))
          .copyWith(
        totalAmount: totalAmount,
        discountAmount: discountAmount,
      );

      await _feeRepository.saveFee(updatedFee);
      _successMessage = 'Fee updated successfully.';
      _isActionLoading = false;
      await fetchFeesData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPayment({
    required String feeId,
    required String studentId,
    required String classId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    required String note,
    required double currentPending,
  }) async {
    if (amount <= 0) {
      _errorMessage = 'Payment amount must be greater than 0.';
      notifyListeners();
      return false;
    }
    if (amount > currentPending) {
      _errorMessage = 'Payment amount cannot be greater than pending amount.';
      notifyListeners();
      return false;
    }

    final parsedDate = DateTime.tryParse(paymentDate);
    if (parsedDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final chosen = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (chosen.isAfter(today)) {
        _errorMessage = 'Payment date cannot be in the future.';
        notifyListeners();
        return false;
      }
    }

    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final paymentId = _feeRepository.generatePaymentId();
      final payment = FeePaymentModel(
        paymentId: paymentId,
        feeId: feeId,
        studentId: studentId,
        classId: classId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        note: note,
      );

      await _feeRepository.savePayment(payment);
      _successMessage = 'Payment saved successfully.';
      _isActionLoading = false;
      await fetchFeesData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    _isActionLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _feeRepository.deletePayment(paymentId);
      _successMessage = 'Payment deleted successfully.';
      _isActionLoading = false;
      await fetchFeesData();
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
