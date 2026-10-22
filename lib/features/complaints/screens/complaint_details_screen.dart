import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/complaints_view_model.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  final ComplaintModel complaint;
  final String userRole;
  final String? preloadedStudentName;
  final String? preloadedClassName;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaint,
    this.userRole = 'admin',
    this.preloadedStudentName,
    this.preloadedClassName,
  });

  /// Opens the complaint details as a modal bottom sheet matching Screenshots 3 and 4.
  static Future<bool?> showComplaintDetailsModal(
    BuildContext context, {
    required ComplaintModel complaint,
    String userRole = 'admin',
    String? preloadedStudentName,
    String? preloadedClassName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComplaintDetailsModal(
        complaint: complaint,
        userRole: userRole,
        preloadedStudentName: preloadedStudentName,
        preloadedClassName: preloadedClassName,
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
          onPressed: () => Navigator.of(context).pop(true),
          tooltip: 'Back',
        ),
        title: const Text(
          'Student Complaints',
          style: TextStyle(
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
              child: ComplaintDetailsContent(
                complaint: complaint,
                userRole: userRole,
                preloadedStudentName: preloadedStudentName,
                preloadedClassName: preloadedClassName,
                isModal: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ComplaintDetailsModal extends StatelessWidget {
  final ComplaintModel complaint;
  final String userRole;
  final String? preloadedStudentName;
  final String? preloadedClassName;

  const ComplaintDetailsModal({
    super.key,
    required this.complaint,
    this.userRole = 'admin',
    this.preloadedStudentName,
    this.preloadedClassName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 12,
            left: 20,
            right: 20,
          ),
          child: ComplaintDetailsContent(
            complaint: complaint,
            userRole: userRole,
            preloadedStudentName: preloadedStudentName,
            preloadedClassName: preloadedClassName,
            isModal: true,
          ),
        ),
      ),
    );
  }
}

class ComplaintDetailsContent extends StatefulWidget {
  final ComplaintModel complaint;
  final String userRole;
  final String? preloadedStudentName;
  final String? preloadedClassName;
  final bool isModal;

  const ComplaintDetailsContent({
    super.key,
    required this.complaint,
    this.userRole = 'admin',
    this.preloadedStudentName,
    this.preloadedClassName,
    this.isModal = false,
  });

  @override
  State<ComplaintDetailsContent> createState() => _ComplaintDetailsContentState();
}

class _ComplaintDetailsContentState extends State<ComplaintDetailsContent> {
  late ComplaintModel _complaint;
  late final ComplaintsViewModel _viewModel;
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _actionNotesController = TextEditingController();
  final TextEditingController _studentResponseController = TextEditingController();

  StudentModel? _student;
  ClassModel? _classModel;
  bool _isLoadingDetails = true;
  bool _hasMutated = false;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _actionNotesController.text = _complaint.resolutionNote;
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);

    _loadRelatedModels();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _actionNotesController.dispose();
    _studentResponseController.dispose();
    super.dispose();
  }

  Future<void> _loadRelatedModels() async {
    setState(() => _isLoadingDetails = true);
    try {
      final fresh = await _viewModel.getComplaintById(_complaint.complaintId);
      if (fresh != null) {
        _complaint = fresh;
        if (_actionNotesController.text.isEmpty && _complaint.resolutionNote.isNotEmpty) {
          _actionNotesController.text = _complaint.resolutionNote;
        }
      }

      // Targeted single-document get: avoids collection-wide queries that fail Teacher security rules
      if (_complaint.studentId.isNotEmpty) {
        final studentDoc = await _firestoreService.getStudentDocument(_complaint.studentId);
        if (studentDoc != null) {
          _student = StudentModel.fromMap(studentDoc, _complaint.studentId);
        }
      }

      if (_complaint.classId.isNotEmpty) {
        final classDoc = await _firestoreService.getClassDocument(_complaint.classId);
        if (classDoc != null) {
          _classModel = ClassModel.fromMap(classDoc, _complaint.classId);
        } else {
          _classModel = ClassModel(
            classId: _complaint.classId,
            className: _complaint.classId,
            standard: '',
            medium: '',
            academicYear: '',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ComplaintDetails] Error loading details: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _handleMarkResolved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firestoreService.getUserDocument(user.uid);
    final userName = userDoc?['name'] as String? ?? user.displayName ?? 'Staff';
    final role = (userDoc?['role'] as String? ?? widget.userRole).toLowerCase();

    final success = await _viewModel.resolveComplaint(
      complaintId: _complaint.complaintId,
      resolutionNote: _actionNotesController.text.trim(),
      resolvedBy: userName,
      resolvedByRole: role,
    );

    if (!mounted) return;

    if (success) {
      _hasMutated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint marked as resolved.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
      await _loadRelatedModels();
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleSubmitStudentResponse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _studentResponseController.text.trim();
    if (text.isEmpty) return;

    final userDoc = await _firestoreService.getUserDocument(user.uid);
    final studentName = userDoc?['name'] as String? ?? _student?.name ?? 'Student';

    final success = await _viewModel.submitStudentResponse(
      complaintId: _complaint.complaintId,
      responseText: text,
      studentUid: user.uid,
      studentName: studentName,
    );

    if (!mounted) return;

    if (success) {
      _hasMutated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response submitted successfully.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
      _studentResponseController.clear();
      await _loadRelatedModels();
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleAcknowledge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firestoreService.getUserDocument(user.uid);
    final studentName = userDoc?['name'] as String? ?? _student?.name ?? 'Student';

    final success = await _viewModel.acknowledgeComplaint(
      complaintId: _complaint.complaintId,
      studentUid: user.uid,
      studentName: studentName,
    );

    if (!mounted) return;

    if (success) {
      _hasMutated = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint acknowledged.'),
          backgroundColor: AppColors.primaryEmerald,
        ),
      );
      await _loadRelatedModels();
    } else if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.userRole == 'student';
    final isResolved = _complaint.status.toLowerCase() == 'resolved';

    Color statusBg = const Color(0xFFFEF3C7);
    Color statusText = AppColors.warning;
    String statusLabel = _complaint.status;

    if (isResolved) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = AppColors.darkEmerald;
      statusLabel = '✓ Resolved';
    } else if (_complaint.status.toLowerCase() == 'open') {
      statusBg = const Color(0xFFFEE2E2);
      statusText = AppColors.error;
      statusLabel = 'Open';
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusText = AppColors.warning;
      statusLabel = 'Under Review';
    }

    Color priorityColor = AppColors.warning;
    if (_complaint.priority.toLowerCase() == 'high') {
      priorityColor = AppColors.error;
    } else if (_complaint.priority.toLowerCase() == 'low') {
      priorityColor = AppColors.darkEmerald;
    }

    final reportedDateStr = _complaint.createdAt != null
        ? '${_complaint.createdAt!.day} ${_monthName(_complaint.createdAt!.month)} ${_complaint.createdAt!.year}'
        : 'N/A';

    final resolvedDateStr = _complaint.resolvedAt != null
        ? '${_complaint.resolvedAt!.day} ${_monthName(_complaint.resolvedAt!.month)} ${_complaint.resolvedAt!.year}'
        : '';

    final displayStudentName = _student?.name ?? widget.preloadedStudentName ?? 'Student';
    final displayClassName = _classModel?.className ?? widget.preloadedClassName ?? 'Class';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasMutated);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Pill for Modal (Screenshots 3 & 4)
          if (widget.isModal) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],

          if (_isLoadingDetails) ...[
            const LinearProgressIndicator(color: AppColors.primaryEmerald),
            const SizedBox(height: 12),
          ],

        // 1. STUDENT HEADER & STATUS BADGE (Screenshots 3 & 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayStudentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayClassName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. COMPLAINT SUMMARY CARD (Screenshots 3 & 4)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _complaint.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 14),
              _buildMetaRow('Category', _complaint.type, isBoldValue: true),
              const SizedBox(height: 8),
              _buildMetaRow(
                'Incident Date',
                _complaint.incidentDate.isNotEmpty ? _complaint.incidentDate : reportedDateStr,
              ),
              const SizedBox(height: 8),
              _buildMetaRow(
                'Priority',
                _complaint.priority,
                valueColor: priorityColor,
                isBoldValue: true,
              ),
              const SizedBox(height: 8),
              _buildMetaRow('Reported Date', reportedDateStr),
              if (isResolved && resolvedDateStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildMetaRow('Resolved Date', resolvedDateStr),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. DESCRIPTION SECTION (Screenshots 3 & 4)
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _complaint.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMain,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4. ACTION TAKEN SECTION (Screenshots 3 & 4)
        if (_complaint.resolutionNote.isNotEmpty) ...[
          const Text(
            'Action Taken',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightEmerald,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
            ),
            child: Text(
              _complaint.resolutionNote,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkEmerald,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 5. ACTIVITY HISTORY SECTION (Screenshots 3 & 4)
        const Text(
          'Activity History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 10),

        _complaint.activityHistory.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primaryEmerald,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complaint reported ($reportedDateStr)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _complaint.activityHistory.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final item = _complaint.activityHistory[idx];
                  final eventText = item['event'] as String? ?? '';
                  return Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primaryEmerald,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eventText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        const SizedBox(height: 24),

        // 6. RESOLUTION BANNER (Screenshot 4 for Resolved State)
        if (isResolved) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.lightEmerald,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryEmerald,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resolved on ${resolvedDateStr.isNotEmpty ? resolvedDateStr : reportedDateStr}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkEmerald,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 7. ADMIN / TEACHER ACTION SECTION (Screenshot 3 for Unresolved State)
        if (!isStudent && !isResolved) ...[
          const Text(
            'Action Taken Notes (Optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _actionNotesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Enter notes e.g. Spoke with student and parent...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textMain),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Mark Resolved',
            isLoading: _viewModel.isSaving,
            onPressed: _viewModel.isSaving ? null : _handleMarkResolved,
          ),
          const SizedBox(height: 20),
        ],

        // 8. STUDENT RESPONSE & ACKNOWLEDGEMENT SECTION
        if (isStudent) ...[
          if (_complaint.studentResponse != null && _complaint.studentResponse!.isNotEmpty) ...[
            const Text(
              'Your Submitted Response',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _complaint.studentResponse!,
                style: const TextStyle(fontSize: 13, color: AppColors.textMain, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!isResolved) ...[
            const Text(
              'Your Response',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _studentResponseController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain your side of the incident...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(14),
              ),
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _viewModel.isSaving ? null : _handleSubmitStudentResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Submit Response', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_complaint.isAcknowledged) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightEmerald,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primaryEmerald, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'You have acknowledged this complaint.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkEmerald),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'Acknowledgement confirms you have read this complaint. It does not mean you admit the allegation is true.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _viewModel.isSaving ? null : _handleAcknowledge,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Acknowledge Complaint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryEmerald,
                  side: const BorderSide(color: AppColors.primaryEmerald),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ],
    ),
  );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? AppColors.textMain,
          ),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
