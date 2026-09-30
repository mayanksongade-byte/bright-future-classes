import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../view_models/classes_view_model.dart';

class AddClassScreen extends StatefulWidget {
  final ClassModel? classToEdit;

  const AddClassScreen({super.key, this.classToEdit});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _standardController = TextEditingController();
  final _academicYearController = TextEditingController();

  String _selectedMedium = 'English';
  String _selectedStatus = 'active';

  late final ClassesViewModel _viewModel;

  final List<String> _mediumOptions = ['English', 'Gujarati', 'Hindi'];
  final List<String> _statusOptions = ['active', 'inactive'];

  bool get isEditing => widget.classToEdit != null;

  @override
  void initState() {
    super.initState();
    _viewModel = ClassesViewModel();
    _viewModel.addListener(_onViewModelChange);

    if (widget.classToEdit != null) {
      final cls = widget.classToEdit!;
      _classNameController.text = cls.className;
      _standardController.text = cls.standard;
      _academicYearController.text = cls.academicYear;
      if (_mediumOptions.contains(cls.medium)) {
        _selectedMedium = cls.medium;
      }
      if (_statusOptions.contains(cls.status.toLowerCase())) {
        _selectedStatus = cls.status.toLowerCase();
      }
    } else {
      _academicYearController.text = '2026-27';
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
    _classNameController.dispose();
    _standardController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = isEditing
        ? await _viewModel.updateClass(
            classId: widget.classToEdit!.classId,
            className: _classNameController.text,
            standard: _standardController.text,
            medium: _selectedMedium,
            academicYear: _academicYearController.text,
            status: _selectedStatus,
            createdAt: widget.classToEdit!.createdAt,
          )
        : await _viewModel.createClass(
            className: _classNameController.text,
            standard: _standardController.text,
            medium: _selectedMedium,
            academicYear: _academicYearController.text,
            status: _selectedStatus,
          );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Class updated successfully'
                      : 'Class created successfully',
                  style: const TextStyle(
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
      Navigator.of(context).pop(true);
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textMain,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          isEditing ? 'Edit Class' : 'Add Class',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Update Class Details' : 'Class Information',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Modify the class parameters below.'
                          : 'Fill in the required information to create a new class.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // 1. Class Name
                    AppTextField(
                      label: 'Class Name',
                      hintText: 'e.g. Class 10 - A',
                      controller: _classNameController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Class Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.school_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Standard
                    AppTextField(
                      label: 'Standard',
                      hintText: 'e.g. 10',
                      controller: _standardController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Standard'),
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.class_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Medium (Dropdown)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medium',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMedium,
                          style: AppTextStyles.inputText,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.translate_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryEmerald,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: _mediumOptions.map((medium) {
                            return DropdownMenuItem<String>(
                              value: medium,
                              child: Text(medium),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMedium = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a Medium';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Academic Year
                    AppTextField(
                      label: 'Academic Year',
                      hintText: 'e.g. 2026-27',
                      controller: _academicYearController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Academic Year'),
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          style: AppTextStyles.inputText,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.toggle_on_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primaryEmerald,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    PrimaryButton(
                      text: isEditing ? 'Update Class' : 'Create Class',
                      isLoading: _viewModel.isActionLoading,
                      onPressed: _handleSave,
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
}
