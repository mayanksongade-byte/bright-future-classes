import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../classes/screens/add_class_screen.dart';
import '../view_models/students_view_model.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _totalFeesController = TextEditingController(text: '30000');
  final _discountController = TextEditingController(text: '0');

  String? _selectedClassId;

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
    _phoneController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _totalFeesController.dispose();
    _discountController.dispose();
    super.dispose();
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

    final success = await _viewModel.createStudent(
      studentId: _studentIdController.text,
      name: _nameController.text,
      phone: _phoneController.text,
      parentName: _parentNameController.text,
      parentPhone: _parentPhoneController.text,
      totalFees: totalFees,
      discount: discount,
      classId: _selectedClassId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Student and fee record added successfully',
                  style: TextStyle(
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
        title: const Text(
          'Add Student',
          style: TextStyle(
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
                      'Enter the details below to add a new student profile and fee setup.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // 1. Student ID
                    AppTextField(
                      label: 'Student ID',
                      hintText: 'e.g. STU001',
                      controller: _studentIdController,
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

                    // 2. Student Name
                    AppTextField(
                      label: 'Student Name',
                      hintText: 'e.g. Rahul Sharma',
                      controller: _nameController,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Student Name'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Phone Number
                    AppTextField(
                      label: 'Phone Number',
                      hintText: 'e.g. 9876543210',
                      controller: _phoneController,
                      validator: (value) =>
                          Validators.validatePhone(value, 'Phone Number'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Parent Name
                    AppTextField(
                      label: 'Parent Name',
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

                    // 5. Parent Phone
                    AppTextField(
                      label: 'Parent Phone',
                      hintText: 'e.g. 9876543211',
                      controller: _parentPhoneController,
                      validator: (value) =>
                          Validators.validatePhone(value, 'Parent Phone'),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.contact_phone_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6. Class Assignment
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Assignment',
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
                    const SizedBox(height: 24),

                    // 7. Fee Details Section
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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 32),

                    // Primary Action Button
                    PrimaryButton(
                      text: 'Create Student',
                      isLoading: _viewModel.isLoading,
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
