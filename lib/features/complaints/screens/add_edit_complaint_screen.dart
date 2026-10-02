import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../view_models/complaints_view_model.dart';

class AddEditComplaintScreen extends StatefulWidget {
  final ComplaintModel? complaintToEdit;

  const AddEditComplaintScreen({super.key, this.complaintToEdit});

  @override
  State<AddEditComplaintScreen> createState() => _AddEditComplaintScreenState();
}

class _AddEditComplaintScreenState extends State<AddEditComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _resolutionNoteController = TextEditingController();

  String _selectedType = 'Academic'; // Academic, Attendance, Behavior, Fees, Other
  String _selectedPriority = 'Medium'; // Low, Medium, High
  String _selectedStatus = 'Open'; // Open, In Review, Resolved, Closed
  String? _selectedClassId;
  String? _selectedStudentId;

  late final ComplaintsViewModel _viewModel;
  late final ClassRepository _classRepository;
  late final StudentRepository _studentRepository;

  List<ClassModel> _availableClasses = [];
  List<StudentModel> _allStudents = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();
    _studentRepository = StudentRepository();

    final c = widget.complaintToEdit;
    if (c != null) {
      _titleController.text = c.title;
      _descriptionController.text = c.description;
      _resolutionNoteController.text = c.resolutionNote;
      _selectedType = c.type;
      _selectedPriority = c.priority;
      _selectedStatus = c.status;
      _selectedClassId = c.classId;
      _selectedStudentId = c.studentId;
    }

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final results = await Future.wait([
        _classRepository.getClasses(),
        _studentRepository.getStudents(),
      ]);
      if (mounted) {
        setState(() {
          _availableClasses = results[0] as List<ClassModel>;
          _allStudents = results[1] as List<StudentModel>;
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
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
    _titleController.dispose();
    _descriptionController.dispose();
    _resolutionNoteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a class'),
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

    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a student'),
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

    final user = FirebaseAuth.instance.currentUser;
    final createdBy = user?.uid ?? 'admin';

    bool success = false;
    if (widget.complaintToEdit == null) {
      success = await _viewModel.createComplaint(
        studentId: _selectedStudentId!,
        classId: _selectedClassId!,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        createdBy: createdBy,
      );
    } else {
      success = await _viewModel.updateComplaint(
        complaintId: widget.complaintToEdit!.complaintId,
        studentId: _selectedStudentId!,
        classId: _selectedClassId!,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        status: _selectedStatus,
        resolutionNote: _resolutionNoteController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.complaintToEdit == null
              ? 'Complaint created successfully.'
              : 'Complaint updated successfully.'),
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
    final isEditing = widget.complaintToEdit != null;
    final filteredStudents = _selectedClassId != null
        ? _allStudents.where((s) => s.classId == _selectedClassId).toList()
        : <StudentModel>[];

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
          isEditing ? 'Edit Complaint' : 'Add Complaint',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Complaint About
                    const Text(
                      'Complaint About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the class and student this complaint relates to.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Class Dropdown
                    const Text('Class', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    _isLoadingData
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                        : DropdownButtonFormField<String>(
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
                            items: _availableClasses.map((cls) {
                              return DropdownMenuItem<String>(
                                value: cls.classId,
                                child: Text(cls.className, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedClassId = val;
                                  // Reset student if not valid for new class
                                  if (_selectedStudentId != null) {
                                    final match = _allStudents.any(
                                        (s) => s.studentId == _selectedStudentId && s.classId == val);
                                    if (!match) {
                                      _selectedStudentId = null;
                                    }
                                  }
                                });
                              }
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please select a class';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),

                    // Student Dropdown (disabled until class selected)
                    const Text('Student', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClassId != null &&
                              filteredStudents.any((s) => s.studentId == _selectedStudentId)
                          ? _selectedStudentId
                          : null,
                      isExpanded: true,
                      style: AppTextStyles.inputText,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _selectedClassId == null
                            ? AppColors.border.withValues(alpha: 0.3)
                            : AppColors.surface,
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
                      items: _selectedClassId == null
                          ? []
                          : filteredStudents.map((stu) {
                              return DropdownMenuItem<String>(
                                value: stu.studentId,
                                child: Text(stu.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                      onChanged: _selectedClassId == null
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStudentId = val;
                                });
                              }
                            },
                      validator: (val) {
                        if (_selectedClassId != null && (val == null || val.isEmpty)) {
                          return 'Please select a student';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // SECTION 2: Complaint Details
                    const Text(
                      'Complaint Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Complaint Type
                    const Text('Complaint Type', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
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
                        DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                        DropdownMenuItem(value: 'Attendance', child: Text('Attendance')),
                        DropdownMenuItem(value: 'Behavior', child: Text('Behavior')),
                        DropdownMenuItem(value: 'Fees', child: Text('Fees')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Complaint Title
                    const Text('Complaint Title', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: AppTextStyles.inputText,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter complaint title';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., Repeated late attendance',
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

                    // Description
                    const Text('Description', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      style: AppTextStyles.inputText,
                      maxLines: 4,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter complaint details...',
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

                    // Priority
                    const Text('Priority', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
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
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPriority = val;
                          });
                        }
                      },
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      const Text('Status', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
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
                          DropdownMenuItem(value: 'Open', child: Text('Open')),
                          DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                          DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                          DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedStatus = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Resolution Note', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _resolutionNoteController,
                        style: AppTextStyles.inputText,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter resolution notes if resolved/closed...',
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
                    ],

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: isEditing ? 'Update Complaint' : 'Create Complaint',
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
      ),
    );
  }
}
