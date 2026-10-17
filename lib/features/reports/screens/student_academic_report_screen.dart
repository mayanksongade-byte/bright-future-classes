import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_academic_result.dart';
import '../../../data/models/student_model.dart';

class StudentAcademicReportScreen extends StatelessWidget {
  final StudentModel student;
  final ClassModel? classModel;
  final List<StudentAcademicResult> results;

  const StudentAcademicReportScreen({
    super.key,
    required this.student,
    this.classModel,
    required this.results,
  });

  void _shareReportSummary(BuildContext context, StudentAcademicSummary summary) {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('  BRIGHT FUTURE CLASSES - ACADEMIC REPORT');
    buffer.writeln('========================================');
    buffer.writeln('Student Name: ${student.name}');
    buffer.writeln('Student ID  : ${student.studentId}');
    buffer.writeln('Class       : ${classModel?.className ?? "N/A"}');
    buffer.writeln('Date        : ${DateTime.now().toString().substring(0, 10)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('OVERALL SUMMARY:');
    buffer.writeln('• Completed Assessments: ${summary.completedCount} / ${summary.totalTests}');
    buffer.writeln('• Overall Average Marks : ${summary.overallAveragePercentage.toStringAsFixed(1)}%');
    buffer.writeln('• Pass Count            : ${summary.passCount}');
    buffer.writeln('• Fail Count            : ${summary.failCount}');
    buffer.writeln('• Pending Marks         : ${summary.pendingCount}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('SUBJECT PERFORMANCE SUMMARY:');
    for (var sub in summary.subjectSummaries) {
      buffer.writeln('• ${sub.subjectName}: ${sub.subjectAveragePercentage.toStringAsFixed(1)}% (${sub.passCount} Pass, ${sub.failCount} Fail, ${sub.pendingCount} Pending)');
    }
    buffer.writeln('========================================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Academic report summary copied to clipboard.'),
        backgroundColor: AppColors.primaryEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = StudentAcademicSummary(allResults: results);
    final subjectSummaries = summary.subjectSummaries;

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
          'Academic Progress Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: AppColors.primaryEmerald),
            onPressed: () => _shareReportSummary(context, summary),
            tooltip: 'Copy Report Summary',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. OFFICIAL INSTITUTION & STUDENT HEADER
                  Container(
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
                                color: AppColors.lightEmerald,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school_rounded, color: AppColors.primaryEmerald, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bright Future Classes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  Text(
                                    'Student Official Academic Progress Report',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _buildHeaderInfoRow('Student Name', student.name)),
                            Expanded(child: _buildHeaderInfoRow('Student ID', student.studentId)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildHeaderInfoRow('Class', classModel?.className ?? 'N/A')),
                            Expanded(child: _buildHeaderInfoRow('Report Date', AppDateFormatter.todayDisplay())),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. OVERALL ACADEMIC METRICS SUMMARY
                  const Text(
                    'Overall Performance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 450;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: isNarrow ? 1.05 : 1.45,
                        children: [
                          _buildReportStatCard('Completed Tests', '${summary.completedCount} / ${summary.totalTests}', Icons.assignment_turned_in_outlined, AppColors.primaryEmerald, AppColors.lightEmerald),
                          _buildReportStatCard('Weighted Avg', '${summary.overallAveragePercentage.toStringAsFixed(1)}%', Icons.analytics_outlined, AppColors.info, const Color(0xFFE0F2FE)),
                          _buildReportStatCard('Pass / Fail', '${summary.passCount} P · ${summary.failCount} F', Icons.check_circle_outline_rounded, summary.failCount == 0 ? AppColors.success : AppColors.warning, const Color(0xFFDCFCE7)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 3. SUBJECT-WISE SUMMARY TABLE
                  const Text(
                    'Subject-Wise Performance Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(1.1),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.3),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: AppColors.background),
                            children: [
                              _buildTableHeaderCell('Subject'),
                              _buildTableHeaderCell('Tests'),
                              _buildTableHeaderCell('Avg %'),
                              _buildTableHeaderCell('Pass / Fail'),
                            ],
                          ),
                          ...subjectSummaries.map((sub) {
                            return TableRow(
                              children: [
                                _buildTableCell(sub.subjectName, isBold: true),
                                _buildTableCell('${sub.completedCount}/${sub.totalTests}'),
                                _buildTableCell('${sub.subjectAveragePercentage.toStringAsFixed(1)}%'),
                                _buildTableCell('${sub.passCount} P / ${sub.failCount} F'),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. DETAILED ASSESSMENT HISTORY GROUPED BY SUBJECT
                  const Text(
                    'Detailed Assessment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjectSummaries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final sub = subjectSummaries[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sub.subjectName,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                  ),
                                  Text(
                                    'Subject Avg: ${sub.subjectAveragePercentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryEmerald),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sub.results.length,
                              separatorBuilder: (context, idx) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (context, idx) {
                                final res = sub.results[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    res.test.testName,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                                  ),
                                                ),
                                                if (res.isArchived) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.background,
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.border),
                                                    ),
                                                    child: const Text('Archived', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text('Date: ${AppDateFormatter.formatDate(res.test.testDate)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(res.marksDisplay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                                          const SizedBox(height: 2),
                                          Text(
                                            res.hasMarksValue ? '${res.percentageDisplay} • ${res.status}' : res.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: res.status == 'Pass' ? AppColors.darkEmerald : (res.status == 'Fail' ? AppColors.error : AppColors.warning),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
      ],
    );
  }

  Widget _buildReportStatCard(String label, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMain),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}
