import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../classes/screens/add_class_screen.dart';
import '../view_models/students_view_model.dart';

class AddStudentScreen extends StatefulWidget {
  final StudentModel? studentToEdit;

  const AddStudentScreen({super.key, this.studentToEdit});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _totalFeesController = TextEditingController(text: '30000');
  final _discountController = TextEditingController(text: '0');

  String _selectedGender = 'Male';
  String? _selectedClassId;
  String _selectedStatus = 'active';

  late final StudentsViewModel _viewModel;
  late final ClassRepository _classRepository;

  List<ClassModel> _availableClasses = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _viewModel = StudentsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();

    final st = widget.studentToEdit;
    if (st != null) {
      _studentIdController.text = st.studentId;
      _nameController.text = st.name;
      _dobController.text = st.dateOfBirth;
      if (['Male', 'Female', 'Other'].contains(st.gender)) {
        _selectedGender = st.gender;
      }
      _phoneController.text = st.phone;
      _addressController.text = st.address;
      _parentNameController.text = st.parentName;
      _parentPhoneController.text = st.parentPhone;
      _selectedClassId = st.classId;
      _selectedStatus = st.status;
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
          if (_availableClasses.isNotEmpty && _selectedClassId == null) {
            _selectedClassId = _availableClasses.first.classId;
          } else if (_selectedClassId != null &&
              !_availableClasses.any((c) => c.classId == _selectedClassId)) {
            // Keep or fallback safely
          }
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
    _studentIdController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _totalFeesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final initialDate = DateTime.tryParse(_dobController.text) ?? DateTime(2010, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(DateTime.now()) ? DateTime.now() : initialDate,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a class for the student'),
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

    final isEditing = widget.studentToEdit != null;
    bool success = false;

    if (isEditing) {
      success = await _viewModel.updateStudent(
        studentId: _studentIdController.text.trim(),
        name: _nameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        classId: _selectedClassId,
        status: _selectedStatus,
      );
    } else {
      final totalFees = double.tryParse(_totalFeesController.text.trim());
      final discount = double.tryParse(_discountController.text.trim()) ?? 0.0;

      if (totalFees == null || totalFees < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid Total Fees amount >= 0'),
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

      if (discount < 0 || discount > totalFees) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Discount cannot be negative or greater than Total Fees'),
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

      success = await _viewModel.createStudent(
        studentId: _studentIdController.text.trim(),
        name: _nameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        gender: _selectedGender,
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        totalFees: totalFees,
        discount: discount,
        classId: _selectedClassId,
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
                      ? 'Student updated successfully'
                      : 'Student and fee record added successfully',
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
    final isEditing = widget.studentToEdit != null;

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
          isEditing ? 'Edit Student' : 'Add Student',
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
                    // SECTION 1 — STUDENT INFORMATION
                    const Text(
                      'Student Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter student personal details and contact info below.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Student ID
                    AppTextField(
                      label: 'Student ID',
                      hintText: 'e.g. STU001',
                      controller: _studentIdController,
                      enabled: !isEditing,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Student ID'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    AppTextField(
                      label: 'Full Name',
                      hintText: 'e.g. Rahul Sharma',
                      controller: _nameController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Full Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date of Birth',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _selectDateOfBirth,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: AppColors.textSecondary,
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
                            child: Text(
                              _dobController.text.isNotEmpty
                                  ? _dobController.text
                                  : 'Select Date of Birth',
                              style: _dobController.text.isNotEmpty
                                  ? AppTextStyles.inputText
                                  : const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                            ),
                          ),
                        ),
                        if (_dobController.text.isEmpty)
                          FormField<String>(
                            validator: (_) =>
                                Validators.validateDateOfBirth(_dobController.text),
                            builder: (field) {
                              if (field.errorText != null) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6, left: 12),
                                  child: Text(
                                    field.errorText!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gender',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
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
                              Icons.wc_rounded,
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
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedGender = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Student Phone Number (10 digits only)
                    AppTextField(
                      label: 'Student Phone Number',
                      hintText: '9876543210',
                      controller: _phoneController,
                      validator: (value) =>
                          Validators.validate10DigitPhone(value, 'Student Phone'),
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
                    const SizedBox(height: 28),

                    // SECTION 2 — PARENT / GUARDIAN
                    const Text(
                      'Parent / Guardian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter parent or guardian contact details.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Parent Name
                    AppTextField(
                      label: 'Parent / Guardian Name',
                      hintText: 'e.g. Suresh Sharma',
                      controller: _parentNameController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Parent Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.family_restroom_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parent Phone Number (10 digits only)
                    AppTextField(
                      label: 'Parent / Guardian Phone Number',
                      hintText: '9876543210',
                      controller: _parentPhoneController,
                      validator: (value) =>
                          Validators.validate10DigitPhone(value, 'Parent Phone'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.contact_phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // SECTION 3 — ACADEMIC
                    const Text(
                      'Academic',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assign class and status.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Class Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class',
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
                                          'Create a class first before adding a student.',
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
                                : DropdownButtonFormField<String>(
                                    initialValue: _selectedClassId,
                                    style: AppTextStyles.inputText,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.surface,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.school_outlined,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: AppColors.primaryEmerald,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    items: _availableClasses.map((cls) {
                                      return DropdownMenuItem<String>(
                                        value: cls.classId,
                                        child: Text(
                                          '${cls.className} (${cls.standard} - ${cls.academicYear})',
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedClassId = value;
                                        });
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select a Class';
                                      }
                                      return null;
                                    },
                                  ),
                      ],
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
                                value: 'active', child: Text('Active')),
                            DropdownMenuItem(
                                value: 'inactive', child: Text('Inactive')),
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

                    // SECTION 4 — FEE DETAILS (Only when creating new student)
                    if (!isEditing) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'Fee Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set initial tuition fee and discount for this student.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),

                      AppTextField(
                        label: 'Total Fees (₹)',
                        hintText: 'e.g. 30000',
                        controller: _totalFeesController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter Total Fees';
                          }
                          if (double.tryParse(value.trim()) == null ||
                              double.parse(value.trim()) < 0) {
                            return 'Please enter a valid amount >= 0';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),

                      AppTextField(
                        label: 'Discount (₹)',
                        hintText: 'e.g. 0',
                        controller: _discountController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final disc = double.tryParse(value.trim());
                          if (disc == null || disc < 0) {
                            return 'Please enter a valid discount >= 0';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Primary Action Button
                    PrimaryButton(
                      text: isEditing ? 'Update Student' : 'Create Student',
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
