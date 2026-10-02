import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/teacher_model.dart';
import '../view_models/teachers_view_model.dart';
import 'add_teacher_screen.dart';
import 'teacher_details_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  late final TeachersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TeachersViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.fetchTeachers();
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

  Future<void> _navigateToAddTeacher() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddTeacherScreen(),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchTeachers();
    }
  }

  Future<void> _navigateToTeacherDetails(TeacherModel teacher) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TeacherDetailsScreen(teacher: teacher),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchTeachers();
    }
  }

  Future<void> _navigateToEditTeacher(TeacherModel teacher) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTeacherScreen(teacherToEdit: teacher),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchTeachers();
    }
  }

  Future<void> _confirmDelete(TeacherModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Teacher?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${teacher.name}"? This action cannot be undone.',
            style: AppTextStyles.subtitle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deleteTeacher(teacher.teacherId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Teacher deleted successfully',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _viewModel.errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textMain,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Teachers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          if (_viewModel.teachers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _navigateToAddTeacher,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.primaryEmerald,
                ),
                label: const Text(
                  'Add Teacher',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ),
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
            : _viewModel.teachers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _viewModel.fetchTeachers,
                    color: AppColors.primaryEmerald,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
                              Text(
                                'Active Teachers (${_viewModel.teachers.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _viewModel.teachers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final teacher = _viewModel.teachers[index];
                                  return _buildTeacherCard(teacher);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
      floatingActionButton: _viewModel.teachers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddTeacher,
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '+ Add Teacher',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 48,
                  color: AppColors.teacherAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Teachers Added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add faculty profiles and assign them to classes to manage your teaching staff.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _navigateToAddTeacher,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  '+ Add Teacher',
                  style: AppTextStyles.button,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherCard(TeacherModel teacher) {
    final bool isActive = teacher.status.toLowerCase() == 'active';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTeacherDetails(teacher),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.teacherAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (teacher.userId != null &&
                                  teacher.userId!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'User ID: ${teacher.userId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryEmerald,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                teacher.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navigateToEditStudent(teacher);
                      } else if (value == 'delete') {
                        _confirmDelete(teacher);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: AppColors.primaryEmerald),
                            SizedBox(width: 8),
                            Text('Edit Teacher'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Teacher',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile(
                      label: 'Phone',
                      value: teacher.phone,
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailTile(
                      label: 'Assigned Classes',
                      value: '${teacher.classIds.length} Classes',
                      icon: Icons.school_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditStudent(TeacherModel teacher) {
    _navigateToEditTeacher(teacher);
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
