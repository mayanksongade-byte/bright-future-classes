import 'package:flutter/material.dart';
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

  List<NoticeModel> _applicableNotices = [];
  List<ComplaintModel> _studentComplaints = [];

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _checkRoleAndLoadDetails();
  }

  Future<void> _checkRoleAndLoadDetails() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser != null) {
        final userDoc = await FirestoreService().getUserDocument(currentUser.uid);
        final role = (userDoc?['role'] as String? ?? '').toLowerCase();
        final isActive = userDoc?['isActive'] as bool? ?? false;
        final isTeacherRole = (role == 'teacher') && isActive;
        final isAdminRole = (role == 'admin') && isActive;

        TeacherModel? teacher;
        if (isTeacherRole) {
          final teacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;
          final teacherData = await FirestoreService().getTeacherDocument(teacherId);
          if (teacherData != null) {
            teacher = TeacherModel.fromMap(teacherData, teacherId);
          }
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
      // 1. Resolve Class
      ClassModel? cls;
      if (_student.classId != null && _student.classId!.isNotEmpty) {
        final classes = await _classRepository.getClasses();
        for (var c in classes) {
          if (c.classId == _student.classId) {
            cls = c;
            break;
          }
        }
      }
      _assignedClass = cls;

      // 2. Resolve Teacher assigned to this class
      TeacherModel? teacher;
      if (_student.classId != null && _student.classId!.isNotEmpty) {
        final teachers = await _teacherRepository.getTeachers();
        for (var t in teachers) {
          if (t.classIds.contains(_student.classId)) {
            teacher = t;
            break;
          }
        }
      }
      _assignedTeacher = teacher;

      // 3. Resolve Attendance
      try {
        List<AttendanceModel> attendanceList =
            await _attendanceRepository.getAttendanceForStudent(_student.studentId);

        if (_student.userId != null &&
            _student.userId!.isNotEmpty &&
            _student.userId != _student.studentId) {
          final additionalList =
              await _attendanceRepository.getAttendanceForStudent(_student.userId!);
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
        debugPrint('[StudentDetailsScreen] Failed to load student attendance summary: $e');
      }

      // 4. Resolve Fees (Admin Only)
      if (_isAdmin) {
        try {
          final allFees = await _feeRepository.getAllFees();
          final studentFees =
              allFees.where((f) => f.studentId == _student.studentId).toList();
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
      try {
        List<TestModel> tests = [];
        if (_student.classId != null && _student.classId!.isNotEmpty) {
          if (_isTeacher && _loggedInTeacher != null) {
            if (_loggedInTeacher!.classIds.contains(_student.classId)) {
              tests = await _testRepository.getTestsForClass(_student.classId!);
            } else {
              tests = [];
            }
          } else {
            tests = await _testRepository.getTestsForClass(_student.classId!);
          }
        }

        if (tests.isEmpty && _isAdmin) {
          tests = await _testRepository.getAllTests();
        }

        // If logged-in user is a teacher, filter tests to authorized subjects only
        if (_isTeacher && _loggedInTeacher != null) {
          tests = tests.where((t) => _loggedInTeacher!.teachesSubject(t.subject)).toList();
        }

        final studentMarks = await _testRepository.getMarksForStudent(_student.studentId);
        final Map<String, MarkModel> markByTestId = {};
        for (var m in studentMarks) {
          markByTestId[m.testId] = m;
        }

        final List<StudentAcademicResult> parsedResults = [];
        for (var test in tests) {
          if (_student.classId != null &&
              _student.classId!.isNotEmpty &&
              test.classId != _student.classId) {
            continue;
          }
          final m = markByTestId[test.testId];
          parsedResults.add(StudentAcademicResult(
            test: test,
            mark: m,
            classModel: _assignedClass,
          ));
        }

        parsedResults.sort((a, b) => b.test.testDate.compareTo(a.test.testDate));

        _academicResults = parsedResults;
        _academicSummary = StudentAcademicSummary(allResults: parsedResults);
      } catch (e) {
        debugPrint('[StudentDetailsScreen] Error resolving tests & marks: $e');
      }

      // 6. Resolve Notices (Admin Only)
      if (_isAdmin) {
        try {
          final notices = await _noticeRepository.getNotices();
          _applicableNotices = notices.where((notice) {
            final isAllStudents =
                notice.targetAudience.toLowerCase() == 'all_students';
            final isClassMatch = _student.classId != null &&
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
          _studentComplaints =
              await _complaintRepository.getComplaintsForStudent(_student.studentId);
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
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primaryEmerald),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                            _buildInfoRow('Date of Birth',
                                _student.dateOfBirth.isNotEmpty ? AppDateFormatter.formatDate(_student.dateOfBirth) : '-'),
                            _buildInfoRow('Gender', _student.gender),
                            _buildInfoRow('Status', isActive ? 'Active' : 'Inactive'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 2 — CONTACT INFORMATION
                        _buildSectionCard(
                          title: 'Contact Information',
                          icon: Icons.phone_outlined,
                          children: [
                            _buildInfoRow('Student Phone',
                                _student.phone.isNotEmpty ? _student.phone : '-'),
                            _buildInfoRow('Address',
                                _student.address.isNotEmpty ? _student.address : '-'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 3 — PARENT / GUARDIAN INFORMATION
                        _buildSectionCard(
                          title: 'Parent / Guardian Information',
                          icon: Icons.family_restroom_outlined,
                          children: [
                            _buildInfoRow('Parent Name',
                                _student.parentName.isNotEmpty ? _student.parentName : '-'),
                            _buildInfoRow('Parent Phone',
                                _student.parentPhone.isNotEmpty ? _student.parentPhone : '-'),
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
                                _buildInfoRow('Academic Year', _assignedClass!.academicYear),
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
                                      value: '${_attendancePercentage.toStringAsFixed(1)}%',
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
                                        builder: (context) => StudentAttendanceScreen(
                                          studentId: _student.studentId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.history_rounded, size: 18),
                                  label: const Text('View Attendance History'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryEmerald,
                                    side: const BorderSide(color: AppColors.primaryEmerald),
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
                                      value: '₹${_totalFees.toStringAsFixed(0)}',
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
                                      value: '₹${_pendingFees.toStringAsFixed(0)}',
                                      color: _pendingFees > 0 ? AppColors.error : AppColors.success,
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
                          title: 'Tests & Marks',
                          icon: Icons.assignment_outlined,
                          children: [
                            if (_academicSummary == null || _academicSummary!.totalTests == 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No tests recorded for this class yet.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Completed Tests',
                                      value: '${_academicSummary!.completedCount} / ${_academicSummary!.totalTests}',
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Overall Average',
                                      value: '${_academicSummary!.overallAveragePercentage.toStringAsFixed(1)}%',
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Pass / Fail',
                                      value: '${_academicSummary!.passCount} P · ${_academicSummary!.failCount} F',
                                      color: _academicSummary!.failCount == 0 ? AppColors.success : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              const Text(
                                'Subject Performance Summary',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._academicSummary!.subjectSummaries.map((sub) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub.subjectName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${sub.completedCount}/${sub.totalTests} Evaluated • ${sub.passCount} Pass · ${sub.failCount} Fail · ${sub.pendingCount} Pending',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${sub.subjectAveragePercentage.toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _navigateToAcademicResults,
                                      icon: const Icon(Icons.analytics_outlined, size: 16),
                                      label: const Text('View All Results', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryEmerald,
                                        side: const BorderSide(color: AppColors.primaryEmerald),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
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
                                            builder: (context) => StudentAcademicReportScreen(
                                              student: _student,
                                              classModel: _assignedClass,
                                              results: _academicResults,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                                      label: const Text('Academic Report', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryEmerald,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
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
                                      const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (context, index) {
                                    final notice = _applicableNotices[index];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            notice.isPinned
                                                ? Icons.push_pin_rounded
                                                : Icons.notifications_none_rounded,
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
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
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
                                    const Divider(height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final complaint = _studentComplaints[index];
                                  final bool isResolved =
                                      complaint.status.toLowerCase() == 'resolved' ||
                                      complaint.status.toLowerCase() == 'closed';
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
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
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isResolved
                                                ? AppColors.lightEmerald
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                color: isActive ? AppColors.darkEmerald : AppColors.textSecondary,
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

  const PlatformInfoRowContent({super.key, required this.label, required this.value});

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
