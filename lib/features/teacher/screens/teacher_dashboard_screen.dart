import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../view_models/teacher_view_model.dart';
import 'teacher_assigned_classes_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_complaints_screen.dart';
import 'teacher_notifications_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_student_list_screen.dart';
import 'teacher_tests_screen.dart';
import '../../notices/screens/notices_list_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  late final TeacherViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TeacherViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadTeacherDashboard();
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

  Future<void> _navigateToAssignedClasses() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeacherAssignedClassesScreen(),
      ),
    );
    if (mounted) {
      _viewModel.loadTeacherDashboard();
    }
  }

  Future<void> _navigateToStudentList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TeacherStudentListScreen(),
      ),
    );
    if (mounted) {
      _viewModel.loadTeacherDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Teacher Workspace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: NotificationRepository()
                .streamNotificationsForRecipient(FirebaseAuth.instance.currentUser?.uid ?? ''),
            builder: (context, snapshot) {
              final unreadCount = (snapshot.data ?? []).where((n) => !n.isRead).length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.textMain),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TeacherNotificationsScreen(),
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
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.primaryEmerald),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TeacherProfileScreen(),
                ),
              );
            },
          ),
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
        child: _viewModel.isLoading
            ? const Center(child: AppLoadingIndicator())
            : RefreshIndicator(
                onRefresh: _viewModel.loadTeacherDashboard,
                color: AppColors.teacherAccent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. WELCOME HEADER
                          _buildWelcomeHeader(),
                          const SizedBox(height: 16),

                          // 1.5 MY SUBJECTS SECTION
                          _buildSubjectsSection(),
                          const SizedBox(height: 24),

                          // 2. ACADEMIC WORKSPACE MODULES
                          const Text(
                            'Academic Workspace',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
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

  Widget _buildWelcomeHeader() {
    final userId = _viewModel.teacherUserId;
    final subject = _viewModel.teacherModel?.subject ?? 'Mathematics';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 24,
                  color: AppColors.teacherAccent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_viewModel.teacherDisplayName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Here's an overview of your academic workspace.",
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (userId != null && userId.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 15,
                      color: AppColors.teacherAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'User ID: $userId',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teacherAccent,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      size: 15,
                      color: AppColors.teacherAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Subject: $subject',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teacherAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkspaceGrid() {
    final int classCount = _viewModel.assignedClassesCount;
    final int studentCount = _viewModel.totalStudents;

    final modules = [
      {
        'title': 'My Classes',
        'subtitle': 'Manage assigned classes',
        'count': classCount == 1 ? '1 Assigned Class' : '$classCount Assigned Classes',
        'icon': Icons.class_outlined,
        'action': _navigateToAssignedClasses,
      },
      {
        'title': 'My Students',
        'subtitle': 'Student list by class',
        'count': studentCount == 1 ? '1 Student' : '$studentCount Students',
        'icon': Icons.people_outline_rounded,
        'action': _navigateToStudentList,
      },
      {
        'title': 'Attendance',
        'subtitle': 'Mark & view attendance',
        'icon': Icons.calendar_today_outlined,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TeacherAttendanceScreen(),
            ),
          );
        },
      },
      {
        'title': 'Tests & Marks',
        'subtitle': 'Assessments & scores',
        'icon': Icons.assignment_outlined,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TeacherTestsScreen(),
            ),
          );
        },
      },
      {
        'title': 'Complaints',
        'subtitle': 'Student issues & reports',
        'icon': Icons.report_problem_outlined,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TeacherComplaintsScreen(),
            ),
          );
        },
      },
      {
        'title': 'Notice Board',
        'subtitle': 'Announcements & notices',
        'icon': Icons.campaign_outlined,
        'action': () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NoticesListScreen(),
            ),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final mod = modules[index];
        final String? count = mod['count'] as String?;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: mod['action'] as VoidCallback?,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          mod['icon'] as IconData,
                          size: 20,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    mod['title'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mod['subtitle'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightEmerald,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkEmerald,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsSection() {
    final teacher = _viewModel.teacherModel;
    final subs = teacher != null && teacher.subjects.isNotEmpty 
        ? teacher.subjects.toSet().toList() 
        : (teacher?.subject != null && teacher!.subject.isNotEmpty ? [teacher.subject] : <String>[]);

    return Container(
      width: double.infinity,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.book_outlined, size: 18, color: AppColors.teacherAccent),
                  SizedBox(width: 8),
                  Text(
                    'My Subjects',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${subs.length} Assigned',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teacherAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          subs.isEmpty
              ? const Text(
                  'No subjects assigned',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subs.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.teacherAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teacherAccent,
                      ),
                    ),
                  )).toList(),
                ),
        ],
      ),
    );
  }
}
