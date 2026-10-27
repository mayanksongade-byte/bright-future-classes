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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _totalFeesController = TextEditingController(text: '30000');
  final _discountController = TextEditingController(text: '0');

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
            content: const Text('Discount cannot be negative or greater than Total Fees'),
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
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Student updated successfully'
                      : 'Student account and fee record added successfully',
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
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
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
                      'Enter student personal details below.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Student ID
                    AppTextField(
                      label: 'Student ID *',
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
                      label: 'Full Name *',
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

                    if (!isEditing) ...[
                      // Initial Password
                      AppTextField(
                        label: 'Initial Password *',
                        hintText: 'Minimum 6 characters',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) => Validators.validatePassword(value),
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      AppTextField(
                        label: 'Confirm Password *',
                        hintText: 'Re-enter initial password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please confirm password';
                          if (value.trim() != _passwordController.text.trim()) return 'Passwords do not match';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dobController.text.isNotEmpty
                                      ? _dobController.text
                                      : 'Select Date of Birth',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _dobController.text.isNotEmpty
                                        ? AppColors.textMain
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppColors.primaryEmerald,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
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
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                          items: ['Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedGender = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Student Phone
                    AppTextField(
                      label: 'Student Phone',
                      hintText: 'e.g. 9876543210',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          Validators.validatePhoneOptional(value),
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    AppTextField(
                      label: 'Address',
                      hintText: 'Enter full residential address',
                      controller: _addressController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Address'),
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.home_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // SECTION 2 — PARENT / GUARDIAN INFORMATION
                    const Text(
                      'Parent / Guardian Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Primary contact details for progress and fee communications.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Parent Name
                    AppTextField(
                      label: 'Parent / Guardian Name',
                      hintText: 'e.g. Ramesh Sharma',
                      controller: _parentNameController,
                      validator: (value) => Validators.validateRequired(
                          value, 'Parent / Guardian Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.family_restroom_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parent Phone
                    AppTextField(
                      label: 'Parent Phone Number',
                      hintText: 'e.g. 9876543210',
                      controller: _parentPhoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          Validators.validatePhone(value, 'Parent Phone Number'),
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.phone_android_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // SECTION 3 — CLASS ASSIGNMENT & FEES
                    const Text(
                      'Class Assignment & Initial Fee Record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Assign student to a class and configure initial academic fee.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Class Dropdown
                    _isLoadingClasses
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Assign Class *',
                                    style: AppTextStyles.inputLabel,
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      final created = await Navigator.of(context)
                                          .push<bool>(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddClassScreen(),
                                        ),
                                      );
                                      if (created == true) {
                                        _loadClasses();
                                      }
                                    },
                                    icon: const Icon(Icons.add_rounded,
                                        size: 16,
                                        color: AppColors.primaryEmerald),
                                    label: const Text(
                                      'Add New Class',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryEmerald,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedClassId,
                                style: AppTextStyles.inputText,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
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
                                items: _availableClasses
                                    .map((cls) => DropdownMenuItem(
                                          value: cls.classId,
                                          child: Text(
                                            '${cls.className} (${cls.standard} - ${cls.medium})',
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedClassId = val;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),

                    if (!isEditing) ...[
                      // Total Fees
                      AppTextField(
                        label: 'Total Payable Fee (₹)',
                        hintText: 'e.g. 30000',
                        controller: _totalFeesController,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            Validators.validateRequired(value, 'Total Fees'),
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Discount
                      AppTextField(
                        label: 'Scholarship / Discount (₹)',
                        hintText: 'e.g. 2000',
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            Validators.validateRequired(value, 'Discount'),
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Status Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Status',
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // SUBMIT BUTTON
                    PrimaryButton(
                      text: isEditing ? 'Save Changes' : 'Add Student Record',
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
