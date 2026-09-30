import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../attendance/screens/admin_attendance_screen.dart';
import '../../classes/screens/add_class_screen.dart';
import '../../classes/screens/classes_screen.dart';
import '../../fees/screens/fees_screen.dart';
import '../../students/screens/add_student_screen.dart';
import '../../students/screens/students_screen.dart';
import '../../teachers/screens/add_teacher_screen.dart';
import '../../teachers/screens/teachers_screen.dart';
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.textMain,
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FeesScreen(),
                ),
              );
              _viewModel.loadDashboardData();
            },
            tooltip: 'Fees',
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textMain,
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminAttendanceScreen(),
                ),
              );
              _viewModel.loadDashboardData();
            },
            tooltip: 'Attendance',
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textMain,
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textMain,
            ),
            onPressed: () {},
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
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
                  // Dashboard Header Overview
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Monitor your tuition operations at a glance',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 20),

                  // Stat Cards Grid
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Today's Attendance Card
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
                    child: _buildAttendanceCard(),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
                      const SizedBox(width: 10),
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
                      const SizedBox(width: 10),
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
                  const SizedBox(height: 24),

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

  Widget _buildAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Today's Attendance",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Present',
                  value: '${_viewModel.todayPresent}',
                  color: AppColors.success,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Absent',
                  value: '${_viewModel.todayAbsent}',
                  color: AppColors.error,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.border,
              ),
              Expanded(
                child: _buildAttendanceMetric(
                  label: 'Attendance',
                  value:
                      '${_viewModel.todayAttendancePercentage.toStringAsFixed(0)}%',
                  color: AppColors.primaryEmerald,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primaryEmerald,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
