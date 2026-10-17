import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/mark_audit_model.dart';
import '../../../data/repositories/test_repository.dart';
import '../view_models/tests_view_model.dart';

class TestResultsScreen extends StatefulWidget {
  final TestItem testItem;

  const TestResultsScreen({super.key, required this.testItem});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final TestRepository _testRepository = TestRepository();
  Map<String, MarkAuditModel> _latestAuditsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  Future<void> _loadAudits() async {
    try {
      final audits = await _testRepository.getMarkAuditsForTest(
        widget.testItem.test.testId,
        classId: widget.testItem.test.classId,
      );
      final Map<String, MarkAuditModel> map = {};
      for (var a in audits) {
        map[a.studentId] = a;
      }
      if (mounted) {
        setState(() {
          _latestAuditsMap = map;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.testItem.test;
    final markMap = {for (var m in widget.testItem.marks) m.studentId: m};

    final rows = widget.testItem.studentsInClass.map((student) {
      final mark = markMap[student.studentId];
      final latestAudit = _latestAuditsMap[student.studentId];
      return TestResultRow(
        student: student,
        mark: mark,
        latestAudit: latestAudit,
        totalMarks: test.totalMarks,
        passingMarks: test.passingMarks,
      );
    }).toList();

    // Summary calculations
    final totalStudents = widget.testItem.totalStudents;
    final enteredRows = rows
        .where((r) => r.mark != null && (r.marksValue != null || r.isAbsent))
        .toList();
    final marksEnteredCount = enteredRows.length;
    final marksPendingCount = totalStudents - marksEnteredCount;

    final presentRows = enteredRows.where((r) => !r.isAbsent).toList();
    final absentCount = enteredRows.where((r) => r.isAbsent).length;

    final passedRows = presentRows.where((r) => r.result == 'Pass').toList();
    final failedRows = presentRows.where((r) => r.result == 'Fail').toList();

    double totalMarksSum = 0;
    for (var r in presentRows) {
      if (r.marksValue != null) {
        totalMarksSum += r.marksValue!;
      }
    }
    final avgMarks =
        presentRows.isNotEmpty ? (totalMarksSum / presentRows.length) : 0.0;

    double totalPercentageSum = 0;
    for (var r in presentRows) {
      totalPercentageSum += r.percentage;
    }
    final avgPercentage =
        presentRows.isNotEmpty ? (totalPercentageSum / presentRows.length) : 0.0;

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
        title: Text(
          'Results: ${test.testName}',
          style: const TextStyle(
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              test.testName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.lightEmerald,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                test.subject,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Class: ${widget.testItem.classModel != null ? widget.testItem.classModel!.className : 'N/A'} • Date: ${test.testDate} • Total Marks: ${test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${test.passingMarks != null ? ' • Passing: ${test.passingMarks!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Statistics Grid
                  const Text(
                    'Performance Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric(
                                  'Total', '$totalStudents', AppColors.textMain),
                            ),
                            Expanded(
                              child: _buildSummaryMetric('Entered',
                                  '$marksEnteredCount', AppColors.success),
                            ),
                            Expanded(
                              child: _buildSummaryMetric('Pending',
                                  '$marksPendingCount', AppColors.warning),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric('Present',
                                  '${presentRows.length}', AppColors.textMain),
                            ),
                            Expanded(
                              child: _buildSummaryMetric(
                                  'Absent', '$absentCount', AppColors.error),
                            ),
                            Expanded(
                              child: _buildSummaryMetric('Passed',
                                  '${passedRows.length}', AppColors.success),
                            ),
                            Expanded(
                              child: _buildSummaryMetric('Failed',
                                  '${failedRows.length}', AppColors.error),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetric(
                                  'Average Marks',
                                  presentRows.isNotEmpty
                                      ? '${avgMarks.toStringAsFixed(1)} / ${test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}'
                                      : '--',
                                  AppColors.primaryEmerald),
                            ),
                            Expanded(
                              child: _buildSummaryMetric(
                                  'Average %',
                                  presentRows.isNotEmpty
                                      ? '${avgPercentage.toStringAsFixed(1)}%'
                                      : '--',
                                  AppColors.primaryEmerald),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student Results List
                  const Text(
                    'Student Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  rows.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'No student results found.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rows.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _buildResultCard(row);
                          },
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

  Widget _buildSummaryMetric(String label, String value, Color color) {
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

  Widget _buildResultCard(TestResultRow row) {
    Color resultColor = AppColors.success;
    if (row.result == 'Fail') {
      resultColor = AppColors.error;
    } else if (row.result == 'Absent' || row.result == 'Pending') {
      resultColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.student.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${row.student.studentId} • Marks: ${row.marksDisplay}',
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
                  if (!row.isAbsent && row.marksValue != null) ...[
                    Text(
                      row.percentageDisplay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      row.result,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: resultColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (row.remarks != null && row.remarks!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Remark: "${row.remarks!.trim()}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textMain,
              ),
            ),
          ],
          if (row.latestAudit != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last updated by: ${row.latestAudit!.editedByName} (${row.latestAudit!.editedByRole.toUpperCase()})',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
