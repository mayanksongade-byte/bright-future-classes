import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/student_model.dart';
import '../view_models/students_view_model.dart';
import 'add_student_screen.dart';
import 'student_details_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  late final StudentsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StudentsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.fetchStudents();
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

  Future<void> _navigateToAddStudent() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddStudentScreen(),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchStudents();
    }
  }

  Future<void> _navigateToStudentDetails(StudentModel student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(student: student),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchStudents();
    }
  }

  Future<void> _navigateToEditStudent(StudentModel student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(studentToEdit: student),
      ),
    );

    if (result == true && mounted) {
      _viewModel.fetchStudents();
    }
  }

  Future<void> _confirmDelete(StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Student?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${student.name}"? This action cannot be undone.',
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
      final success = await _viewModel.deleteStudent(student.studentId);
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
                    'Student deleted successfully',
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
          'Students',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          if (_viewModel.students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _navigateToAddStudent,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.primaryEmerald,
                ),
                label: const Text(
                  'Add Student',
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
            : _viewModel.students.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _viewModel.fetchStudents,
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
                                'Active Students (${_viewModel.students.length})',
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
                                itemCount: _viewModel.students.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final student = _viewModel.students[index];
                                  return _buildStudentCard(student);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
      floatingActionButton: _viewModel.students.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _navigateToAddStudent,
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '+ Add Student',
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
                  color: AppColors.lightEmerald,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  size: 48,
                  color: AppColors.primaryEmerald,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Students Added',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Start building your class roster by adding student profiles with contact details.',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _navigateToAddStudent,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  '+ Add Student',
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

  Widget _buildStudentCard(StudentModel student) {
    final bool isActive = student.status.toLowerCase() == 'active';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToStudentDetails(student),
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
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primaryEmerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${student.studentId}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
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
                        _navigateToEditStudent(student);
                      } else if (value == 'delete') {
                        _confirmDelete(student);
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
                            Text('Edit Student'),
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
                            Text('Delete Student',
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
                      value: student.phone,
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailTile(
                      label: 'Parent Name',
                      value: student.parentName,
                      icon: Icons.family_restroom_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailTile(
                      label: 'Parent Phone',
                      value: student.parentPhone,
                      icon: Icons.contact_phone_outlined,
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
