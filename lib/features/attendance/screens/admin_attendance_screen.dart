import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../view_models/attendance_view_model.dart';
import 'attendance_report_screen.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  late final AttendanceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadClasses();
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryEmerald,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      await _viewModel.selectDate(picked, context);
      if (_viewModel.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _viewModel.clearMessages();
      }
    }
  }

  Future<void> _handleSave() async {
    if (_viewModel.isSaving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final success = await _viewModel.saveAttendance(user.uid);
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
                  'Attendance saved successfully.',
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
          content: Text(_viewModel.errorMessage!),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Attendance Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _viewModel.isLoading && _viewModel.classes.isEmpty
            ? const Center(child: AppLoadingIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Class & Date Selectors
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Select Class',
                                      style: AppTextStyles.inputLabel),
                                  const SizedBox(height: 6),
                                  _viewModel.classes.isEmpty
                                      ? Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: AppColors.border),
                                          ),
                                          child: const Text(
                                              'No classes available',
                                              style: TextStyle(
                                                  color: AppColors
                                                      .textSecondary)),
                                        )
                                      : DropdownButtonFormField<ClassModel>(
                                          initialValue: _viewModel.selectedClass,
                                          style: AppTextStyles.inputText,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppColors.surface,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 14),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color: AppColors.border),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                  color:
                                                      AppColors.primaryEmerald,
                                                  width: 1.5),
                                            ),
                                          ),
                                          items: _viewModel.classes.map((cls) {
                                            return DropdownMenuItem(
                                              value: cls,
                                              child: Text(cls.className),
                                            );
                                          }).toList(),
                                          onChanged: (cls) {
                                            if (cls != null) {
                                              _viewModel.selectClass(cls);
                                            }
                                          },
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date',
                                      style: AppTextStyles.inputLabel),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: _selectDate,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _viewModel.formattedDate,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 18,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Summary Card
                        Container(
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
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryMetric(
                                  label: 'Total',
                                  value: '${_viewModel.totalStudents}',
                                  color: AppColors.textMain,
                                ),
                              ),
                              Container(
                                  width: 1, height: 36, color: AppColors.border),
                              Expanded(
                                child: _buildSummaryMetric(
                                  label: 'Present',
                                  value: '${_viewModel.presentCount}',
                                  color: AppColors.success,
                                ),
                              ),
                              Container(
                                  width: 1, height: 36, color: AppColors.border),
                              Expanded(
                                child: _buildSummaryMetric(
                                  label: 'Absent',
                                  value: '${_viewModel.absentCount}',
                                  color: AppColors.error,
                                ),
                              ),
                              Container(
                                  width: 1, height: 36, color: AppColors.border),
                              Expanded(
                                child: _buildSummaryMetric(
                                  label: 'Attendance',
                                  value:
                                      '${_viewModel.attendancePercentage.toStringAsFixed(1)}%',
                                  color: AppColors.primaryEmerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Students List Header & Mark All Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Students (${_viewModel.students.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            if (_viewModel.students.isNotEmpty)
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: _viewModel.isSaving
                                        ? null
                                        : () => _viewModel.markAllPresent(),
                                    icon: const Icon(Icons.done_all_rounded,
                                        size: 16, color: AppColors.success),
                                    label: const Text('All Present',
                                        style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton.icon(
                                    onPressed: _viewModel.isSaving
                                        ? null
                                        : () => _viewModel.markAllAbsent(),
                                    icon: const Icon(
                                        Icons.remove_done_rounded,
                                        size: 16,
                                        color: AppColors.error),
                                    label: const Text('All Absent',
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Students Attendance List
                        _viewModel.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(child: AppLoadingIndicator()),
                              )
                            : _viewModel.students.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: const Text(
                                      'No students found in this class.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _viewModel.students.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final student =
                                          _viewModel.students[index];
                                      final status = _viewModel
                                              .attendanceMap[student.studentId] ??
                                          'present';
                                      final isPresent = status == 'present';

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    student.name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .textMain,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'ID: ${student.studentId}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            ToggleButtons(
                                              isSelected: [
                                                isPresent,
                                                !isPresent
                                              ],
                                              onPressed: _viewModel.isSaving
                                                  ? null
                                                  : (selectedIndex) {
                                                      _viewModel.setStatus(
                                                        student.studentId,
                                                        selectedIndex == 0
                                                            ? 'present'
                                                            : 'absent',
                                                      );
                                                    },
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              selectedColor: Colors.white,
                                              fillColor: isPresent
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              color: AppColors.textSecondary,
                                              constraints:
                                                  const BoxConstraints(
                                                      minHeight: 36,
                                                      minWidth: 70),
                                              children: const [
                                                Text('Present',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                Text('Absent',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                        const SizedBox(height: 32),

                        // Save Button
                        if (_viewModel.students.isNotEmpty) ...[
                          PrimaryButton(
                            text: 'Save Attendance',
                            isLoading: _viewModel.isSaving,
                            onPressed: _viewModel.isSaving ? null : _handleSave,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // View Attendance Report Button
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AttendanceReportScreen(
                                  initialClass: _viewModel.selectedClass,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bar_chart_rounded,
                              size: 18, color: AppColors.primaryEmerald),
                          label: const Text('View Attendance Report',
                              style: TextStyle(
                                  color: AppColors.primaryEmerald,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(
                                color: AppColors.primaryEmerald),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
