import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/services/firestore_service.dart';
import '../view_models/complaints_view_model.dart';
import 'add_edit_complaint_screen.dart';
import 'complaint_details_screen.dart';

class ComplaintsListScreen extends StatefulWidget {
  final String? studentId;
  const ComplaintsListScreen({super.key, this.studentId});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  late final ComplaintsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _userRole = 'admin';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _resolveUserAndFetch();
  }

  void _onViewModelChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChange);
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resolveUserAndFetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = widget.studentId ?? user.uid;
      final userDoc = await _firestoreService.getUserDocument(user.uid);
      _userRole = (userDoc?['role'] as String? ?? 'admin').toLowerCase();
    }
    await _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final complaints = _viewModel.filteredComplaints;
    final isStudent = _userRole == 'student';

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
          'Student Complaints',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          if (!isStudent)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryEmerald,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final created = await AddEditComplaintScreen.showReportIssueModal(
                        context,
                        preloadedClasses: _viewModel.classes,
                      );
                      if (created == true) {
                        _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId);
                      }
                    },
                    tooltip: 'Report Student Issue',
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: _viewModel.isLoading
            ? const Center(child: AppLoadingIndicator())
            : RefreshIndicator(
                onRefresh: () => _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId),
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SUMMARY STRIP CARD (Screenshot 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    count: '${_viewModel.openCount}',
                                    label: 'Open',
                                    countColor: AppColors.error,
                                  ),
                                ),
                                Container(width: 1, height: 32, color: AppColors.border),
                                Expanded(
                                  child: _buildSummaryItem(
                                    count: '${_viewModel.highPriorityCount}',
                                    label: 'High Priority',
                                    countColor: AppColors.warning,
                                  ),
                                ),
                                Container(width: 1, height: 32, color: AppColors.border),
                                Expanded(
                                  child: _buildSummaryItem(
                                    count: '${_viewModel.inReviewCount}',
                                    label: 'Under Review',
                                    countColor: AppColors.primaryEmerald,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. SEARCH FIELD (Screenshot 1)
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => _viewModel.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search student or complaint...',
                              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _viewModel.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              fillColor: AppColors.surface,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. FILTER TABS (Screenshot 1: All, Open, Under Review, Resolved)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: ['All', 'Open', 'Under Review', 'Resolved', 'Archived'].map((status) {
                                final isSelected = _viewModel.selectedStatusFilter == status;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () => _viewModel.setStatusFilter(status),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryEmerald : AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? AppColors.primaryEmerald : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. COMPLAINT CARDS LIST
                          _viewModel.errorMessage != null
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.error),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Unable to Load Complaints',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _viewModel.errorMessage!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : complaints.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.primaryEmerald),
                                      SizedBox(height: 12),
                                      Text(
                                        'No Complaints',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'No complaints found for your assigned classes.',
                                        style: AppTextStyles.subtitle,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: complaints.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final complaint = complaints[index];
                                    return _buildComplaintCard(complaint);
                                  },
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

  Widget _buildSummaryItem({required String count, required String label, required Color countColor}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: countColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    final studentName = _viewModel.studentNameMap[complaint.studentId] ?? 'Student';
    final className = _viewModel.classNameMap[complaint.classId] ?? 'Class';

    Color statusBg = const Color(0xFFFEE2E2);
    Color statusText = AppColors.error;
    String statusLabel = complaint.status;

    if (complaint.status.toLowerCase() == 'resolved') {
      statusBg = const Color(0xFFDCFCE7);
      statusText = AppColors.darkEmerald;
      statusLabel = '✓ Resolved';
    } else if (complaint.status.toLowerCase() == 'under review' || complaint.status.toLowerCase() == 'in review') {
      statusBg = const Color(0xFFFEF3C7);
      statusText = AppColors.warning;
      statusLabel = 'Under Review';
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusText = AppColors.error;
      statusLabel = 'Open';
    }

    Color priorityBg = AppColors.background;
    Color priorityText = AppColors.textSecondary;
    if (complaint.priority.toLowerCase() == 'high') {
      priorityBg = const Color(0xFFFEE2E2);
      priorityText = AppColors.error;
    } else if (complaint.priority.toLowerCase() == 'medium') {
      priorityBg = const Color(0xFFFEF3C7);
      priorityText = AppColors.warning;
    } else if (complaint.priority.toLowerCase() == 'low') {
      priorityBg = AppColors.lightEmerald;
      priorityText = AppColors.darkEmerald;
    }

    return InkWell(
      onTap: () async {
        final refreshed = await ComplaintDetailsScreen.showComplaintDetailsModal(
          context,
          complaint: complaint,
          userRole: _userRole,
          preloadedStudentName: studentName,
          preloadedClassName: className,
        );
        if (refreshed == true) {
          _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Student Name, Class, Status Badge, More Vert Menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusText,
                        ),
                      ),
                    ),
                    if (_userRole != 'student') ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) async {
                          if (val == 'details') {
                            final refreshed = await ComplaintDetailsScreen.showComplaintDetailsModal(
                              context,
                              complaint: complaint,
                              userRole: _userRole,
                              preloadedStudentName: studentName,
                              preloadedClassName: className,
                            );
                            if (refreshed == true) {
                              _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId);
                            }
                          } else if (val == 'edit') {
                            final refreshed = await showModalBottomSheet<bool>(
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
                                    complaintToEdit: complaint,
                                    preloadedClasses: _viewModel.classes,
                                  ),
                                ),
                              ),
                            );
                            if (refreshed == true) {
                              _viewModel.fetchComplaintsData(role: _userRole, userId: _currentUserId);
                            }
                          } else if (val == 'archive') {
                            final success = await _viewModel.archiveComplaint(complaint.complaintId, !complaint.isArchived);
                            if (!mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(complaint.isArchived ? 'Complaint restored.' : 'Complaint archived.'),
                                  backgroundColor: AppColors.primaryEmerald,
                                ),
                              );
                            }
                          } else if (val == 'delete') {
                            _confirmDeleteComplaint(complaint);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18, color: AppColors.textMain),
                                SizedBox(width: 8),
                                Text('View Details', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: AppColors.textMain),
                                SizedBox(width: 8),
                                Text('Edit Issue', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(complaint.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(complaint.isArchived ? 'Restore' : 'Archive'),
                              ],
                            ),
                          ),
                          if (_canDeleteComplaint(complaint))
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(fontSize: 13, color: AppColors.error)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Creator Info Label
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  complaint.createdByRole.toLowerCase() == 'admin'
                      ? 'Created by Admin: ${complaint.createdByName.isNotEmpty ? complaint.createdByName : 'Admin'}'
                      : 'Reported by: ${complaint.createdByName.isNotEmpty ? complaint.createdByName : 'Teacher'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (complaint.status.toLowerCase() == 'resolved') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.darkEmerald),
                  const SizedBox(width: 4),
                  Text(
                    complaint.resolvedByName != null && complaint.resolvedByName!.isNotEmpty
                        ? 'Resolved by ${complaint.resolvedByName} (${complaint.resolvedByRole != null && complaint.resolvedByRole!.isNotEmpty ? complaint.resolvedByRole!.toUpperCase() : "Staff"})'
                        : 'Resolved (Resolution details unavailable)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkEmerald,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Complaint Title
            Text(
              complaint.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 12),

            // Bottom Row: Incident Date, Priority, Chevron
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Incident: ${complaint.incidentDate.isNotEmpty ? complaint.incidentDate : AppDateFormatter.formatDate(complaint.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.priority,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: priorityText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteComplaint(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Complaint?'),
          content: Text('Are you sure you want to permanently delete "${complaint.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final success = await _viewModel.deleteComplaint(complaint.complaintId);
                if (!mounted) return;
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Complaint deleted permanently.'), backgroundColor: AppColors.success),
                  );
                } else if (_viewModel.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(_viewModel.errorMessage!), backgroundColor: AppColors.error),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  bool _canDeleteComplaint(ComplaintModel complaint) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (_userRole == 'admin') return true;

    if (_userRole == 'teacher') {
      final isCreatorUid = complaint.createdBy == user.uid;
      final isCreatorDoc = complaint.createdBy.isNotEmpty &&
          (complaint.createdBy == user.uid ||
           complaint.createdByName.trim().toLowerCase() == user.displayName?.trim().toLowerCase());
      return isCreatorUid || isCreatorDoc;
    }

    return false;
  }
}
