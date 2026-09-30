import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../view_models/attendance_reports_view_model.dart';

class AttendanceReportScreen extends StatefulWidget {
  final ClassModel? initialClass;

  const AttendanceReportScreen({super.key, this.initialClass});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  late final AttendanceReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AttendanceReportsViewModel(initialClass: widget.initialClass);
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadReportData();
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
      _viewModel.selectDate(picked);
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
          'Attendance Reports',
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
        child: _viewModel.isLoading
            ? const Center(child: AppLoadingIndicator())
            : _viewModel.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _viewModel.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _viewModel.loadReportData,
                    color: AppColors.primaryEmerald,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filters Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Report Filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                        ToggleButtons(
                                          isSelected: [
                                            !_viewModel.isMonthly,
                                            _viewModel.isMonthly
                                          ],
                                          onPressed: (index) {
                                            _viewModel.setMode(index == 1);
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          selectedColor: Colors.white,
                                          fillColor:
                                              AppColors.primaryEmerald,
                                          color: AppColors.textSecondary,
                                          constraints: const BoxConstraints(
                                              minHeight: 32, minWidth: 70),
                                          children: const [
                                            Text('Daily',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text('Monthly',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Class',
                                                  style: AppTextStyles
                                                      .inputLabel),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<
                                                  ClassModel?>(
                                                initialValue:
                                                    _viewModel.selectedClass,
                                                style:
                                                    AppTextStyles.inputText,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      AppColors.background,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 12),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: AppColors
                                                                .border),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: AppColors
                                                                .primaryEmerald,
                                                            width: 1.5),
                                                  ),
                                                ),
                                                items: [
                                                  const DropdownMenuItem<
                                                      ClassModel?>(
                                                    value: null,
                                                    child:
                                                        Text('All Classes'),
                                                  ),
                                                  ..._viewModel.classes
                                                      .map((cls) {
                                                    return DropdownMenuItem<
                                                        ClassModel?>(
                                                      value: cls,
                                                      child:
                                                          Text(cls.className),
                                                    );
                                                  }),
                                                ],
                                                onChanged: (cls) => _viewModel
                                                    .selectClass(cls),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  _viewModel.isMonthly
                                                      ? 'Month'
                                                      : 'Date',
                                                  style: AppTextStyles
                                                      .inputLabel),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: _viewModel.isMonthly
                                                    ? null
                                                    : _selectDate,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 14),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .background,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: AppColors
                                                            .border),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        _viewModel.isMonthly
                                                            ? '${_viewModel.selectedMonth.year}-${_viewModel.selectedMonth.month.toString().padLeft(2, '0')}'
                                                            : _viewModel
                                                                .dateQueryString,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textMain,
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 16,
                                                        color: AppColors
                                                            .textSecondary,
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
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Overall Summary Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryMetric(
                                        label: 'Students',
                                        value:
                                            '${_viewModel.totalStudentsSummary}',
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: AppColors.border),
                                    Expanded(
                                      child: _buildSummaryMetric(
                                        label: 'Present',
                                        value: '${_viewModel.presentSummary}',
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: AppColors.border),
                                    Expanded(
                                      child: _buildSummaryMetric(
                                        label: 'Absent',
                                        value: '${_viewModel.absentSummary}',
                                        color: AppColors.error,
                                      ),
                                    ),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: AppColors.border),
                                    Expanded(
                                      child: _buildSummaryMetric(
                                        label: 'Attendance',
                                        value:
                                            '${_viewModel.overallAttendancePercentage.toStringAsFixed(1)}%',
                                        color: AppColors.primaryEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Class-wise Report Section
                              const Text(
                                'Class-wise Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _viewModel.classReports.isEmpty
                                  ? _buildEmptyBox(
                                      'No attendance records found for the selected period.')
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          _viewModel.classReports.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final item =
                                            _viewModel.classReports[index];
                                        return _buildClassReportCard(item);
                                      },
                                    ),
                              const SizedBox(height: 28),

                              // Low Attendance Section (< 75%)
                              const Text(
                                'Low Attendance (< 75%)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _viewModel.lowAttendanceStudents.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.border),
                                      ),
                                      child: const Text(
                                        'No students with attendance below 75%.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _viewModel
                                          .lowAttendanceStudents.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final item = _viewModel
                                            .lowAttendanceStudents[index];
                                        return _buildStudentReportCard(
                                            item, true);
                                      },
                                    ),
                              const SizedBox(height: 28),

                              // Student-wise Report Section
                              const Text(
                                'Student-wise Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _viewModel.studentReports.isEmpty
                                  ? _buildEmptyBox(
                                      'No student attendance records found.')
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          _viewModel.studentReports.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final item =
                                            _viewModel.studentReports[index];
                                        return _buildStudentReportCard(
                                            item, false);
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

  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildClassReportCard(ClassReportItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.classModel.className,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Students: ${item.totalStudents} • Present: ${item.presentCount} • Absent: ${item.absentCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightEmerald,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${item.attendancePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentReportCard(StudentReportItem item, bool isLow) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLow
                ? AppColors.error.withValues(alpha: 0.5)
                : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${item.student.studentId} • Present: ${item.presentDays} • Absent: ${item.absentDays} • Total: ${item.totalMarkedDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLow ? const Color(0xFFFEE2E2) : AppColors.lightEmerald,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${item.attendancePercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isLow ? AppColors.error : AppColors.darkEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
