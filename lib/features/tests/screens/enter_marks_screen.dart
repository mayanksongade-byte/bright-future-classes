import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/tests_view_model.dart';

class EnterMarksScreen extends StatefulWidget {
  final TestItem testItem;

  const EnterMarksScreen({super.key, required this.testItem});

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  late final TestsViewModel _viewModel;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, bool> _absentMap = {};

  @override
  void initState() {
    super.initState();
    _viewModel = TestsViewModel();
    _viewModel.addListener(_onViewModelChange);

    final markMap = {for (var m in widget.testItem.marks) m.studentId: m};

    for (var student in widget.testItem.studentsInClass) {
      final existingMark = markMap[student.studentId];
      final isAbs = existingMark?.isAbsent ?? false;
      _absentMap[student.studentId] = isAbs;

      String initialVal = '';
      if (!isAbs && existingMark?.marks != null) {
        initialVal = existingMark!.marks!
            .toStringAsFixed(1)
            .replaceAll(RegExp(r'\.0$'), '');
      }
      _controllers[student.studentId] = TextEditingController(text: initialVal);
      _remarksControllers[student.studentId] =
          TextEditingController(text: existingMark?.remarks ?? '');
    }
  }

  bool get _isFutureExamDate {
    final testDate = widget.testItem.test.testDate.trim();
    if (testDate.isEmpty) return false;
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return testDate.compareTo(todayStr) > 0;
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
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveMarks() async {
    if (_viewModel.isSaving || _isFutureExamDate) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirestoreService().getUserDocument(user.uid);
    final userRole = (userDoc?['role'] as String? ?? 'teacher').toLowerCase();
    final userName = userDoc?['name'] as String? ?? user.displayName ?? 'Teacher';

    final marksInputMap = <String, String>{};
    for (var entry in _controllers.entries) {
      marksInputMap[entry.key] = entry.value.text;
    }

    final remarksInputMap = <String, String>{};
    for (var entry in _remarksControllers.entries) {
      remarksInputMap[entry.key] = entry.value.text;
    }

    final studentNameMap = <String, String>{
      for (var s in widget.testItem.studentsInClass) s.studentId: s.name
    };

    final success = await _viewModel.saveStudentMarks(
      test: widget.testItem.test,
      marksInputMap: marksInputMap,
      absentMap: _absentMap,
      remarksInputMap: remarksInputMap,
      studentNameMap: studentNameMap,
      currentUserId: user.uid,
      currentUserName: userName,
      currentUserRole: userRole,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marks saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.testItem.test;
    final students = widget.testItem.studentsInClass;

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
          'Enter Marks: ${test.testName}',
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
        child: students.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No students found in this class.',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isFutureExamDate) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock_outlined, color: AppColors.textMain, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Marks entry available on ${test.testDate}.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Info banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    test.subject,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total Marks: ${test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.lightEmerald,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Students: ${students.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkEmerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Student Marks & Remarks Entry',
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
                          itemCount: students.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final controller = _controllers[student.studentId]!;
                            final remarksController = _remarksControllers[student.studentId]!;
                            final isAbsent =
                                _absentMap[student.studentId] ?? false;

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
                                      const SizedBox(width: 12),
                                      Row(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: isAbsent,
                                                activeColor: AppColors.error,
                                                onChanged: _isFutureExamDate
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          _absentMap[student.studentId] =
                                                              val ?? false;
                                                          if (val == true) {
                                                            controller.clear();
                                                          }
                                                        });
                                                      },
                                              ),
                                              const Text(
                                                'Absent',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 80,
                                            child: TextField(
                                              controller: controller,
                                              enabled: !_isFutureExamDate && !isAbsent,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              style: AppTextStyles.inputText,
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                hintText: 'Marks',
                                                hintStyle: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary),
                                                filled: true,
                                                fillColor: isAbsent || _isFutureExamDate
                                                    ? AppColors.background
                                                    : AppColors.background,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 10),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color: AppColors.border),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  borderSide: const BorderSide(
                                                      color:
                                                          AppColors.primaryEmerald,
                                                      width: 1.5),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: remarksController,
                                    enabled: !_isFutureExamDate && !isAbsent,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMain),
                                    decoration: InputDecoration(
                                      hintText: 'Add remark for ${student.name} (optional)',
                                      hintStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      filled: true,
                                      fillColor: AppColors.background,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        PrimaryButton(
                          text: _isFutureExamDate ? 'Marks Entry Available on ${test.testDate}' : 'Save Marks & Remarks',
                          isLoading: _viewModel.isSaving,
                          onPressed: (_isFutureExamDate || _viewModel.isSaving) ? null : _saveMarks,
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
}
