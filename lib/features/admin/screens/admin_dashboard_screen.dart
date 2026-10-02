import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../attendance/screens/admin_attendance_screen.dart';
import '../../classes/screens/add_class_screen.dart';
import '../../classes/screens/classes_screen.dart';
import '../../complaints/screens/complaints_list_screen.dart';
import '../../fees/screens/fees_screen.dart';
import '../../homework/screens/homework_list_screen.dart';
import '../../notices/screens/notices_list_screen.dart';
import '../../reports/screens/reports_screen.dart';
import '../../students/screens/add_student_screen.dart';
import '../../students/screens/students_screen.dart';
import '../../teachers/screens/add_teacher_screen.dart';
import '../../teachers/screens/teachers_screen.dart';
import '../../tests/screens/tests_list_screen.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../view_models/admin_view_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AdminViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadDashboardData();
  }

  void _onViewModelChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'BF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          NotificationBellWidget(),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. OVERVIEW SECTION
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Monitor your tuition operations at a glance',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),

                  // Continuous Grid (Total Students, Total Teachers, Total Classes, Pending Fees, Total Homework, Total Notices, Total Complaints, Reports, Total Tests)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.4 : 1.3,
                        children: [
                          _buildStatCard(
                            title: 'Total Students',
                            value: '${_viewModel.totalStudents}',
                            icon: Icons.people_outline_rounded,
                            iconColor: AppColors.primaryEmerald,
                            bgColor: AppColors.lightEmerald,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const StudentsScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Teachers',
                            value: '${_viewModel.totalTeachers}',
                            icon: Icons.badge_outlined,
                            iconColor: AppColors.teacherAccent,
                            bgColor: const Color(0xFFF3E8FF),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TeachersScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Classes',
                            value: '${_viewModel.totalClasses}',
                            icon: Icons.school_outlined,
                            iconColor: AppColors.info,
                            bgColor: const Color(0xFFE0F2FE),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ClassesScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Pending Fees',
                            value: _viewModel.pendingFees,
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: AppColors.warning,
                            bgColor: const Color(0xFFFEF3C7),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const FeesScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Homework',
                            value: '${_viewModel.totalHomework}',
                            icon: Icons.assignment_outlined,
                            iconColor: AppColors.info,
                            bgColor: const Color(0xFFE0F2FE),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const HomeworkListScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Notices',
                            value: '${_viewModel.totalNotices}',
                            icon: Icons.notifications_active_outlined,
                            iconColor: AppColors.primaryEmerald,
                            bgColor: AppColors.lightEmerald,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const NoticesListScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Complaints',
                            value: '${_viewModel.totalComplaints}',
                            icon: Icons.report_gmailerrorred_rounded,
                            iconColor: AppColors.error,
                            bgColor: const Color(0xFFFEE2E2),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ComplaintsListScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Reports & Analytics',
                            value: 'Analytics',
                            icon: Icons.bar_chart_rounded,
                            iconColor: AppColors.primaryEmerald,
                            bgColor: AppColors.lightEmerald,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ReportsScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                          _buildStatCard(
                            title: 'Total Tests',
                            value: '${_viewModel.totalTests}',
                            icon: Icons.quiz_outlined,
                            iconColor: AppColors.primaryEmerald,
                            bgColor: AppColors.lightEmerald,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TestsListScreen(),
                                ),
                              );
                              _viewModel.loadDashboardData();
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // 2. ATTENDANCE SECTION
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminAttendanceScreen(),
                        ),
                      );
                      _viewModel.loadDashboardData();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightEmerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primaryEmerald,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Attendance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Manage / View Attendance',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildAttendanceSummaryMetric(
                                  'Present',
                                  '${_viewModel.todayPresent}',
                                  AppColors.success),
                              const SizedBox(width: 8),
                              _buildAttendanceSummaryMetric(
                                  'Absent',
                                  '${_viewModel.todayAbsent}',
                                  AppColors.error),
                              const SizedBox(width: 8),
                              _buildAttendanceSummaryMetric(
                                  '%',
                                  '${_viewModel.todayAttendancePercentage.toStringAsFixed(0)}%',
                                  AppColors.primaryEmerald),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. QUICK ACTIONS SECTION
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          label: 'Add Student',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddStudentScreen(),
                              ),
                            );
                            _viewModel.loadDashboardData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          label: 'Add Teacher',
                          icon: Icons.person_add_outlined,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddTeacherScreen(),
                              ),
                            );
                            _viewModel.loadDashboardData();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          label: 'Create Class',
                          icon: Icons.add_business_outlined,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddClassScreen(),
                              ),
                            );
                            _viewModel.loadDashboardData();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Recent Activity
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentActivityEmptyState(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryMetric(
      String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.primaryEmerald,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.history_toggle_off_rounded,
            color: AppColors.textSecondary,
            size: 36,
          ),
          SizedBox(height: 8),
          Text(
            'No recent activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
