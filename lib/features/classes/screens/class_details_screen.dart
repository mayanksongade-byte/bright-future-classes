import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../students/screens/student_details_screen.dart';
import '../../teachers/screens/teacher_details_screen.dart';
import '../view_models/class_details_view_model.dart';

class ClassDetailsScreen extends StatefulWidget {
  final ClassModel classModel;

  const ClassDetailsScreen({super.key, required this.classModel});

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  late final ClassDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ClassDetailsViewModel(classModel: widget.classModel);
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadClassDetails();
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

  Future<void> _navigateToTeacherDetails(TeacherModel teacher) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TeacherDetailsScreen(teacher: teacher),
      ),
    );

    if (result == true && mounted) {
      _viewModel.loadClassDetails();
    }
  }

  Future<void> _navigateToStudentDetails(StudentModel student) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(student: student),
      ),
    );

    if (result == true && mounted) {
      _viewModel.loadClassDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.classModel;
    final bool isActive = cls.status.toLowerCase() == 'active';

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
        title: Text(
          cls.className,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
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
                onRefresh: _viewModel.loadClassDetails,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class Overview Card
                          Container(
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        cls.className,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
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
                                            : AppColors.border
                                                .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(20),
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
                                const SizedBox(height: 16),
                                const Divider(
                                    height: 1, color: AppColors.border),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailTile(
                                        label: 'Standard',
                                        value: cls.standard,
                                        icon: Icons.class_outlined,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailTile(
                                        label: 'Medium',
                                        value: cls.medium,
                                        icon: Icons.translate_rounded,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailTile(
                                        label: 'Academic Year',
                                        value: cls.academicYear,
                                        icon: Icons.calendar_today_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDetailTile(
                                        label: 'Teachers',
                                        value: '${_viewModel.teacherCount}',
                                        icon: Icons.badge_outlined,
                                        valueColor: AppColors.teacherAccent,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildDetailTile(
                                        label: 'Students',
                                        value: '${_viewModel.studentCount}',
                                        icon: Icons.people_outline_rounded,
                                        valueColor: AppColors.primaryEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Assigned Teachers Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Assigned Teachers (${_viewModel.teacherCount})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _viewModel.assignedTeachers.isEmpty
                              ? _buildEmptySection(
                                  'No teacher assigned to this class.')
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      _viewModel.assignedTeachers.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final teacher =
                                        _viewModel.assignedTeachers[index];
                                    return _buildTeacherCard(teacher);
                                  },
                                ),
                          const SizedBox(height: 28),

                          // Assigned Students Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Students (${_viewModel.studentCount})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _viewModel.assignedStudents.isEmpty
                              ? _buildEmptySection(
                                  'No students assigned to this class.')
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount:
                                      _viewModel.assignedStudents.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final student =
                                        _viewModel.assignedStudents[index];
                                    return _buildStudentCard(student);
                                  },
                                ),
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

  Widget _buildDetailTile({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textMain,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTeacherCard(TeacherModel teacher) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTeacherDetails(teacher),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Email: ${teacher.email} • Phone: ${teacher.phone}',
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToStudentDetails(student),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${student.studentId} • Phone: ${student.phone}',
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
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
