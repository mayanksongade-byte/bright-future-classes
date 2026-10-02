import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../view_models/notices_view_model.dart';

class AddEditNoticeScreen extends StatefulWidget {
  final NoticeModel? noticeToEdit;

  const AddEditNoticeScreen({super.key, this.noticeToEdit});

  @override
  State<AddEditNoticeScreen> createState() => _AddEditNoticeScreenState();
}

class _AddEditNoticeScreenState extends State<AddEditNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'general'; // general, academic, exam, holiday, fee, important, event
  String _selectedPriority = 'normal'; // normal, high
  String _selectedAudience = 'all_students'; // all_students, selected_classes
  Set<String> _selectedClassIds = {};
  String _statusOverride = ''; // '' or 'draft'
  bool _isPinned = false;

  late DateTime _publishDate;
  late DateTime _expiryDate;

  late final NoticesViewModel _viewModel;
  late final ClassRepository _classRepository;

  List<ClassModel> _availableClasses = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _viewModel = NoticesViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();

    final n = widget.noticeToEdit;
    if (n != null) {
      _titleController.text = n.title;
      _descriptionController.text = n.description;
      _selectedType = n.type.toLowerCase();
      _selectedPriority = n.priority.toLowerCase();
      _selectedAudience = n.targetAudience.toLowerCase();
      _selectedClassIds = n.classIds.toSet();
      _statusOverride = n.statusOverride;
      _isPinned = n.isPinned;
      _publishDate = n.publishDate;
      _expiryDate = n.expiryDate;
    } else {
      _publishDate = DateTime.now();
      _expiryDate = DateTime.now().add(const Duration(days: 7));
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectPublishDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _publishDate = picked;
        if (_expiryDate.isBefore(DateTime(picked.year, picked.month, picked.day))) {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate.isBefore(_publishDate) ? _publishDate : _expiryDate,
      firstDate: _publishDate,
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _openClassSelectionDialog() async {
    Set<String> tempSelected = Set.from(_selectedClassIds);
    String searchKeyword = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredClasses = _availableClasses.where((c) {
              if (searchKeyword.isEmpty) return true;
              return c.className.toLowerCase().contains(searchKeyword.toLowerCase()) ||
                  c.standard.toLowerCase().contains(searchKeyword.toLowerCase());
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Select Classes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search classes...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.primaryEmerald, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchKeyword = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: filteredClasses.isEmpty
                          ? const Center(
                              child: Text('No classes found.',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredClasses.length,
                              itemBuilder: (context, index) {
                                final cls = filteredClasses[index];
                                final isSelected = tempSelected.contains(cls.classId);
                                return CheckboxListTile(
                                  title: Text(cls.className,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                      'Standard: ${cls.standard} • ${cls.academicYear}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  value: isSelected,
                                  activeColor: AppColors.primaryEmerald,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (bool? checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        tempSelected.add(cls.classId);
                                      } else {
                                        tempSelected.remove(cls.classId);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedClassIds = tempSelected;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudience == 'selected_classes' && _selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one class'),
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
    if (widget.noticeToEdit == null) {
      success = await _viewModel.createNotice(
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        priority: _selectedPriority,
        targetAudience: _selectedAudience,
        classIds: _selectedAudience == 'selected_classes' ? _selectedClassIds.toList() : [],
        publishDate: _publishDate,
        expiryDate: _expiryDate,
        createdBy: createdBy,
        statusOverride: _statusOverride,
        isPinned: _isPinned,
      );
    } else {
      success = await _viewModel.updateNotice(
        noticeId: widget.noticeToEdit!.noticeId,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        priority: _selectedPriority,
        targetAudience: _selectedAudience,
        classIds: _selectedAudience == 'selected_classes' ? _selectedClassIds.toList() : [],
        publishDate: _publishDate,
        expiryDate: _expiryDate,
        statusOverride: _statusOverride,
        isPinned: _isPinned,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.noticeToEdit == null
              ? 'Notice created successfully.'
              : 'Notice updated successfully.'),
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
    final isEditing = widget.noticeToEdit != null;

    // Build summary string for selected classes
    String classSummary = 'No classes selected';
    if (_selectedClassIds.isNotEmpty) {
      final selectedNames = _availableClasses
          .where((c) => _selectedClassIds.contains(c.classId))
          .map((c) => c.className)
          .toList();
      if (selectedNames.isNotEmpty) {
        classSummary = selectedNames.join(', ');
      } else {
        classSummary = '${_selectedClassIds.length} classes selected';
      }
    }

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
          isEditing ? 'Edit Notice' : 'Create Notice',
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
                    // SECTION 1 — NOTICE INFORMATION
                    const Text(
                      'Notice Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter notice title and detailed content below.',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 20),

                    // Title Field
                    const Text('Notice Title', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      style: AppTextStyles.inputText,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter notice title';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g., Mid-Term Examination Schedule',
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
                    const Text('Notice Description', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      style: AppTextStyles.inputText,
                      maxLines: 5,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter notice content';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter full notice description and instructions...',
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
                    const SizedBox(height: 28),

                    // SECTION 2 — NOTICE CLASSIFICATION
                    const Text(
                      'Classification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Notice Type', style: AppTextStyles.inputLabel),
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
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'academic', child: Text('Academic')),
                        DropdownMenuItem(value: 'exam', child: Text('Exam')),
                        DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
                        DropdownMenuItem(value: 'fee', child: Text('Fee')),
                        DropdownMenuItem(value: 'important', child: Text('Important')),
                        DropdownMenuItem(value: 'event', child: Text('Event')),
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

                    // Priority (Directly below Notice Type)
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
                        DropdownMenuItem(value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPriority = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // SECTION 3 — TARGET AUDIENCE
                    const Text(
                      'Target Audience',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Audience', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAudience,
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
                        DropdownMenuItem(value: 'all_students', child: Text('All Students')),
                        DropdownMenuItem(value: 'selected_classes', child: Text('Selected Classes')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAudience = val;
                          });
                        }
                      },
                    ),

                    if (_selectedAudience == 'selected_classes') ...[
                      const SizedBox(height: 16),
                      const Text('Select Classes', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 6),
                      _isLoadingClasses
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _openClassSelectionDialog,
                                  icon: const Icon(Icons.school_outlined,
                                      color: AppColors.primaryEmerald),
                                  label: Text(
                                    _selectedClassIds.isEmpty
                                        ? 'Select Classes...'
                                        : '${_selectedClassIds.length} classes selected',
                                    style: const TextStyle(
                                        color: AppColors.textMain,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  classSummary,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ],
                    const SizedBox(height: 28),

                    // SECTION 4 — SCHEDULE
                    const Text(
                      'Schedule & Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Publish Date',
                                  style: AppTextStyles.inputLabel),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _selectPublishDate,
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
                                        _formatDate(_publishDate),
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
                              const Text('Expiry Date',
                                  style: AppTextStyles.inputLabel),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: _selectExpiryDate,
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
                                        _formatDate(_expiryDate),
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
                    const SizedBox(height: 16),
                    const Text('Save Mode', style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _statusOverride,
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
                        DropdownMenuItem(value: '', child: Text('Automatic (Based on Dates)')),
                        DropdownMenuItem(value: 'draft', child: Text('Save as Draft')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _statusOverride = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 28),

                    // SECTION 5 — OPTIONS (Pin Notice)
                    const Text(
                      'Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: CheckboxListTile(
                        title: const Text('Pin this notice',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMain)),
                        subtitle: const Text(
                            'Pinned notices appear at the top of the notice list',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: _isPinned,
                        activeColor: AppColors.primaryEmerald,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (bool? val) {
                          setState(() {
                            _isPinned = val ?? false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: isEditing ? 'Update Notice' : 'Create Notice',
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
