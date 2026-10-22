import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/complaints_view_model.dart';

class AddEditComplaintScreen extends StatelessWidget {
  final ComplaintModel? complaintToEdit;

  const AddEditComplaintScreen({super.key, this.complaintToEdit});

  static Future<bool?> showReportIssueModal(BuildContext context, {List<ClassModel>? preloadedClasses}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: ReportStudentIssueModal(
            preloadedClasses: preloadedClasses,
          ),
        ),
      ),
    );
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: Text(
          complaintToEdit == null ? 'Report Student Issue' : 'Edit Student Issue',
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
              child: ReportStudentIssueModal(
                complaintToEdit: complaintToEdit,
                isModal: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReportStudentIssueModal extends StatefulWidget {
  final ComplaintModel? complaintToEdit;
  final List<ClassModel>? preloadedClasses;
  final bool isModal;

  const ReportStudentIssueModal({
    super.key,
    this.complaintToEdit,
    this.preloadedClasses,
    this.isModal = true,
  });

  @override
  State<ReportStudentIssueModal> createState() => _ReportStudentIssueModalState();
}

class _ReportStudentIssueModalState extends State<ReportStudentIssueModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _actionTakenController = TextEditingController();

  late final ComplaintsViewModel _viewModel;
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedClassId;
  String? _selectedStudentId;
  String _selectedCategory = 'Academic';
  String _selectedPriority = 'Medium';
  DateTime _incidentDate = DateTime.now();

  List<ClassModel> _availableClasses = [];
  List<StudentModel> _studentsInSelectedClass = [];
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);

    final c = widget.complaintToEdit;
    if (c != null) {
      _selectedClassId = c.classId;
      _selectedStudentId = c.studentId;
      _titleController.text = c.title;
      _descriptionController.text = c.description;
      _actionTakenController.text = c.resolutionNote;
      _selectedCategory = c.type;
      _selectedPriority = c.priority;
      _incidentDate = DateTime.tryParse(c.incidentDate) ?? DateTime.now();
    }

    _loadClassesAndStudents();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _actionTakenController.dispose();
    super.dispose();
  }

  Future<void> _loadClassesAndStudents() async {
    setState(() => _isLoadingClasses = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        final role = (userDoc?['role'] as String? ?? 'admin').toLowerCase();

        List<ClassModel> loadedClasses = [];
        if (widget.preloadedClasses != null && widget.preloadedClasses!.isNotEmpty) {
          loadedClasses = List.from(widget.preloadedClasses!);
        } else if (role == 'teacher') {
          final teacherIdFromDoc = userDoc?['teacherId'] as String? ?? '';
          final customUserId = userDoc?['userId'] as String? ?? '';
          final candidateIds = <String>{};
          if (teacherIdFromDoc.isNotEmpty) candidateIds.add(teacherIdFromDoc);
          candidateIds.add(currentUser.uid);
          if (customUserId.isNotEmpty) candidateIds.add(customUserId);

          List<String> classIds = [];
          for (final candidateId in candidateIds) {
            final teacherData = await _firestoreService.getTeacherDocument(candidateId);
            if (teacherData != null) {
              classIds = (teacherData['classIds'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              if (kDebugMode) {
                debugPrint('[AddEditComplaint] Teacher doc at $candidateId, classIds=$classIds');
              }
              break;
            }
          }

          for (var cId in classIds) {
            final classData = await _firestoreService.getClassDocument(cId);
            if (classData != null) {
              loadedClasses.add(ClassModel.fromMap(classData, cId));
            } else {
              loadedClasses.add(ClassModel(
                classId: cId,
                className: cId,
                standard: '',
                medium: '',
                academicYear: '',
              ));
            }
          }
        } else {
          loadedClasses = await ClassRepository().getClasses();
        }

        loadedClasses.sort((a, b) => a.className.compareTo(b.className));

        if (mounted) {
          setState(() {
            _availableClasses = loadedClasses;
            _isLoadingClasses = false;
          });

          if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
            await _onClassSelected(_selectedClassId!);
            if (widget.complaintToEdit != null) {
              _selectedStudentId = widget.complaintToEdit!.studentId;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AddEditComplaint] Error loading classes: $e');
      }
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _onClassSelected(String classId) async {
    setState(() {
      _selectedClassId = classId;
      _selectedStudentId = null;
      _studentsInSelectedClass = [];
      _isLoadingStudents = true;
    });

    try {
      var studentDocs = await _firestoreService.getStudentsDocumentsByClassId(classId);
      // Fallback: in case student documents were stored using className
      if (studentDocs.isEmpty) {
        final matchingClass = _availableClasses.firstWhere(
          (c) => c.classId == classId,
          orElse: () => ClassModel(classId: '', className: '', standard: '', medium: '', academicYear: ''),
        );
        if (matchingClass.className.isNotEmpty && matchingClass.className != classId) {
          studentDocs = await _firestoreService.getStudentsDocumentsByClassId(matchingClass.className);
        }
      }

      final students = studentDocs.map((doc) => StudentModel.fromMap(doc.data(), doc.id)).toList();
      students.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _studentsInSelectedClass = students;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AddEditComplaint] Error loading students for class $classId: $e');
      }
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _selectIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null || _selectedClassId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student'), backgroundColor: AppColors.error),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firestoreService.getUserDocument(user.uid);
    final userRole = (userDoc?['role'] as String? ?? 'admin').toLowerCase();
    final userName = userDoc?['name'] as String? ?? user.displayName ?? (userRole == 'teacher' ? 'Teacher' : 'Admin');

    final incidentDateFormatted = '${_incidentDate.day} ${_monthName(_incidentDate.month)} ${_incidentDate.year}';

    bool success = false;
    if (widget.complaintToEdit == null) {
      success = await _viewModel.createComplaint(
        studentId: _selectedStudentId!,
        classId: _selectedClassId!,
        type: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        incidentDate: incidentDateFormatted,
        resolutionNote: _actionTakenController.text.trim(),
        createdBy: user.uid,
        createdByName: userName,
        createdByRole: userRole,
      );
    } else {
      success = await _viewModel.updateComplaint(
        complaintId: widget.complaintToEdit!.complaintId,
        studentId: _selectedStudentId!,
        classId: _selectedClassId!,
        type: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: widget.complaintToEdit!.status,
        resolutionNote: _actionTakenController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.complaintToEdit == null ? 'Complaint submitted successfully.' : 'Complaint updated.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
      Navigator.of(context).pop(true);
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedClass = _availableClasses.firstWhere(
      (c) => c.classId == _selectedClassId,
      orElse: () => ClassModel(classId: '', className: '', standard: '', medium: '', academicYear: ''),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: widget.isModal ? 12 : 0,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle Pill (Screenshot 2)
            if (widget.isModal) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Modal Header Title (Screenshot 2)
            Text(
              widget.complaintToEdit == null ? 'Report Student Issue' : 'Edit Student Issue',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 20),

            // 1. SELECT CLASS DROPDOWN (Screenshot 2)
            _isLoadingClasses
                ? const LinearProgressIndicator(color: AppColors.primaryEmerald)
                : DropdownButtonFormField<String>(
                    initialValue: _selectedClassId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Class *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w600),
                    items: _availableClasses.map((cls) {
                      return DropdownMenuItem(
                        value: cls.classId,
                        child: Text(cls.className, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _onClassSelected(val);
                    },
                    validator: (val) => (val == null || val.isEmpty) ? 'Please select a class' : null,
                  ),
            const SizedBox(height: 14),

            // 2. SELECT STUDENT DROPDOWN (Class-First Behavior, Screenshot 2)
            _isLoadingStudents
                ? const LinearProgressIndicator(color: AppColors.primaryEmerald)
                : DropdownButtonFormField<String>(
                    initialValue: _selectedStudentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Student *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabled: _selectedClassId != null && _studentsInSelectedClass.isNotEmpty,
                    ),
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w600),
                    items: _studentsInSelectedClass.map((st) {
                      return DropdownMenuItem(
                        value: st.studentId,
                        child: Text(
                          selectedClass.className.isNotEmpty ? '${st.name} (${selectedClass.className})' : st.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (_selectedClassId != null && _studentsInSelectedClass.isNotEmpty)
                        ? (val) {
                            if (val != null) setState(() => _selectedStudentId = val);
                          }
                        : null,
                    validator: (val) => (val == null || val.isEmpty) ? 'Please select a student' : null,
                  ),
            if (_selectedClassId != null && _studentsInSelectedClass.isEmpty && !_isLoadingClasses && !_isLoadingStudents) ...[
              const SizedBox(height: 4),
              const Text('No students found in this class.', style: TextStyle(fontSize: 11, color: AppColors.error)),
            ],
            const SizedBox(height: 14),

            // 3. ISSUE TITLE (Screenshot 2)
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Issue Title *',
                hintText: 'e.g. Homework not completed',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.textMain, fontWeight: FontWeight.w600),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter issue title' : null,
            ),
            const SizedBox(height: 14),

            // 4. CATEGORY & PRIORITY DROPDOWNS ROW (Screenshot 2)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                    items: ['Academic', 'Homework', 'Discipline', 'Behavior', 'Fees', 'Other'].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                    items: ['Low', 'Medium', 'High'].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5. INCIDENT DATE PICKER (Screenshot 2)
            InkWell(
              onTap: _selectIncidentDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Incident Date *',
                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryEmerald, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                child: Text(
                  '${_incidentDate.day} ${_monthName(_incidentDate.month)} ${_incidentDate.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 6. DESCRIBE THE ISSUE (Screenshot 2)
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe the issue *',
                hintText: 'Provide details about the incident...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please describe the issue' : null,
            ),
            const SizedBox(height: 14),

            // 7. ACTION TAKEN (OPTIONAL) (Screenshot 2)
            TextFormField(
              controller: _actionTakenController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Action Taken (Optional)',
                hintText: 'e.g. Spoke with student and assigned corrective practice.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
            ),
            const SizedBox(height: 24),

            // SUBMIT COMPLAINT BUTTON (Screenshot 2)
            PrimaryButton(
              text: 'Submit Complaint',
              isLoading: _viewModel.isSaving,
              onPressed: _viewModel.isSaving ? null : _handleSubmit,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
