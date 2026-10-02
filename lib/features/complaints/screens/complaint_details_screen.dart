import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../view_models/complaints_view_model.dart';
import 'add_edit_complaint_screen.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final ComplaintModel complaint;

  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  late ComplaintModel _complaint;
  late final ComplaintsViewModel _viewModel;
  late final ClassRepository _classRepository;
  late final StudentRepository _studentRepository;

  String _studentName = 'Loading student...';
  String _className = 'Loading class...';
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _classRepository = ClassRepository();
    _studentRepository = StudentRepository();
    _loadRelatedData();
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
    super.dispose();
  }

  Future<void> _loadRelatedData() async {
    try {
      final results = await Future.wait([
        _studentRepository.getStudents(),
        _classRepository.getClasses(),
      ]);
      final students = results[0] as List<StudentModel>;
      final classes = results[1] as List<ClassModel>;

      final studentMatch = students.firstWhere(
        (s) => s.studentId == _complaint.studentId,
        orElse: () => StudentModel(
          studentId: '',
          name: 'Student unavailable',
          phone: '',
          parentName: '',
          parentPhone: '',
        ),
      );

      final classMatch = classes.firstWhere(
        (c) => c.classId == _complaint.classId,
        orElse: () => ClassModel(
          classId: '',
          className: 'Class unavailable',
          standard: '',
          medium: '',
          academicYear: '',
        ),
      );

      if (mounted) {
        setState(() {
          _studentName = studentMatch.name;
          _className = classMatch.className;
          _isLoadingRelated = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _studentName = 'Student unavailable';
          _className = 'Class unavailable';
          _isLoadingRelated = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Complaint?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this complaint? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deleteComplaint(_complaint.complaintId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint deleted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (_viewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateStatusAndNote(String newStatus, {String? resolutionNote}) async {
    final success = await _viewModel.updateComplaint(
      complaintId: _complaint.complaintId,
      studentId: _complaint.studentId,
      classId: _complaint.classId,
      type: _complaint.type,
      title: _complaint.title,
      description: _complaint.description,
      priority: _complaint.priority,
      status: newStatus,
      resolutionNote: resolutionNote ?? _complaint.resolutionNote,
    );

    if (!mounted) return;

    if (success) {
      final fresh = await _viewModel.getComplaintById(_complaint.complaintId);
      if (!mounted) return;
      if (fresh != null) {
        setState(() {
          _complaint = fresh;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _promptResolutionNoteAndResolve() async {
    final controller = TextEditingController(text: _complaint.resolutionNote);
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Resolve Complaint'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter resolution note (e.g., Parent contacted...)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text('Resolve'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (note != null) {
      await _updateStatusAndNote('Resolved', resolutionNote: note);
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.warning;
      case 'in review':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(_complaint.status);
    final priorityColor = _getPriorityColor(_complaint.priority);

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
        title: const Text(
          'Complaint Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.primaryEmerald),
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditComplaintScreen(complaintToEdit: _complaint),
                ),
              );
              if (updated == true) {
                final fresh = await _viewModel.getComplaintById(_complaint.complaintId);
                if (fresh != null && mounted) {
                  setState(() {
                    _complaint = fresh;
                  });
                  _loadRelatedData();
                }
              }
            },
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
            onPressed: _confirmDelete,
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Complaint Title & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _complaint.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _complaint.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Priority & 6. Complaint Type
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _complaint.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_complaint.priority} Priority',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // 4. Student & 5. Class
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            label: 'Student',
                            value: _isLoadingRelated ? 'Loading...' : _studentName,
                            icon: Icons.person_outline_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoTile(
                            label: 'Class',
                            value: _isLoadingRelated ? 'Loading...' : _className,
                            icon: Icons.school_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 7. Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _complaint.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMain,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 8. Resolution Note (when available)
                    if (_complaint.resolutionNote.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resolution Note',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkEmerald,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _complaint.resolutionNote,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 9, 10, 11. Metadata
                    Text(
                      'Created By: ${_complaint.createdBy} (${_complaint.createdByRole})',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Created At: ${_formatDate(_complaint.createdAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated At: ${_formatDate(_complaint.updatedAt)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 28),

                    // Status Workflow Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_complaint.status == 'Open') ...[
                          OutlinedButton.icon(
                            onPressed: () => _updateStatusAndNote('In Review'),
                            icon: const Icon(Icons.rate_review_outlined, size: 16),
                            label: const Text('Mark In Review'),
                          ),
                        ],
                        if (_complaint.status == 'In Review') ...[
                          ElevatedButton.icon(
                            onPressed: _promptResolutionNoteAndResolve,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Resolve'),
                          ),
                        ],
                        if (_complaint.status == 'Resolved') ...[
                          OutlinedButton.icon(
                            onPressed: () => _updateStatusAndNote('Closed'),
                            icon: const Icon(Icons.lock_outline_rounded, size: 16),
                            label: const Text('Close'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _updateStatusAndNote('Open'),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reopen'),
                          ),
                        ],
                        if (_complaint.status == 'Closed') ...[
                          OutlinedButton.icon(
                            onPressed: () => _updateStatusAndNote('Open'),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reopen'),
                          ),
                        ],
                        OutlinedButton.icon(
                          onPressed: _confirmDelete,
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
