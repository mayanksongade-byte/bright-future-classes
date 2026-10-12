import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/repositories/holiday_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../view_models/attendance_view_model.dart';

class StudentAttendanceScreen extends StatefulWidget {
  final String studentId;

  const StudentAttendanceScreen({super.key, required this.studentId});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  late final StudentAttendanceViewModel _viewModel;
  final HolidayRepository _holidayRepository = HolidayRepository();
  final StudentRepository _studentRepository = StudentRepository();
  List<HolidayModel> _holidays = [];
  String? _studentClassId;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = StudentAttendanceViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.loadStudentAttendance(widget.studentId);
    _loadStudentDetailsAndHolidays();
  }

  Future<void> _loadStudentDetailsAndHolidays() async {
    try {
      final students = await _studentRepository.getStudents();
      final match = students.firstWhere(
        (s) => s.studentId == widget.studentId || s.studentId.trim().toUpperCase() == widget.studentId.trim().toUpperCase(),
        orElse: () => students.isNotEmpty ? students.first : throw Exception('No student'),
      );
      if (mounted) {
        setState(() {
          _studentClassId = match.classId;
        });
      }
    } catch (_) {}

    try {
      final list = await _holidayRepository.getHolidays();
      if (mounted) {
        setState(() {
          _holidays = list;
        });
      }
    } catch (_) {}
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

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatDisplayDate(DateTime d) {
    final dayName = _weekdays[(d.weekday - 1) % 7];
    final monthName = _months[d.month - 1];
    return '$dayName, ${d.day.toString().padLeft(2, '0')} $monthName ${d.year}';
  }

  HolidayModel? _getHolidayForDate(String dateKey) {
    for (var h in _holidays) {
      if (h.includesDate(dateKey) && h.appliesToClass(_studentClassId)) {
        return h;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Build map of dateStr (yyyy-MM-dd) -> AttendanceModel
    final Map<String, AttendanceModel> attendanceMap = {};
    for (var att in _viewModel.attendanceHistory) {
      final key = att.date.trim();
      if (key.isNotEmpty) {
        attendanceMap[key] = att;
      }
    }

    // Monthly stats calculation
    int monthPresent = 0;
    int monthAbsent = 0;
    int monthHolidays = 0;
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      final key = _formatDateKey(DateTime(_focusedMonth.year, _focusedMonth.month, day));
      final holiday = _getHolidayForDate(key);
      if (holiday != null) {
        monthHolidays++;
      } else if (attendanceMap.containsKey(key)) {
        final status = attendanceMap[key]!.status.toLowerCase();
        if (status == 'present') {
          monthPresent++;
        } else if (status == 'absent') {
          monthAbsent++;
        }
      }
    }
    final int monthTotal = monthPresent + monthAbsent;
    final double monthPercentage = monthTotal > 0 ? (monthPresent / monthTotal) * 100.0 : 0.0;

    // Selected date details
    final selectedKey = _formatDateKey(_selectedDate);
    final AttendanceModel? selectedRecord = attendanceMap[selectedKey];
    final HolidayModel? selectedHoliday = _getHolidayForDate(selectedKey);
    final bool isFutureDate = _selectedDate.isAfter(DateTime.now());

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
          'My Attendance',
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
            : RefreshIndicator(
                onRefresh: () async {
                  await _viewModel.loadStudentAttendance(widget.studentId);
                  await _loadStudentDetailsAndHolidays();
                },
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. ALL-TIME SUMMARY CARD
                          _buildAllTimeSummaryCard(),
                          const SizedBox(height: 24),

                          // 2. MONTHLY CALENDAR HEADER & CONTROLS
                          _buildCalendarHeader(),
                          const SizedBox(height: 16),

                          // 3. MONTHLY SUMMARY ROW
                          _buildMonthlySummaryRow(monthPresent, monthAbsent, monthHolidays, monthPercentage),
                          const SizedBox(height: 16),

                          // 4. MONTHLY CALENDAR GRID
                          _buildCalendarGrid(attendanceMap),
                          const SizedBox(height: 16),

                          // 5. ACCESSIBLE LEGEND
                          _buildLegend(),
                          const SizedBox(height: 20),

                          // 6. SELECTED DATE DETAIL CARD
                          _buildSelectedDateCard(selectedRecord, selectedHoliday, isFutureDate),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAllTimeSummaryCard() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                '${_viewModel.attendancePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Total Days',
                  value: '${_viewModel.totalClasses}',
                  color: AppColors.textMain,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  label: 'Present',
                  value: '${_viewModel.presentCount}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  label: 'Absent',
                  value: '${_viewModel.absentCount}',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthName = _months[_focusedMonth.month - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName ${_focusedMonth.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const Text(
              'Monthly Attendance Calendar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.primaryEmerald),
              label: const Text('Today', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.w600, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textMain),
              onPressed: _prevMonth,
              tooltip: 'Previous Month',
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textMain),
              onPressed: _nextMonth,
              tooltip: 'Next Month',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlySummaryRow(int present, int absent, int holidays, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Present', '$present Days', AppColors.success),
          Container(width: 1, height: 20, color: AppColors.border),
          _buildSummaryItem('Absent', '$absent Days', AppColors.error),
          Container(width: 1, height: 20, color: AppColors.border),
          _buildSummaryItem('Holidays', '$holidays Days', AppColors.textSecondary),
          Container(width: 1, height: 20, color: AppColors.border),
          _buildSummaryItem('Monthly Rate', '${percentage.toStringAsFixed(1)}%', AppColors.primaryEmerald),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<String, AttendanceModel> attendanceMap) {
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int leadingEmptySlots = (firstDayOfMonth.weekday - 1) % 7; // Monday = 1 -> 0 slots
    final int totalGridCells = leadingEmptySlots + daysInMonth;

    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Weekday Labels (Monday-first)
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // 7-Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: totalGridCells,
            itemBuilder: (context, index) {
              if (index < leadingEmptySlots) {
                return const SizedBox.shrink(); // Empty slot before 1st day
              }

              final int dayNumber = index - leadingEmptySlots + 1;
              final DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final String dateKey = _formatDateKey(cellDate);

              final bool isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final bool isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;

              final HolidayModel? holiday = _getHolidayForDate(dateKey);
              final AttendanceModel? record = attendanceMap[dateKey];
              final String? status = record?.status.toLowerCase();

              Color bgColor = AppColors.background;
              Color borderColor = AppColors.border;
              Color textColor = AppColors.textMain;
              String labelText = '$dayNumber';
              String statusBadgeText = '';

              if (holiday != null) {
                bgColor = AppColors.border.withValues(alpha: 0.3);
                borderColor = AppColors.textSecondary.withValues(alpha: 0.4);
                textColor = AppColors.textMain;
                statusBadgeText = 'H';
              } else if (status == 'present') {
                bgColor = AppColors.lightEmerald;
                borderColor = AppColors.primaryEmerald;
                textColor = AppColors.darkEmerald;
                statusBadgeText = 'P';
              } else if (status == 'absent') {
                bgColor = const Color(0xFFFEE2E2);
                borderColor = AppColors.error;
                textColor = AppColors.error;
                statusBadgeText = 'A';
              } else if (cellDate.isAfter(today)) {
                textColor = AppColors.textSecondary.withValues(alpha: 0.5);
              }

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : (isToday ? AppColors.darkEmerald : borderColor),
                      width: isSelected ? 2.0 : (isToday ? 1.5 : 1.0),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labelText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (statusBadgeText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: holiday != null
                                    ? AppColors.textSecondary
                                    : (status == 'present'
                                        ? AppColors.primaryEmerald
                                        : AppColors.error),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusBadgeText,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isToday)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('P', 'Present', AppColors.primaryEmerald, AppColors.lightEmerald),
          _buildLegendItem('A', 'Absent', AppColors.error, const Color(0xFFFEE2E2)),
          _buildLegendItem('H', 'Holiday', AppColors.textSecondary, AppColors.border.withValues(alpha: 0.3)),
          _buildLegendItem('-', 'Not Marked', AppColors.textSecondary, AppColors.background),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String code, String label, Color color, Color bg) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.0),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
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
    );
  }

  Widget _buildSelectedDateCard(AttendanceModel? record, HolidayModel? holiday, bool isFutureDate) {
    String statusTitle = 'Not Marked';
    Color statusColor = AppColors.textSecondary;
    Color statusBg = AppColors.background;
    IconData statusIcon = Icons.help_outline_rounded;

    if (holiday != null) {
      statusTitle = 'Official Holiday (${holiday.type})';
      statusColor = AppColors.textMain;
      statusBg = AppColors.border.withValues(alpha: 0.3);
      statusIcon = Icons.event_available_rounded;
    } else if (isFutureDate) {
      statusTitle = 'Upcoming Date';
      statusColor = AppColors.textSecondary;
      statusBg = AppColors.background;
      statusIcon = Icons.event_rounded;
    } else if (record != null) {
      final s = record.status.toLowerCase();
      if (s == 'present') {
        statusTitle = 'Present';
        statusColor = AppColors.darkEmerald;
        statusBg = AppColors.lightEmerald;
        statusIcon = Icons.check_circle_outline_rounded;
      } else if (s == 'absent') {
        statusTitle = 'Absent';
        statusColor = AppColors.error;
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.highlight_off_rounded;
      }
    }

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holiday != null ? holiday.title : 'Selected Date Details',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (holiday != null && holiday.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            Text(
              'Holiday Note: ${holiday.note}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (record != null && record.isAdminChanged) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Updated by Admin (Original: ${record.originalStatus.toUpperCase()})${record.adminChangeReason != null && record.adminChangeReason!.isNotEmpty ? " · Reason: \"${record.adminChangeReason}\"" : ""}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric({
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
}
