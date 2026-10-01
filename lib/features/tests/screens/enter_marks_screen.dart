import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
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
            .toStringAsFixed(0)
            .replaceAll(RegExp(r'\.0$'), '');
      }
      _controllers[student.studentId] = TextEditingController(text: initialVal);
    }
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
    super.dispose();
  }

  Future<void> _saveMarks() async {
    if (_viewModel.isSaving) return;

    final marksInputMap = <String, String>{};
    for (var entry in _controllers.entries) {
      marksInputMap[entry.key] = entry.value.text;
    }

    final success = await _viewModel.saveStudentMarks(
      test: widget.testItem.test,
      marksInputMap: marksInputMap,
      absentMap: _absentMap,
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
                                    'Total Marks: ${test.totalMarks.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '')}',
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
                          'Student Marks Entry',
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
                            final isAbsent =
                                _absentMap[student.studentId] ?? false;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
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
                                            onChanged: (val) {
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
                                          enabled: !isAbsent,
                                          keyboardType: TextInputType.number,
                                          style: AppTextStyles.inputText,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: 'Marks',
                                            hintStyle: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    AppColors.textSecondary),
                                            filled: true,
                                            fillColor: isAbsent
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
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        PrimaryButton(
                          text: 'Save Marks',
                          isLoading: _viewModel.isSaving,
                          onPressed: _viewModel.isSaving ? null : _saveMarks,
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
