import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../classes/screens/add_class_screen.dart';
import '../view_models/teachers_view_model.dart';

class AddTeacherScreen extends StatefulWidget {
  final TeacherModel? teacherToEdit;

  const AddTeacherScreen({super.key, this.teacherToEdit});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Set<String> _selectedClassIds = {};
  String _selectedStatus = 'active';

  late final TeachersViewModel _viewModel;
  late final ClassRepository _classRepository;

  List<ClassModel> _availableClasses = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _viewModel = TeachersViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();

    final t = widget.teacherToEdit;
    if (t != null) {
      _nameController.text = t.name;
      _emailController.text = t.email;
      _phoneController.text = t.phone;
      _addressController.text = t.address;
      _selectedStatus = t.status;
      _selectedClassIds = t.classIds.toSet();
    }

    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });
    try {
      final classes = await _classRepository.getClasses();
      if (mounted) {
        setState(() {
          _availableClasses = classes;
          _isLoadingClasses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one assigned class'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final isEditing = widget.teacherToEdit != null;
    bool success = false;

    if (isEditing) {
      success = await _viewModel.updateTeacher(
        teacherId: widget.teacherToEdit!.teacherId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        classIds: _selectedClassIds.toList(),
        status: _selectedStatus,
        createdAt: widget.teacherToEdit!.createdAt,
      );
    } else {
      success = await _viewModel.createTeacher(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        classIds: _selectedClassIds.toList(),
        status: _selectedStatus,
      );
    }

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
                      ? 'Teacher profile updated successfully'
                      : 'Teacher added successfully',
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
    final isEditing = widget.teacherToEdit != null;

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
          isEditing ? 'Edit Teacher' : 'Add Teacher',
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
                    // SECTION 1 — TEACHER INFORMATION
                    const Text(
                      'Teacher Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter teacher details, contact info, and status.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    AppTextField(
                      label: 'Teacher Name',
                      hintText: 'e.g. Amit Patel',
                      controller: _nameController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Teacher Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    AppTextField(
                      label: 'Email Address',
                      hintText: 'e.g. amit@example.com',
                      controller: _emailController,
                      validator: (value) => Validators.validateEmail(value),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone (10 digits only)
                    AppTextField(
                      label: 'Phone Number',
                      hintText: '9876543210',
                      controller: _phoneController,
                      validator: (value) =>
                          Validators.validate10DigitPhone(value, 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address (Multiline)
                    AppTextField(
                      label: 'Address',
                      hintText: 'Enter complete residential address...',
                      controller: _addressController,
                      maxLines: 3,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Address'),
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
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
                    const SizedBox(height: 28),

                    // SECTION 2 — TEACHING INFORMATION
                    const Text(
                      'Teaching Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select assigned classes for this teacher.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Assigned Classes (Multi-select)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Classes',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        _isLoadingClasses
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryEmerald,
                                  ),
                                ),
                              )
                            : _availableClasses.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.border.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Create a class first before adding a teacher.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        PrimaryButton(
                                          text: 'Create Class',
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const AddClassScreen(),
                                              ),
                                            );
                                            _loadClasses();
                                          },
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _availableClasses.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(
                                        height: 1,
                                        color: AppColors.border,
                                      ),
                                      itemBuilder: (context, index) {
                                        final cls = _availableClasses[index];
                                        final isSelected =
                                            _selectedClassIds.contains(cls.classId);
                                        return CheckboxListTile(
                                          title: Text(
                                            cls.className,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Standard: ${cls.standard} • Medium: ${cls.medium} • ${cls.academicYear}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          value: isSelected,
                                          activeColor: AppColors.primaryEmerald,
                                          checkboxShape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedClassIds.add(cls.classId);
                                              } else {
                                                _selectedClassIds
                                                    .remove(cls.classId);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    PrimaryButton(
                      text: isEditing ? 'Update Teacher' : 'Save Teacher',
                      isLoading: _viewModel.isActionLoading,
                      onPressed: _viewModel.isActionLoading ? null : _handleSave,
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
