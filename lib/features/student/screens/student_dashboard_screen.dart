import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_academic_result.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/test_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../attendance/screens/student_attendance_screen.dart';
import '../../complaints/screens/complaints_list_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../reports/screens/student_academic_report_screen.dart';
import '../../students/screens/academic_results_screen.dart';
import '../../students/screens/student_details_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final AuthService _authService = AuthService();
  final StudentRepository _studentRepository = StudentRepository();
  final ClassRepository _classRepository = ClassRepository();
  final TestRepository _testRepository = TestRepository();

  bool _isLoading = true;
  StudentModel? _student;
  ClassModel? _studentClass;
  List<StudentAcademicResult> _academicResults = [];
  StudentAcademicSummary? _academicSummary;

  @override
  void initState() {
    super.initState();
    _loadStudentDashboard();
  }

  Future<void> _loadStudentDashboard() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final uid = currentUser.uid;
        final students = await _studentRepository.getStudents();
        StudentModel? st;
        for (var s in students) {
          if (s.studentId == uid || s.userId == uid) {
            st = s;
            break;
          }
        }
        _student = st;

        if (_student != null && _student!.classId != null && _student!.classId!.isNotEmpty) {
          final classes = await _classRepository.getClasses();
          for (var c in classes) {
            if (c.classId == _student!.classId) {
              _studentClass = c;
              break;
            }
          }

          final tests = await _testRepository.getTestsForClass(_student!.classId!);
          final studentMarks = await _testRepository.getMarksForStudent(_student!.studentId);
          final markByTestId = {for (var m in studentMarks) m.testId: m};

          final results = <StudentAcademicResult>[];
          for (var t in tests) {
            results.add(StudentAcademicResult(
              test: t,
              mark: markByTestId[t.testId],
              classModel: _studentClass,
            ));
          }
          results.sort((a, b) => b.test.testDate.compareTo(a.test.testDate));
          _academicResults = results;
          _academicSummary = StudentAcademicSummary(allResults: results);
        }
      }
    } catch (e) {
      debugPrint('[StudentDashboardScreen] Error loading student dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Student Portal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: NotificationRepository()
                .streamNotificationsForRecipient(user?.uid ?? '', userRole: 'student'),
            builder: (context, snapshot) {
              final unreadCount = (snapshot.data ?? []).where((n) => !n.isRead).length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textMain),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryEmerald),
            tooltip: 'Profile',
            onPressed: () {
              if (_student != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(student: _student!),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : RefreshIndicator(
                onRefresh: _loadStudentDashboard,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. WELCOME HEADER
                          _buildWelcomeCard(),
                          const SizedBox(height: 20),

                          // 2. ACADEMIC OVERVIEW
                          if (_academicSummary != null && _academicSummary!.totalTests > 0) ...[
                            _buildAcademicOverviewCard(),
                            const SizedBox(height: 20),
                          ],

                          // 3. WORKSPACE MODULES GRID
                          const Text(
                            'My Workspace',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          ),
                          const SizedBox(height: 14),

                          _buildWorkspaceGrid(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.lightEmerald,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_rounded, size: 24, color: AppColors.primaryEmerald),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_student?.name ?? "Student"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMain),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_studentClass?.className ?? "Class"} • Student ID: ${_student?.studentId ?? "N/A"}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Academic Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_student != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => StudentAcademicReportScreen(
                          student: _student!,
                          classModel: _studentClass,
                          results: _academicResults,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                label: const Text('Report', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Completed Tests',
                  value: '${_academicSummary!.completedCount} / ${_academicSummary!.totalTests}',
                  color: AppColors.textMain,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Weighted Avg',
                  value: '${_academicSummary!.overallAveragePercentage.toStringAsFixed(1)}%',
                  color: AppColors.primaryEmerald,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Pass / Fail',
                  value: '${_academicSummary!.passCount} P · ${_academicSummary!.failCount} F',
                  color: _academicSummary!.failCount == 0 ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildWorkspaceGrid() {
    final modules = [
      {
        'title': 'My Complaints',
        'subtitle': 'Track issues & response',
        'icon': Icons.report_problem_outlined,
        'color': AppColors.warning,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ComplaintsListScreen(studentId: _student?.studentId),
            ),
          );
        },
      },
      {
        'title': 'Academic Results',
        'subtitle': 'Tests & marks history',
        'icon': Icons.analytics_outlined,
        'color': AppColors.primaryEmerald,
        'onTap': () {
          if (_student != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AcademicResultsScreen(
                  student: _student!,
                  classModel: _studentClass,
                  initialResults: _academicResults,
                ),
              ),
            );
          }
        },
      },
      {
        'title': 'My Attendance',
        'subtitle': 'Calendar & records',
        'icon': Icons.calendar_today_outlined,
        'color': AppColors.info,
        'onTap': () {
          if (_student != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudentAttendanceScreen(studentId: _student!.studentId),
              ),
            );
          }
        },
      },
      {
        'title': 'My Profile',
        'subtitle': 'Student details & class',
        'icon': Icons.person_outline_rounded,
        'color': AppColors.teacherAccent,
        'onTap': () {
          if (_student != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StudentDetailsScreen(student: _student!),
              ),
            );
          }
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final mod = modules[index];
        return InkWell(
          onTap: mod['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (mod['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(mod['icon'] as IconData, size: 20, color: mod['color'] as Color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mod['title'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mod['subtitle'] as String,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
