import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../view_models/attendance_view_model.dart';

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

  Future<void> _selectSubmittedSessionsDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.submittedSessionsDate,
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
      _viewModel.setSubmittedSessionsDate(picked);
    }
  }

  Future<void> _handleSave() async {
    if (_viewModel.isSaving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final success = await _viewModel.saveAttendance(
      user.uid,
      currentUserName: user.displayName ?? 'Admin',
      userRole: 'admin',
    );
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

  void _showSessionDetailsModal(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SessionDetailsModalContent(
          initialSession: session,
          viewModel: _viewModel,
        );
      },
    );
  }

  Widget _buildExistingSessionBanner() {
    final submitter = _viewModel.existingSubmitterName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.lightEmerald,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.darkEmerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attendance already submitted by $submitter',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Present: ${_viewModel.presentCount} · Absent: ${_viewModel.absentCount} · Total: ${_viewModel.totalStudents} (${_viewModel.attendancePercentage.toStringAsFixed(1)}%)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
          ),
          const SizedBox(height: 10),
          const Text(
            'To change any student\'s attendance, open Submitted Sessions and edit the existing session.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              _viewModel.setAdminTab(1); // Switch to Submitted Sessions tab!
            },
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Open Submitted Sessions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
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
                        // Tab Switcher for Admin
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _viewModel.setAdminTab(0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _viewModel.adminTabIndex == 0
                                          ? AppColors.primaryEmerald
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Text(
                                      'Mark Attendance',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _viewModel.adminTabIndex == 0
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _viewModel.setAdminTab(1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _viewModel.adminTabIndex == 1
                                          ? AppColors.primaryEmerald
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Text(
                                      'Submitted Sessions',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _viewModel.adminTabIndex == 1
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_viewModel.adminTabIndex == 0) ...[
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

                          // Existing Session Submitted Banner (Case B/C)
                          if (_viewModel.isExistingSessionSubmitted)
                            _buildExistingSessionBanner(),

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
                              if (_viewModel.students.isNotEmpty && !_viewModel.isExistingSessionSubmitted)
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

                          // Student List
                          _viewModel.students.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Text(
                                    'No active students found in this class.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _viewModel.students.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final student = _viewModel.students[index];
                                    final currentStatus =
                                        _viewModel.attendanceMap[student.studentId] ??
                                            'present';
                                    final isPresent = currentStatus == 'present';

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: isPresent
                                                ? AppColors.lightEmerald
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            child: Text(
                                              student.name.isNotEmpty
                                                  ? student.name[0]
                                                  : 'S',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: isPresent
                                                    ? AppColors.primaryEmerald
                                                    : AppColors.error,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textMain,
                                                  ),
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
                                          Row(
                                            children: [
                                              _buildToggleButton(
                                                studentId: student.studentId,
                                                label: 'Present',
                                                statusValue: 'present',
                                                activeColor: AppColors.success,
                                                isSelected: isPresent,
                                                isDisabled: _viewModel.isExistingSessionSubmitted,
                                              ),
                                              const SizedBox(width: 8),
                                              _buildToggleButton(
                                                studentId: student.studentId,
                                                label: 'Absent',
                                                statusValue: 'absent',
                                                activeColor: AppColors.error,
                                                isSelected: !isPresent,
                                                isDisabled: _viewModel.isExistingSessionSubmitted,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          const SizedBox(height: 24),
                          if (!_viewModel.isExistingSessionSubmitted)
                            PrimaryButton(
                              text: 'Save Attendance',
                              onPressed: _viewModel.isSaving ? null : _handleSave,
                            ),
                        ] else ...[
                          // SUBMITTED SESSIONS TAB
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filter by Date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              InkWell(
                                onTap: _selectSubmittedSessionsDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryEmerald),
                                      const SizedBox(width: 6),
                                      Text(
                                        _viewModel.formattedSubmittedSessionsDate,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _viewModel.submittedSessions.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'No submitted attendance sessions found for ${_viewModel.formattedSubmittedSessionsDate}.',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _viewModel.submittedSessions.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final session = _viewModel.submittedSessions[index];
                                    final adminChanges = session['adminChangesCount'] as int;

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _showSessionDetailsModal(session),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.border),
                                          ),
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
                                                      session['className'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.textMain,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Date: ${session['date']} · By: ${session['teacherName']}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Present: ${session['present']} · Absent: ${session['absent']} · Attendance: ${session['percentage'].toStringAsFixed(1)}%',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.textMain,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.lightEmerald,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      adminChanges > 0
                                                          ? '$adminChanges Admin Change(s)'
                                                          : 'Submitted',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.darkEmerald,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    color: AppColors.textSecondary,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
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
            fontSize: 16,
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

  Widget _buildToggleButton({
    required String studentId,
    required String label,
    required String statusValue,
    required Color activeColor,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: (_viewModel.isSaving || isDisabled)
          ? null
          : () => _viewModel.setStatus(studentId, statusValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SessionDetailsModalContent extends StatefulWidget {
  final Map<String, dynamic> initialSession;
  final AttendanceViewModel viewModel;

  const _SessionDetailsModalContent({
    required this.initialSession,
    required this.viewModel,
  });

  @override
  State<_SessionDetailsModalContent> createState() => _SessionDetailsModalContentState();
}

class _SessionDetailsModalContentState extends State<_SessionDetailsModalContent> {
  final StudentRepository _studentRepository = StudentRepository();
  Map<String, String> _studentNamesMap = {};
  String? _modalSuccessMessage;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    _loadStudentNames();
  }

  Future<void> _loadStudentNames() async {
    try {
      final students = await _studentRepository.getStudents();
      if (mounted) {
        setState(() {
          _studentNamesMap = {for (var s in students) s.studentId: s.name};
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showAdminChangeConfirmationDialog({
    required AttendanceModel attendance,
    required String newStatus,
    required String className,
    required Map<String, dynamic> session,
  }) {
    final reasonController = TextEditingController();
    final studentRealName = _studentNamesMap[attendance.studentId] ?? 'Student (${attendance.studentId})';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Change Attendance?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: $studentRealName', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain)),
              const SizedBox(height: 2),
              Text('Student ID: ${attendance.studentId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text('Class: $className · Date: ${attendance.date}'),
              const SizedBox(height: 12),
              Text('Current Status: ${attendance.status.toUpperCase()}'),
              Text('Change To: ${newStatus.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w700, color: newStatus == 'present' ? AppColors.success : AppColors.error)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for change (Optional)',
                  hintText: 'e.g. Student arrived late',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();

                final student = StudentModel(
                  studentId: attendance.studentId,
                  userId: '',
                  name: studentRealName,
                  phone: '',
                  parentName: '',
                  parentPhone: '',
                  classId: attendance.classId,
                  status: 'active',
                );

                final success = await widget.viewModel.changeStudentAttendanceByAdmin(
                  attendance: attendance,
                  newStatus: newStatus,
                  reason: reason,
                  student: student,
                  className: className,
                );

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();

                if (!mounted) return;
                if (success) {
                  final List<AttendanceModel> records =
                      List<AttendanceModel>.from(session['records'] as List);
                  final idx = records.indexWhere((r) => r.attendanceId == attendance.attendanceId);
                  if (idx != -1) {
                    records[idx] = attendance.copyWith(
                      status: newStatus.toLowerCase(),
                      isAdminChanged: true,
                      adminChangeReason: reason,
                    );
                  }
                  int p = records.where((r) => r.status.toLowerCase() == 'present').length;
                  int a = records.where((r) => r.status.toLowerCase() == 'absent').length;
                  int t = p + a;
                  session['present'] = p;
                  session['absent'] = a;
                  session['percentage'] = t > 0 ? (p / t) * 100 : 0.0;
                  session['adminChangesCount'] = records.where((r) => r.isAdminChanged).length;

                  setState(() {
                    _modalSuccessMessage = 'Attendance updated successfully.';
                  });
                } else if (widget.viewModel.errorMessage != null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.viewModel.errorMessage!),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  widget.viewModel.clearMessages();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Change'),
            ),
          ],
        );
      },
    );
  }

  void _showAuditHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final audits = widget.viewModel.sessionAudits;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text(
                'Attendance Change History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 16),
              audits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No change history found for this session.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: audits.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final audit = audits[index];
                          final realStudentName = _studentNamesMap[audit.studentId] ?? 'Student (${audit.studentId})';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(realStudentName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textMain)),
                                Text('Student ID: ${audit.studentId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('${audit.oldStatus.toUpperCase()} → ${audit.newStatus.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryEmerald)),
                                const SizedBox(height: 2),
                                Text('Changed by: ${audit.changedByName} (${audit.changedByRole})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Reason: "${audit.reason.isNotEmpty ? audit.reason : 'No reason provided'}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMain)),
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
  }

  @override
  Widget build(BuildContext context) {
    final sessionKey = widget.initialSession['key'] as String;
    final session = widget.viewModel.submittedSessions.firstWhere(
      (s) => s['key'] == sessionKey,
      orElse: () => widget.initialSession,
    );

    final List<AttendanceModel> records =
        List<AttendanceModel>.from(session['records'] as List);
    final String className = session['className'] as String;
    final String classId = session['classId'] as String;
    final String date = session['date'] as String;
    final String teacherName = session['teacherName'] as String;
    final int adminChanges = session['adminChangesCount'] as int;
    final int presentCount = session['present'] as int;
    final int absentCount = session['absent'] as int;
    final double percentage = session['percentage'] as double;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
              // Responsive header Row preventing overflow
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Date: $date · By: $teacherName\nPresent: $presentCount · Absent: $absentCount · ${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightEmerald,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      adminChanges > 0 ? '$adminChanges Admin Change(s)' : 'Submitted',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkEmerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Success Banner inside bottom sheet
              if (_modalSuccessMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightEmerald,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.darkEmerald, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _modalSuccessMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await widget.viewModel.loadSessionAudits(classId, date);
                      if (!context.mounted) return;
                      _showAuditHistoryModal();
                    },
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('View Change History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.textMain,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final att = records[index];
                    final bool isPres = att.status.toLowerCase() == 'present';
                    final studentRealName = _studentNamesMap[att.studentId] ?? 'Student (${att.studentId})';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isPres
                                ? AppColors.lightEmerald
                                : AppColors.error.withValues(alpha: 0.1),
                            child: Text(
                              studentRealName.isNotEmpty ? studentRealName[0] : 'S',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isPres
                                    ? AppColors.primaryEmerald
                                    : AppColors.error,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentRealName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                Text(
                                  'ID: ${att.studentId}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (att.isAdminChanged)
                                  Text(
                                    'Original: ${att.originalStatus.toUpperCase()} · Changed by Admin',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _buildAdminToggle(att, 'present', isPres, className, session),
                              const SizedBox(width: 6),
                              _buildAdminToggle(att, 'absent', !isPres, className, session),
                            ],
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
  }

  Widget _buildAdminToggle(
    AttendanceModel att,
    String targetStatus,
    bool isSelected,
    String className,
    Map<String, dynamic> session,
  ) {
    final bool isPres = targetStatus == 'present';
    final activeColor = isPres ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () {
        if (isSelected) return; // already in this status
        _showAdminChangeConfirmationDialog(
          attendance: att,
          newStatus: targetStatus,
          className: className,
          session: session,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          isPres ? 'Present' : 'Absent',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
