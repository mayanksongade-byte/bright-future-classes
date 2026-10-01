import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/homework_model.dart';
import '../view_models/homework_view_model.dart';

class AddEditHomeworkScreen extends StatefulWidget {
  final HomeworkModel? homeworkToEdit;
  final List<ClassModel>? preloadedClasses;

  const AddEditHomeworkScreen({
    super.key,
    this.homeworkToEdit,
    this.preloadedClasses,
  });

  @override
  State<AddEditHomeworkScreen> createState() => _AddEditHomeworkScreenState();
}

class _AddEditHomeworkScreenState extends State<AddEditHomeworkScreen> {
  late final HomeworkViewModel _viewModel;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedClassId;
  String _status = 'active';
  late DateTime _assignedDate;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeworkViewModel();
    _viewModel.addListener(_onViewModelChange);

    final hw = widget.homeworkToEdit;
    if (hw != null) {
      _titleController.text = hw.title;
      _descriptionController.text = hw.description;
      _selectedClassId = hw.classId;
      _status = hw.status;
      _assignedDate = DateTime.tryParse(hw.assignedDate) ?? DateTime.now();
      _dueDate = DateTime.tryParse(hw.dueDate) ??
          DateTime.now().add(const Duration(days: 3));
    } else {
      _assignedDate = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 3));
    }

    if (widget.preloadedClasses != null &&
        widget.preloadedClasses!.isNotEmpty) {
      _selectedClassId ??= widget.preloadedClasses!.first.classId;
    }

    _viewModel.fetchHomeworkData().then((_) {
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectAssignedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _assignedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _assignedDate = picked;
        if (_dueDate.isBefore(DateTime(picked.year, picked.month, picked.day))) {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(_assignedDate) ? _assignedDate : _dueDate,
      firstDate: _assignedDate,
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_viewModel.isSaving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final classId = _selectedClassId ?? '';
    final title = _titleController.text;
    final description = _descriptionController.text;
    final assignedStr = _formatDate(_assignedDate);
    final dueStr = _formatDate(_dueDate);

    bool success = false;
    if (widget.homeworkToEdit == null) {
      success = await _viewModel.createHomework(
        classId: classId,
        title: title,
        description: description,
        assignedDate: assignedStr,
        dueDate: dueStr,
        createdBy: user.uid,
      );
    } else {
      success = await _viewModel.updateHomework(
        homeworkId: widget.homeworkToEdit!.homeworkId,
        classId: classId,
        title: title,
        description: description,
        assignedDate: assignedStr,
        dueDate: dueStr,
        status: _status,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.homeworkToEdit == null
              ? 'Homework created successfully.'
              : 'Homework updated successfully.'),
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
    final isEditing = widget.homeworkToEdit != null;
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
          isEditing ? 'Edit Homework' : 'Add Homework',
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

                  // Title Field
                  const Text('Title', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'e.g., Chapter 3 Exercises',
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

                  // Description Field
                  const Text('Description', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    style: AppTextStyles.inputText,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter homework description and instructions...',
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

                  // Dates Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assigned Date',
                                style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectAssignedDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_assignedDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
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
                            const Text('Due Date',
                                style: AppTextStyles.inputLabel),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _selectDueDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDate(_dueDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
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

                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    const Text('Status', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
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
                      items: const [
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _status = val;
                          });
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: isEditing ? 'Update Homework' : 'Create Homework',
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
