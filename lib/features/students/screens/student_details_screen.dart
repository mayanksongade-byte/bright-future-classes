import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/mark_model.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/models/test_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../data/repositories/notice_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../data/models/student_academic_result.dart';
import '../../attendance/screens/student_attendance_screen.dart';
import '../../reports/screens/student_academic_report_screen.dart';
import 'academic_results_screen.dart';
import 'add_student_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  late StudentModel _student;

  final StudentRepository _studentRepository = StudentRepository();
  final ClassRepository _classRepository = ClassRepository();
  final TeacherRepository _teacherRepository = TeacherRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final FeeRepository _feeRepository = FeeRepository();
  final TestRepository _testRepository = TestRepository();
  final NoticeRepository _noticeRepository = NoticeRepository();
  final ComplaintRepository _complaintRepository = ComplaintRepository();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isAdmin = true;
  bool _isTeacher = false;
  ClassModel? _assignedClass;
  TeacherModel? _assignedTeacher;
  TeacherModel? _loggedInTeacher;

  int _attendancePresent = 0;
  int _attendanceAbsent = 0;
  double _attendancePercentage = 0.0;

  double _totalFees = 0.0;
  double _paidFees = 0.0;
  double _pendingFees = 0.0;

  List<StudentAcademicResult> _academicResults = [];
  StudentAcademicSummary? _academicSummary;
  String? _academicFetchError;

  List<NoticeModel> _applicableNotices = [];
  List<ComplaintModel> _studentComplaints = [];

  bool _isTeacherAssignedToClass(
    TeacherModel? teacher,
    String? studentClassId, {
    ClassModel? assignedClass,
  }) {
    if (teacher == null) return false;

    final Set<String> targetIdentifiers = {};
    if (studentClassId != null && studentClassId.trim().isNotEmpty) {
      targetIdentifiers.add(studentClassId.trim().toLowerCase());
    }
    if (assignedClass != null) {
      if (assignedClass.classId.trim().isNotEmpty) {
        targetIdentifiers.add(assignedClass.classId.trim().toLowerCase());
      }
      if (assignedClass.className.trim().isNotEmpty) {
        targetIdentifiers.add(assignedClass.className.trim().toLowerCase());
      }
    }

    if (targetIdentifiers.isEmpty) return false;

    for (var cId in teacher.classIds) {
      if (targetIdentifiers.contains(cId.trim().toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _checkRoleAndLoadDetails();
  }

  Future<TeacherModel?> _resolveLoggedInTeacher(
    User user,
    Map<String, dynamic>? userDoc,
  ) async {
    try {
      final customTeacherId = userDoc?['teacherId'] as String? ?? '';
      if (customTeacherId.isNotEmpty) {
        final data = await FirestoreService().getTeacherDocument(
          customTeacherId,
        );
        if (data != null) {
          return TeacherModel.fromMap(data, customTeacherId);
        }
      }
      final directData = await FirestoreService().getTeacherDocument(user.uid);
      if (directData != null) {
        return TeacherModel.fromMap(directData, user.uid);
      }
      if (_isAdmin) {
        final allTeachers = await _teacherRepository.getTeachers();
        for (var t in allTeachers) {
          if (t.userId == user.uid ||
              t.teacherId == user.uid ||
              t.teacherId == customTeacherId) {
            return t;
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[StudentDetailsScreen] Error resolving logged-in teacher: $e',
      );
    }
    return null;
  }

  Future<void> _checkRoleAndLoadDetails() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final userDoc = await FirestoreService().getUserDocument(
          currentUser.uid,
        );
        final role = (userDoc?['role'] as String? ?? '').toLowerCase();
        final isActive = userDoc?['isActive'] as bool? ?? false;
        final isTeacherRole = (role == 'teacher') && isActive;
        final isAdminRole = (role == 'admin') && isActive;

        TeacherModel? teacher;
        if (isTeacherRole) {
          teacher = await _resolveLoggedInTeacher(currentUser, userDoc);
        }

        if (mounted) {
          setState(() {
            _isAdmin = isAdminRole;
            _isTeacher = isTeacherRole;
            _loggedInTeacher = teacher;
          });
        }
      }
    } catch (_) {}
    _loadAllStudentDetails();
  }

  Future<void> _loadAllStudentDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 0. Refresh student doc if possible
      try {
        final freshStudentDoc = await _firestoreService.getStudentDocument(
          _student.studentId,
        );
        if (freshStudentDoc != null) {
          _student = StudentModel.fromMap(freshStudentDoc, _student.studentId);
        }
      } catch (_) {}

      // 1. Resolve Class
      ClassModel? cls;
      try {
        final cleanStudentClassId = _student.classId?.trim() ?? '';
        if (_isAdmin) {
          final classes = await _classRepository.getClasses();
          for (var c in classes) {
            if (cleanStudentClassId.isNotEmpty &&
                (c.classId.trim().toLowerCase() ==
                        cleanStudentClassId.toLowerCase() ||
                    c.className.trim().toLowerCase() ==
                        cleanStudentClassId.toLowerCase())) {
              cls = c;
              break;
            }
          }
        } else {
          // Teacher Class Resolution
          // A. If student has classId, try direct lookup by doc ID
          if (cleanStudentClassId.isNotEmpty) {
            final classData = await _firestoreService.getClassDocument(
              cleanStudentClassId,
            );
            if (classData != null) {
              cls = ClassModel.fromMap(classData, cleanStudentClassId);
            }
          }

          // B. If not found or student.classId was a className, check teacher's assigned classes
          if (cls == null &&
              _loggedInTeacher != null &&
              _loggedInTeacher!.classIds.isNotEmpty) {
            for (var cId in _loggedInTeacher!.classIds) {
              final cData = await _firestoreService.getClassDocument(cId);
              if (cData != null) {
                final cModel = ClassModel.fromMap(cData, cId);
                if (cleanStudentClassId.isNotEmpty &&
                    (cModel.classId.trim().toLowerCase() ==
                            cleanStudentClassId.toLowerCase() ||
                        cModel.className.trim().toLowerCase() ==
                            cleanStudentClassId.toLowerCase())) {
                  cls = cModel;
                  break;
                }
              }
            }
          }

          // C. If still not found (or student.classId was empty), check which of teacher's classes contains this student
          if (cls == null &&
              _loggedInTeacher != null &&
              _loggedInTeacher!.classIds.isNotEmpty) {
            for (var cId in _loggedInTeacher!.classIds) {
              final studentDocs = await _firestoreService
                  .getStudentsDocumentsByClassId(cId);
              final isEnrolled = studentDocs.any(
                (d) =>
                    d.id == _student.studentId ||
                    (d.data()['userId'] != null &&
                        d.data()['userId'] == _student.userId),
              );
              if (isEnrolled) {
                final cData = await _firestoreService.getClassDocument(cId);
                if (cData != null) {
                  cls = ClassModel.fromMap(cData, cId);
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[StudentDetailsScreen] Failed to resolve class: $e');
      }
      _assignedClass = cls;

      // 2. Resolve Teacher assigned to this class
      TeacherModel? teacher;
      try {
        if (_isAdmin) {
          final teachers = await _teacherRepository.getTeachers();
          final classTarget = _assignedClass?.classId ?? _student.classId ?? '';
          if (classTarget.isNotEmpty) {
            for (var t in teachers) {
              if (t.classIds.contains(classTarget)) {
                teacher = t;
                break;
              }
            }
          }
        } else if (_isTeacher && _loggedInTeacher != null) {
          if (_isTeacherAssignedToClass(
            _loggedInTeacher,
            _student.classId,
            assignedClass: _assignedClass,
          )) {
            teacher = _loggedInTeacher;
          }
        }
      } catch (e) {
        debugPrint('[StudentDetailsScreen] Failed to resolve teacher: $e');
      }
      _assignedTeacher = teacher;

      // 3. Resolve Attendance
      try {
        List<AttendanceModel> attendanceList = await _attendanceRepository
            .getAttendanceForStudent(_student.studentId);

        if (_student.userId != null &&
            _student.userId!.isNotEmpty &&
            _student.userId != _student.studentId) {
          final additionalList = await _attendanceRepository
              .getAttendanceForStudent(_student.userId!);
          final Map<String, AttendanceModel> mergedMap = {};
          for (var a in attendanceList) {
            mergedMap[a.attendanceId] = a;
          }
          for (var a in additionalList) {
            mergedMap[a.attendanceId] = a;
          }
          attendanceList = mergedMap.values.toList();
        }

        // Map distinct dates (yyyy-MM-dd) to attendance status
        final Map<String, String> dateStatusMap = {};
        for (var att in attendanceList) {
          final dateKey = att.date.trim();
          if (dateKey.isNotEmpty) {
            dateStatusMap[dateKey] = att.status.toLowerCase();
          }
        }

        int present = 0;
        int absent = 0;
        dateStatusMap.forEach((date, status) {
          if (status == 'present') {
            present++;
          } else if (status == 'absent') {
            absent++;
          }
        });

        if (mounted) {
          setState(() {
            _attendancePresent = present;
            _attendanceAbsent = absent;
            final total = present + absent;
            _attendancePercentage = total > 0 ? (present / total) * 100.0 : 0.0;
          });
        }
      } catch (e) {
        debugPrint(
          '[StudentDetailsScreen] Failed to load student attendance summary: $e',
        );
      }

      // 4. Resolve Fees (Admin Only)
      if (_isAdmin) {
        try {
          final allFees = await _feeRepository.getAllFees();
          final studentFees = allFees
              .where((f) => f.studentId == _student.studentId)
              .toList();
          double total = 0.0;
          for (var f in studentFees) {
            total += f.finalPayable;
          }
          _totalFees = total;

          final allPayments = await _feeRepository.getAllPayments();
          final studentPayments = allPayments
              .where((p) => p.studentId == _student.studentId)
              .toList();
          double paid = 0.0;
          for (var p in studentPayments) {
            paid += p.amount;
          }
          _paidFees = paid;
          _pendingFees = (_totalFees - _paidFees).clamp(0.0, double.infinity);
        } catch (_) {}
      }

      // 5. Resolve Tests & Marks
      _academicFetchError = null;
      try {
        final Set<String> queryClassIdentifiers = {};
        if (_student.classId != null && _student.classId!.trim().isNotEmpty) {
          queryClassIdentifiers.add(_student.classId!.trim());
        }
        if (_assignedClass != null) {
          if (_assignedClass!.classId.trim().isNotEmpty) {
            queryClassIdentifiers.add(_assignedClass!.classId.trim());
          }
          if (_assignedClass!.className.trim().isNotEmpty) {
            queryClassIdentifiers.add(_assignedClass!.className.trim());
          }
        }

        // If teacher, also ensure any teacher classId matching assignedClass or student is added
        if (_isTeacher && _loggedInTeacher != null) {
          for (var cId in _loggedInTeacher!.classIds) {
            if (_isTeacherAssignedToClass(
              _loggedInTeacher,
              cId,
              assignedClass: _assignedClass,
            )) {
              queryClassIdentifiers.add(cId);
            }
          }
        }

        List<TestModel> tests = [];
        if (queryClassIdentifiers.isNotEmpty) {
          if (_isTeacher) {
            if (_loggedInTeacher == null) {
              final currentUser = AuthService().currentUser;
              if (currentUser != null) {
                final userDoc = await FirestoreService().getUserDocument(
                  currentUser.uid,
                );
                _loggedInTeacher = await _resolveLoggedInTeacher(
                  currentUser,
                  userDoc,
                );
              }
            }

            if (_isTeacherAssignedToClass(
              _loggedInTeacher,
              _student.classId,
              assignedClass: _assignedClass,
            )) {
              final Map<String, TestModel> testMap = {};
              for (var classIdKey in queryClassIdentifiers) {
                final classTests = await _testRepository.getTestsForClass(
                  classIdKey,
                );
                for (var t in classTests) {
                  testMap[t.testId] = t;
                }
              }
              tests = testMap.values.toList();
            } else {
              tests = [];
            }
          } else {
            final Map<String, TestModel> testMap = {};
            for (var classIdKey in queryClassIdentifiers) {
              final classTests = await _testRepository.getTestsForClass(
                classIdKey,
              );
              for (var t in classTests) {
                testMap[t.testId] = t;
              }
            }
            tests = testMap.values.toList();
          }
        }

        if (tests.isEmpty && _isAdmin) {
          tests = await _testRepository.getAllTests();
        }

        // For teachers, ensure test classId belongs to teacher's assigned classes
        if (_isTeacher && _loggedInTeacher != null) {
          tests = tests
              .where(
                (t) => _isTeacherAssignedToClass(
                  _loggedInTeacher,
                  t.classId,
                  assignedClass: _assignedClass,
                ),
              )
              .toList();
        }

        if (kDebugMode) {
          debugPrint(
            '[StudentDetailsScreen Debug] StudentDocId: ${_student.studentId}, StudentUserId: ${_student.userId}, ClassId: ${_student.classId}',
          );
          debugPrint(
            '[StudentDetailsScreen Debug] IsAdmin: $_isAdmin, IsTeacher: $_isTeacher, TeacherId: ${_loggedInTeacher?.teacherId}, ClassIds: ${_loggedInTeacher?.classIds}',
          );
          debugPrint(
            '[StudentDetailsScreen Debug] QueryClassIdentifiers: $queryClassIdentifiers, TestsCount: ${tests.length}',
          );
        }

        final Map<String, MarkModel> markByTestId = {};
        for (var test in tests) {
          try {
            final testMarks = await _testRepository.getMarksForTest(
              test.testId,
              classId: test.classId,
            );
            for (var m in testMarks) {
              final matchDocId =
                  m.studentId == _student.studentId ||
                  m.studentId.trim().toLowerCase() ==
                      _student.studentId.trim().toLowerCase();
              final matchUserId =
                  _student.userId != null &&
                  _student.userId!.isNotEmpty &&
                  (m.studentId == _student.userId ||
                      m.studentId.trim().toLowerCase() ==
                          _student.userId!.trim().toLowerCase());
              if (matchDocId || matchUserId) {
                markByTestId[test.testId] = m;
                break;
              }
            }
          } catch (markErr) {
            debugPrint(
              '[StudentDetailsScreen] Error fetching marks for test ${test.testId}: $markErr',
            );
          }
        }

        final List<StudentAcademicResult> parsedResults = [];
        for (var test in tests) {
          final m = markByTestId[test.testId];
          parsedResults.add(
            StudentAcademicResult(
              test: test,
              mark: m,
              classModel: _assignedClass,
            ),
          );
        }

        parsedResults.sort(
          (a, b) => b.test.testDate.compareTo(a.test.testDate),
        );

        _academicResults = parsedResults;
        _academicSummary = StudentAcademicSummary(allResults: parsedResults);

        if (kDebugMode) {
          debugPrint(
            '[StudentDetailsScreen Debug] Final Academic Results Count: ${parsedResults.length}, Completed: ${_academicSummary?.completedCount}',
          );
        }
      } catch (e) {
        debugPrint('[StudentDetailsScreen] ERROR resolving tests & marks: $e');
        _academicFetchError = e.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
      }

      // 6. Resolve Notices (Admin Only)
      if (_isAdmin) {
        try {
          final notices = await _noticeRepository.getNotices();
          _applicableNotices = notices.where((notice) {
            final isAllStudents =
                notice.targetAudience.toLowerCase() == 'all_students';
            final isClassMatch =
                _student.classId != null &&
                _student.classId!.isNotEmpty &&
                notice.classIds.contains(_student.classId);
            return isAllStudents || isClassMatch;
          }).toList();
        } catch (_) {}
      }

      // 7. Resolve Complaints
      try {
        if (_isAdmin) {
          final complaints = await _complaintRepository.getComplaints();
          _studentComplaints = complaints
              .where((c) => c.studentId == _student.studentId)
              .toList();
        } else {
          _studentComplaints = await _complaintRepository
              .getComplaintsForStudent(_student.studentId);
        }
      } catch (_) {}
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditStudent() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(studentToEdit: _student),
      ),
    );

    if (updated == true && mounted) {
      try {
        final students = await _studentRepository.getStudents();
        final refreshed = students.firstWhere(
          (s) => s.studentId == _student.studentId,
          orElse: () => _student,
        );
        setState(() {
          _student = refreshed;
        });
        _loadAllStudentDetails();
      } catch (_) {}
    }
  }

  void _navigateToAcademicResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AcademicResultsScreen(
          student: _student,
          classModel: _assignedClass,
          initialResults: _academicResults,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _student.status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(true),
          tooltip: 'Back',
        ),
        title: const Text(
          'Student Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: false,
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryEmerald,
                  ),
                  onPressed: _navigateToEditStudent,
                  tooltip: 'Edit Student',
                ),
              ]
            : [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER CARD
                        _buildHeaderCard(isActive),
                        const SizedBox(height: 20),

                        // SECTION 1 — PERSONAL INFORMATION
                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildInfoRow('Full Name', _student.name),
                            _buildInfoRow('Student ID', _student.studentId),
                            _buildInfoRow(
                              'Date of Birth',
                              _student.dateOfBirth.isNotEmpty
                                  ? AppDateFormatter.formatDate(
                                      _student.dateOfBirth,
                                    )
                                  : '-',
                            ),
                            _buildInfoRow('Gender', _student.gender),
                            _buildInfoRow(
                              'Status',
                              isActive ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 2 — CONTACT INFORMATION
                        _buildSectionCard(
                          title: 'Contact Information',
                          icon: Icons.phone_outlined,
                          children: [
                            _buildInfoRow(
                              'Student Phone',
                              _student.phone.isNotEmpty ? _student.phone : '-',
                            ),
                            _buildInfoRow(
                              'Address',
                              _student.address.isNotEmpty
                                  ? _student.address
                                  : '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 3 — PARENT / GUARDIAN INFORMATION
                        _buildSectionCard(
                          title: 'Parent / Guardian Information',
                          icon: Icons.family_restroom_outlined,
                          children: [
                            _buildInfoRow(
                              'Parent Name',
                              _student.parentName.isNotEmpty
                                  ? _student.parentName
                                  : '-',
                            ),
                            _buildInfoRow(
                              'Parent Phone',
                              _student.parentPhone.isNotEmpty
                                  ? _student.parentPhone
                                  : '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ADMIN-ONLY SECTIONS
                        if (_isAdmin) ...[
                          // SECTION 4 — ACADEMIC INFORMATION
                          _buildSectionCard(
                            title: 'Academic Information',
                            icon: Icons.school_outlined,
                            children: [
                              _buildInfoRow(
                                'Assigned Class',
                                _assignedClass != null
                                    ? '${_assignedClass!.className} (${_assignedClass!.standard} - ${_assignedClass!.medium})'
                                    : 'Not Assigned',
                              ),
                              if (_assignedClass != null)
                                _buildInfoRow(
                                  'Academic Year',
                                  _assignedClass!.academicYear,
                                ),
                              _buildInfoRow(
                                'Assigned Teacher',
                                _assignedTeacher != null
                                    ? '${_assignedTeacher!.name} (${_assignedTeacher!.phone})'
                                    : 'Not Assigned',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // SECTION 5 — ATTENDANCE SUMMARY
                          _buildSectionCard(
                            title: 'Attendance',
                            icon: Icons.calendar_today_outlined,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Present',
                                      value: '$_attendancePresent Days',
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Absent',
                                      value: '$_attendanceAbsent Days',
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Attendance',
                                      value:
                                          '${_attendancePercentage.toStringAsFixed(1)}%',
                                      color: AppColors.teacherAccent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentAttendanceScreen(
                                              studentId: _student.studentId,
                                            ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.history_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('View Attendance History'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryEmerald,
                                    side: const BorderSide(
                                      color: AppColors.primaryEmerald,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // SECTION 6 — FEES (Strictly hidden for teachers)
                          _buildSectionCard(
                            title: 'Fees',
                            icon: Icons.account_balance_wallet_outlined,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Total Payable',
                                      value:
                                          '₹${_totalFees.toStringAsFixed(0)}',
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Paid Amount',
                                      value: '₹${_paidFees.toStringAsFixed(0)}',
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Pending',
                                      value:
                                          '₹${_pendingFees.toStringAsFixed(0)}',
                                      color: _pendingFees > 0
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // SECTION 7 — TESTS & MARKS (Allowed for teacher)
                        _buildSectionCard(
                          title: 'Tests & Academic Performance',
                          icon: Icons.assignment_outlined,
                          children: [
                            if (_academicFetchError != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Unable to load academic results: $_academicFetchError',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: _loadAllStudentDetails,
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Retry Loading'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_academicSummary == null ||
                                _academicSummary!.totalTests == 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No test records found for this class.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else ...[
                              // 1. SUMMARY METRICS CARDS
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: isWide ? 4 : 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: isWide ? 1.5 : 1.6,
                                    children: [
                                      _buildMetricBox(
                                        label: 'Completed Tests',
                                        value:
                                            '${_academicSummary!.completedCount} / ${_academicSummary!.totalTests}',
                                        color: AppColors.textMain,
                                      ),
                                      _buildMetricBox(
                                        label: 'Weighted Avg',
                                        value:
                                            '${_academicSummary!.overallAveragePercentage.toStringAsFixed(1)}%',
                                        color: AppColors.primaryEmerald,
                                      ),
                                      _buildMetricBox(
                                        label: 'Passed / Failed',
                                        value:
                                            '${_academicSummary!.passCount} Passed · ${_academicSummary!.failCount} Failed',
                                        color: _academicSummary!.failCount == 0
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                      _buildMetricBox(
                                        label: 'Pending Marks',
                                        value:
                                            '${_academicSummary!.pendingCount} Pending',
                                        color:
                                            _academicSummary!.pendingCount > 0
                                                ? AppColors.info
                                                : AppColors.textSecondary,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 18),

                              // 2. SUBJECT-WISE PERFORMANCE SECTION WITH PROGRESS BARS
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Subject-Wise Performance',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  Text(
                                    '${_academicSummary!.subjectSummaries.length} Subjects',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              ..._academicSummary!.subjectSummaries.map((sub) {
                                final double avgPerc =
                                    sub.subjectAveragePercentage;
                                final bool isPassingAvg = avgPerc >= 35.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sub.subjectName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMain,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${avgPerc.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: sub.completedCount > 0
                                                  ? (isPassingAvg
                                                      ? AppColors.darkEmerald
                                                      : AppColors.error)
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Progress Bar
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: sub.completedCount > 0
                                              ? (avgPerc / 100.0).clamp(
                                                  0.0,
                                                  1.0,
                                                )
                                              : 0.0,
                                          backgroundColor: AppColors.border,
                                          color: isPassingAvg
                                              ? AppColors.primaryEmerald
                                              : AppColors.error,
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${sub.completedCount} of ${sub.totalTests} tests evaluated',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            '${sub.passCount} Pass · ${sub.failCount} Fail${sub.pendingCount > 0 ? ' · ${sub.pendingCount} Pending' : ''}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 18),

                              // 3. RECENT TEST HISTORY PREVIEW
                              if (_academicResults.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Recent Test History',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'Showing ${_academicResults.length > 3 ? 3 : _academicResults.length} of ${_academicResults.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                ..._academicResults.take(3).map((res) {
                                  Color badgeColor = AppColors.info;
                                  Color badgeTextColor = AppColors.info;
                                  if (res.status == 'Pass') {
                                    badgeColor = AppColors.lightEmerald;
                                    badgeTextColor = AppColors.darkEmerald;
                                  } else if (res.status == 'Fail' ||
                                      res.status == 'Absent') {
                                    badgeColor = const Color(0xFFFEE2E2);
                                    badgeTextColor = AppColors.error;
                                  } else if (res.status == 'Pending') {
                                    badgeColor = const Color(0xFFFEF3C7);
                                    badgeTextColor = AppColors.warning;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      res.test.testName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppColors.textMain,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ),
                                                  if (res.isArchived) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.background,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        border: Border.all(
                                                          color:
                                                              AppColors.border,
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Archived',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${res.test.subject} • ${AppDateFormatter.formatDate(res.test.testDate)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              res.marksDisplay,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeColor,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                res.hasMarksValue
                                                    ? '${res.percentageDisplay} • ${res.status}'
                                                    : res.status,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: badgeTextColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                              ],

                              // 4. ACTION BUTTONS
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _navigateToAcademicResults,
                                      icon: const Icon(
                                        Icons.analytics_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'View All Results',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.primaryEmerald,
                                        side: const BorderSide(
                                          color: AppColors.primaryEmerald,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StudentAcademicReportScreen(
                                                  student: _student,
                                                  classModel: _assignedClass,
                                                  results: _academicResults,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Academic Report',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primaryEmerald,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isAdmin) ...[
                          // SECTION 8 — APPLICABLE NOTICES
                          _buildSectionCard(
                            title: 'Notices (${_applicableNotices.length})',
                            icon: Icons.campaign_outlined,
                            children: [
                              if (_applicableNotices.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'No notices applicable to this student.',
                                    style: AppTextStyles.subtitle,
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _applicableNotices.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                  itemBuilder: (context, index) {
                                    final notice = _applicableNotices[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            notice.isPinned
                                                ? Icons.push_pin_rounded
                                                : Icons
                                                      .notifications_none_rounded,
                                            size: 18,
                                            color: notice.isPinned
                                                ? AppColors.primaryEmerald
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notice.title,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textMain,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  notice.description,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // SECTION 9 — COMPLAINTS (Allowed for teacher)
                        _buildSectionCard(
                          title: 'Complaints (${_studentComplaints.length})',
                          icon: Icons.report_problem_outlined,
                          children: [
                            if (_studentComplaints.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No complaints recorded.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _studentComplaints.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                itemBuilder: (context, index) {
                                  final complaint = _studentComplaints[index];
                                  final bool isResolved =
                                      complaint.status.toLowerCase() ==
                                          'resolved' ||
                                      complaint.status.toLowerCase() ==
                                          'closed';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                complaint.title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Type: ${complaint.type} • Priority: ${complaint.priority}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isResolved
                                                ? AppColors.lightEmerald
                                                : AppColors.error.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            complaint.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isResolved
                                                  ? AppColors.darkEmerald
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightEmerald,
            child: Text(
              _student.name.isNotEmpty ? _student.name[0].toUpperCase() : 'S',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryEmerald,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: ${_student.studentId}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.lightEmerald
                  : AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? AppColors.darkEmerald
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryEmerald),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return PlatformInfoRow(label: label, value: value);
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PlatformInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const PlatformInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return PlatformInfoRowContent(label: label, value: value);
  }
}

class PlatformInfoRowContent extends StatelessWidget {
  final String label;
  final String value;

  const PlatformInfoRowContent({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
