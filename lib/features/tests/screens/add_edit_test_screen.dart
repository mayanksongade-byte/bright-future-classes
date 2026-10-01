import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/test_model.dart';
import '../view_models/tests_view_model.dart';

class AddEditTestScreen extends StatefulWidget {
  final TestModel? testToEdit;
  final List<ClassModel>? preloadedClasses;

  const AddEditTestScreen({
    super.key,
    this.testToEdit,
    this.preloadedClasses,
  });

  @override
  State<AddEditTestScreen> createState() => _AddEditTestScreenState();
}

class _AddEditTestScreenState extends State<AddEditTestScreen> {
  late final TestsViewModel _viewModel;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController();
  final TextEditingController _passingMarksController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedClassId;
  late DateTime _testDate;

  @override
  void initState() {
    super.initState();
    _viewModel = TestsViewModel();
    _viewModel.addListener(_onViewModelChange);

    final t = widget.testToEdit;
    if (t != null) {
      _nameController.text = t.testName;
      _subjectController.text = t.subject;
      _totalMarksController.text = t.totalMarks.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '');
      _passingMarksController.text = t.passingMarks != null
          ? t.passingMarks!.toStringAsFixed(0).replaceAll(RegExp(r'\.0$'), '')
          : '';
      _descriptionController.text = t.description;
      _selectedClassId = t.classId;
      _testDate = DateTime.tryParse(t.testDate) ?? DateTime.now();
    } else {
      _testDate = DateTime.now();
      _totalMarksController.text = '50';
    }

    _viewModel.fetchTestsData().then((_) {
      if (mounted && _selectedClassId == null && _viewModel.classes.isNotEmpty) {
        setState(() {
          _selectedClassId = _viewModel.classes.first.classId;
        });
      }
    });
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
    _nameController.dispose();
    _subjectController.dispose();
    _totalMarksController.dispose();
    _passingMarksController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTestDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _testDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _testDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_viewModel.isSaving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final classId = _selectedClassId ?? '';
    final name = _nameController.text;
    final subject = _subjectController.text;
    final desc = _descriptionController.text;
    final dateStr = _formatDate(_testDate);

    final totalMarks = double.tryParse(_totalMarksController.text.trim()) ?? 0;
    final passingStr = _passingMarksController.text.trim();
    double? passingMarks;
    if (passingStr.isNotEmpty) {
      passingMarks = double.tryParse(passingStr);
    }

    bool success = false;
    if (widget.testToEdit == null) {
      success = await _viewModel.createTest(
        testName: name,
        classId: classId,
        subject: subject,
        testDate: dateStr,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: desc,
        createdBy: user.uid,
      );
    } else {
      success = await _viewModel.updateTest(
        testId: widget.testToEdit!.testId,
        testName: name,
        classId: classId,
        subject: subject,
        testDate: dateStr,
        totalMarks: totalMarks,
        passingMarks: passingMarks,
        description: desc,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.testToEdit == null
              ? 'Test created successfully.'
              : 'Test updated successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop(true);
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
    final isEditing = widget.testToEdit != null;
    final classesList = widget.preloadedClasses ?? _viewModel.classes;

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
          isEditing ? 'Edit Test' : 'Create Test',
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
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Name
                  const Text('Test Name', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'e.g., Unit Test 1',
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryEmerald, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Class Dropdown
                  const Text('Class', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    isExpanded: true,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryEmerald, width: 1.5),
                      ),
                    ),
                    items: classesList.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Loading classes...',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            )
                          ]
                        : classesList.map((cls) {
                            return DropdownMenuItem<String>(
                              value: cls.classId,
                              child: Text(cls.className,
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedClassId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Subject
                  const Text('Subject', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _subjectController,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'e.g., Mathematics',
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryEmerald, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Test Date
                  const Text('Test Date', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectTestDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(_testDate),
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
                  const SizedBox(height: 16),

                  // Marks Row (Total Marks & Passing Marks)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Marks',
                                style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _totalMarksController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'e.g., 50',
                                hintStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primaryEmerald,
                                      width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Passing Marks (Optional)',
                                style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passingMarksController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.inputText,
                              decoration: InputDecoration(
                                hintText: 'e.g., 18',
                                hintStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primaryEmerald,
                                      width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('Description (Optional)',
                      style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    style: AppTextStyles.inputText,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g., Chapter 1 to Chapter 4',
                      hintStyle: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryEmerald, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: isEditing ? 'Update Test' : 'Create Test',
                    isLoading: _viewModel.isSaving,
                    onPressed: _viewModel.isSaving ? null : _handleSave,
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
