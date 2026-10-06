import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
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
import '../../attendance/screens/student_attendance_screen.dart';
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
  ClassModel? _assignedClass;
  TeacherModel? _assignedTeacher;

  int _attendancePresent = 0;
  int _attendanceAbsent = 0;
  double _attendancePercentage = 0.0;

  double _totalFees = 0.0;
  double _paidFees = 0.0;
  double _pendingFees = 0.0;

  int _testsTaken = 0;
  double _averageMarksPercentage = 0.0;
  Map<String, dynamic>? _latestResult;
  List<Map<String, dynamic>> _allStudentResults = [];

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
        if (mounted) {
          setState(() {
            _isAdmin = role == 'admin' && isActive;
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
        final attendanceList =
            await _attendanceRepository.getAttendanceForStudent(_student.studentId);
        int present = 0;
        int absent = 0;
        for (var att in attendanceList) {
          if (att.status.toLowerCase() == 'present') {
            present++;
          } else if (att.status.toLowerCase() == 'absent') {
            absent++;
          }
        }
        _attendancePresent = present;
        _attendanceAbsent = absent;
        final total = present + absent;
        _attendancePercentage = total > 0 ? (present / total) * 100 : 0.0;
      } catch (_) {}

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
        if (_isAdmin) {
          tests = await _testRepository.getAllTests();
        } else if (_student.classId != null && _student.classId!.isNotEmpty) {
          tests = await _testRepository.getTestsForClass(_student.classId!);
        }

        final List<Map<String, dynamic>> results = [];
        double totalScorePerc = 0.0;
        int scoredCount = 0;

        for (var test in tests) {
          if (_student.classId != null &&
              _student.classId!.isNotEmpty &&
              test.classId != _student.classId) {
            continue;
          }
          final marks = await _testRepository.getMarksForTest(test.testId);
          final studentMark = marks.firstWhere(
            (m) => m.studentId == _student.studentId,
            orElse: () => MarkModel(
              markId: '',
              testId: test.testId,
              studentId: _student.studentId,
              classId: test.classId,
            ),
          );

          if (studentMark.markId.isNotEmpty) {
            final double? markVal = studentMark.isAbsent ? 0.0 : studentMark.marks;
            final double maxMarks = test.totalMarks > 0 ? test.totalMarks : 100.0;
            final double perc =
                markVal != null ? (markVal / maxMarks) * 100.0 : 0.0;

            if (markVal != null) {
              totalScorePerc += perc;
              scoredCount++;
            }

            results.add({
              'testName': test.testName,
              'subject': test.subject,
              'testDate': test.testDate,
              'marksObtained': studentMark.isAbsent ? 'Absent' : (markVal?.toStringAsFixed(1) ?? 'N/A'),
              'totalMarks': maxMarks.toStringAsFixed(0),
              'isAbsent': studentMark.isAbsent,
              'percentage': perc,
            });
          }
        }

        _testsTaken = results.length;
        _allStudentResults = results;
        _averageMarksPercentage =
            scoredCount > 0 ? totalScorePerc / scoredCount : 0.0;
        _latestResult = results.isNotEmpty ? results.first : null;
      } catch (_) {}

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

  void _showAllResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Academic Results (${_allStudentResults.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _allStudentResults.isEmpty
                        ? const Center(
                            child: Text(
                              'No test results recorded yet.',
                              style: AppTextStyles.subtitle,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: _allStudentResults.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final res = _allStudentResults[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                                            res['testName'] as String,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Subject: ${res['subject']} • Date: ${res['testDate']}',
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
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: (res['isAbsent'] as bool)
                                            ? AppColors.error.withValues(alpha: 0.1)
                                            : AppColors.lightEmerald,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${res['marksObtained']} / ${res['totalMarks']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: (res['isAbsent'] as bool)
                                              ? AppColors.error
                                              : AppColors.darkEmerald,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                                _student.dateOfBirth.isNotEmpty ? _student.dateOfBirth : '-'),
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
                            if (_allStudentResults.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No tests recorded yet.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Tests Taken',
                                      value: '$_testsTaken',
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Average Score',
                                      value: '${_averageMarksPercentage.toStringAsFixed(1)}%',
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              if (_latestResult != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Latest Result',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_latestResult!['testName']} (${_latestResult!['subject']})',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${_latestResult!['marksObtained']} / ${_latestResult!['totalMarks']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _showAllResultsBottomSheet,
                                  icon: const Icon(Icons.analytics_outlined, size: 18),
                                  label: const Text('View All Results'),
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
