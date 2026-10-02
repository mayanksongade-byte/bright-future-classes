import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../attendance/screens/admin_attendance_screen.dart';
import '../view_models/reports_view_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.fetchReportsData();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Reports & Analytics',
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
                onRefresh: _viewModel.fetchReportsData,
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
                          // Section Selector Tabs / Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                'Overview',
                                'Students',
                                'Attendance',
                                'Fees',
                                'Tests & Marks',
                                'Homework',
                                'Complaints'
                              ].map((section) {
                                final isSelected =
                                    _viewModel.selectedSection == section;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(section),
                                    selected: isSelected,
                                    selectedColor: AppColors.primaryEmerald,
                                    backgroundColor: AppColors.surface,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textMain,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected
                                            ? AppColors.primaryEmerald
                                            : AppColors.border,
                                      ),
                                    ),
                                    onSelected: (_) =>
                                        _viewModel.setSelectedSection(section),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Render Active Section
                          _buildActiveSectionContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActiveSectionContent() {
    switch (_viewModel.selectedSection) {
      case 'Students':
        return _buildStudentsReport();
      case 'Attendance':
        return _buildAttendanceReport();
      case 'Fees':
        return _buildFeesReport();
      case 'Tests & Marks':
        return _buildTestsReport();
      case 'Homework':
        return _buildHomeworkReport();
      case 'Complaints':
        return _buildComplaintsReport();
      case 'Overview':
      default:
        return _buildOverviewReport();
    }
  }

  // --- 1. OVERVIEW SECTION ---
  Widget _buildOverviewReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Live summary metrics across all tuition modules',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 16),
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
                _buildStatCard('Total Students', '${_viewModel.totalStudents}', Icons.people_outline_rounded, AppColors.primaryEmerald, AppColors.lightEmerald),
                _buildStatCard('Total Teachers', '${_viewModel.totalTeachers}', Icons.badge_outlined, AppColors.teacherAccent, const Color(0xFFF3E8FF)),
                _buildStatCard('Total Classes', '${_viewModel.totalClasses}', Icons.school_outlined, AppColors.info, const Color(0xFFE0F2FE)),
                _buildStatCard('Pending Fees', _viewModel.pendingFeesStr, Icons.account_balance_wallet_outlined, AppColors.warning, const Color(0xFFFEF3C7)),
                _buildStatCard('Attendance %', '${_viewModel.overallAttendancePercentage.toStringAsFixed(1)}%', Icons.calendar_today_rounded, AppColors.success, const Color(0xFFDCFCE7)),
                _buildStatCard('Total Tests', '${_viewModel.totalTests}', Icons.quiz_outlined, AppColors.primaryEmerald, AppColors.lightEmerald),
                _buildStatCard('Open Complaints', '${_viewModel.openComplaints}', Icons.report_gmailerrorred_rounded, AppColors.error, const Color(0xFFFEE2E2)),
                _buildStatCard('Total Homework', '${_viewModel.totalHomework}', Icons.assignment_outlined, AppColors.info, const Color(0xFFE0F2FE)),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- 2. STUDENTS REPORT SECTION ---
  Widget _buildStudentsReport() {
    final classCounts = _viewModel.classWiseStudentCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Analytics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Total Students', '${_viewModel.totalStudents}', AppColors.primaryEmerald)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Active', '${_viewModel.activeStudentsCount}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Inactive', '${_viewModel.inactiveStudentsCount}', AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Class-wise Distribution',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 12),
        classCounts.isEmpty
            ? const Text('No classes available.', style: TextStyle(color: AppColors.textSecondary))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: classCounts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = classCounts.entries.elementAt(index);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value} Students',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryEmerald),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- 3. ATTENDANCE REPORT SECTION ---
  Widget _buildAttendanceReport() {
    final classAttendance = _viewModel.classWiseAttendanceMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attendance Analytics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminAttendanceScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Detailed Report'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Present', '${_viewModel.attendancePresentCount}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Absent', '${_viewModel.attendanceAbsentCount}', AppColors.error)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Rate', '${_viewModel.filteredAttendancePercentage.toStringAsFixed(1)}%', AppColors.primaryEmerald)),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Class-wise Attendance Breakdown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 12),
        classAttendance.isEmpty
            ? const Text('No attendance records available.', style: TextStyle(color: AppColors.textSecondary))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: classAttendance.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = classAttendance.entries.elementAt(index);
                  final present = entry.value['present'] ?? 0;
                  final absent = entry.value['absent'] ?? 0;
                  final total = present + absent;
                  final rate = total > 0 ? (present / total) * 100 : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMain)),
                        Row(
                          children: [
                            Text('Present: $present', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Text('Absent: $absent', style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            Text('${rate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.primaryEmerald, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- 4. FEES REPORT SECTION ---
  Widget _buildFeesReport() {
    final feesReport = _viewModel.classWiseFeesReport;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fees & Collection Analytics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Payable', '₹${_viewModel.totalPayable.toStringAsFixed(0)}', AppColors.primaryEmerald)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('Paid', '₹${_viewModel.totalPaid.toStringAsFixed(0)}', AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('Pending', '₹${_viewModel.totalPendingFees.toStringAsFixed(0)}', AppColors.warning)),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _viewModel.filterAcademicYear,
                isExpanded: true,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Academic Year',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Years')),
                  DropdownMenuItem(value: '2025-26', child: Text('2025-26')),
                  DropdownMenuItem(value: '2026-27', child: Text('2026-27')),
                ],
                onChanged: (val) {
                  if (val != null) _viewModel.setFilterAcademicYear(val);
                },
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _viewModel.filterFeeStatus,
                isExpanded: true,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Fee Status',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Status')),
                  DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'Partially Paid', child: Text('Partially Paid')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                ],
                onChanged: (val) {
                  if (val != null) _viewModel.setFilterFeeStatus(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Class-wise Fee Breakdown',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 12),
        feesReport.isEmpty
            ? const Text('No fee records available.', style: TextStyle(color: AppColors.textSecondary))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: feesReport.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = feesReport[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['className'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textMain)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item['status'] == 'Paid' ? AppColors.lightEmerald : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(item['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: item['status'] == 'Paid' ? AppColors.darkEmerald : AppColors.warning)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Students: ${item['studentCount']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('Payable: ₹${item['payable'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textMain)),
                            Text('Paid: ₹${item['paid'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                            Text('Pending: ₹${item['pending'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- 5. TESTS & MARKS REPORT SECTION ---
  Widget _buildTestsReport() {
    final summary = _viewModel.testMarksSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tests & Academic Performance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Total Tests', '${summary['totalTests']}', AppColors.primaryEmerald)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Passed', '${summary['passed']}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Failed', '${summary['failed']}', AppColors.error)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Absent', '${summary['absent']}', AppColors.warning)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Avg Marks', (summary['avgMarks'] as double).toStringAsFixed(1), AppColors.info)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Avg %', '${(summary['avgPercentage'] as double).toStringAsFixed(1)}%', AppColors.primaryEmerald)),
          ],
        ),
      ],
    );
  }

  // --- 6. HOMEWORK REPORT SECTION ---
  Widget _buildHomeworkReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Homework Analytics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Total Homework', '${_viewModel.totalHomeworkCount}', AppColors.primaryEmerald)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Active', '${_viewModel.activeHomeworkCount}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Completed', '${_viewModel.completedHomeworkCount}', AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  // --- 7. COMPLAINT REPORT SECTION ---
  Widget _buildComplaintsReport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complaint Analytics',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Total', '${_viewModel.totalComplaintsCount}', AppColors.primaryEmerald)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('Open', '${_viewModel.openComplaintsCount}', AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryBox('In Review', '${_viewModel.inReviewComplaintsCount}', AppColors.info)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryBox('Resolved', '${_viewModel.resolvedComplaintsCount}', AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryBox('Closed', '${_viewModel.closedComplaintsCount}', AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
    );
  }

  Widget _buildSummaryBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
