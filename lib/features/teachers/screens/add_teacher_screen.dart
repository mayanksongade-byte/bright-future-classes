import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/services/firestore_service.dart';
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
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  Set<String> _selectedClassIds = {};
  Set<String> _selectedSubjects = {'Mathematics'};
  String _selectedStatus = 'active';
  bool _isPasswordObscured = true;

  List<String> _availableSubjects = [
    'Mathematics',
    'Science',
    'English',
    'Computer',
    'Social Science',
    'Gujarati',
    'Hindi',
  ];
  bool _isLoadingSubjects = true;

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
      if (t.subjects.isNotEmpty) {
        _selectedSubjects = t.subjects.toSet();
      } else if (t.subject.isNotEmpty) {
        _selectedSubjects = {t.subject};
      }
      _userIdController.text = t.userId ?? '';
      _selectedStatus = t.status;
      _selectedClassIds = t.classIds.toSet();
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingClasses = true;
      _isLoadingSubjects = true;
    });

    try {
      final classes = await _classRepository.getClasses();
      final centralSubs = await FirestoreService().getCentralSubjects();
      if (!mounted) return;
      setState(() {
        _availableClasses = classes;
        _availableSubjects = centralSubs;
        _isLoadingClasses = false;
        _isLoadingSubjects = false;
        if (_selectedSubjects.isEmpty && centralSubs.isNotEmpty) {
          _selectedSubjects = {centralSubs.first};
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
          _isLoadingSubjects = false;
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
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Subject', style: TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Subject Name', hintText: 'e.g. Marathi'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                final exists = _availableSubjects.any((s) => s.trim().toLowerCase() == name.toLowerCase());
                if (exists) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subject already exists.'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                await FirestoreService().addCentralSubject(name);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                final updated = await FirestoreService().getCentralSubjects();
                if (!mounted) return;
                setState(() {
                  _availableSubjects = updated;
                  _selectedSubjects.add(name);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
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

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one assigned subject'),
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
        subjects: _selectedSubjects.toList(),
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
        subjects: _selectedSubjects.toList(),
        classIds: _selectedClassIds.toList(),
        loginUserId: _userIdController.text.trim().toUpperCase(),
        password: _passwordController.text.trim(),
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
                      : 'Teacher profile created successfully',
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
                      hintText: 'e.g. amit@brightfuture.com',
                      controller: _emailController,
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    AppTextField(
                      label: 'Phone Number',
                      hintText: 'e.g. 9876543210',
                      controller: _phoneController,
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
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
                      label: 'Address (Optional)',
                      hintText: 'e.g. 123 Main Street',
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2 — ASSIGNED SUBJECTS (Multi-select)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assigned Subjects *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddSubjectDialog,
                          icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryEmerald),
                          label: const Text('Add Subject', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select one or more subjects taught by this teacher.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),

                    _isLoadingSubjects
                        ? Center(child: Padding(padding: const EdgeInsets.all(16), child: AppLoadingIndicator()))
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: _availableSubjects.isEmpty
                                ? const Text('No subjects available.', style: TextStyle(color: AppColors.textSecondary))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _availableSubjects.map((sub) {
                                      final isSelected = _selectedSubjects.contains(sub);
                                      return FilterChip(
                                        label: Text(sub),
                                        selected: isSelected,
                                        selectedColor: AppColors.lightEmerald,
                                        checkmarkColor: AppColors.darkEmerald,
                                        labelStyle: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? AppColors.darkEmerald : AppColors.textMain,
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedSubjects.add(sub);
                                            } else {
                                              if (_selectedSubjects.length > 1) {
                                                _selectedSubjects.remove(sub);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('At least one subject must remain selected.'),
                                                    backgroundColor: AppColors.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                    const SizedBox(height: 20),

                    // SECTION 3 — ASSIGNED CLASSES
                    const Text(
                      'Assigned Classes *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select classes this teacher is assigned to.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),

                    _isLoadingClasses
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: AppLoadingIndicator(),
                            ),
                          )
                        : _availableClasses.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'No classes available in the system.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AddClassScreen(),
                                          ),
                                        );
                                        _loadData();
                                      },
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16,
                                          color: AppColors.primaryEmerald),
                                      label: const Text(
                                        'Create Class First',
                                        style: TextStyle(
                                            color: AppColors.primaryEmerald,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckboxListTile(
                                      title: const Text(
                                        'Select All Classes',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      value: _selectedClassIds.length ==
                                          _availableClasses.length,
                                      activeColor: AppColors.primaryEmerald,
                                      contentPadding: EdgeInsets.zero,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedClassIds = _availableClasses
                                                .map((c) => c.classId)
                                                .toSet();
                                          } else {
                                            _selectedClassIds.clear();
                                          }
                                        });
                                      },
                                    ),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 8),
                                    ..._availableClasses.map((cls) {
                                      final isSelected =
                                          _selectedClassIds.contains(cls.classId);
                                      return CheckboxListTile(
                                        title: Text(
                                          cls.className,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Standard: ${cls.standard} · Medium: ${cls.medium}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        value: isSelected,
                                        activeColor: AppColors.primaryEmerald,
                                        contentPadding: EdgeInsets.zero,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedClassIds.add(cls.classId);
                                            } else {
                                              _selectedClassIds.remove(cls.classId);
                                            }
                                          });
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),

                    // SECTION 4 — STATUS & CREDENTIALS
                    const SizedBox(height: 28),
                    const Text(
                      'Status & Credentials',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure teacher status and login account.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

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

                    if (!isEditing) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Login User ID',
                        hintText: 'e.g. TCH001',
                        controller: _userIdController,
                        validator: (value) =>
                            Validators.validateRequired(value, 'User ID'),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.characters,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Password',
                        hintText: 'At least 6 characters',
                        controller: _passwordController,
                        validator: Validators.validatePassword,
                        obscureText: _isPasswordObscured,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: isEditing ? 'Update Teacher Profile' : 'Create Teacher Profile',
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
