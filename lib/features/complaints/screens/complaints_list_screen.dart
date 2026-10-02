import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/complaint_model.dart';
import '../../../data/models/student_model.dart';
import '../view_models/complaints_view_model.dart';
import 'add_edit_complaint_screen.dart';
import 'complaint_details_screen.dart';

class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  late final ComplaintsViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ComplaintsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _viewModel.fetchComplaintsData();
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
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
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
    final complaints = _viewModel.filteredComplaints;
    final availableStudents = _viewModel.selectedClassFilter != null
        ? _viewModel.students
            .where((s) => s.classId == _viewModel.selectedClassFilter)
            .toList()
        : _viewModel.students;

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
          'Complaints',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const AddEditComplaintScreen(),
                  ),
                );
                if (created == true) {
                  _viewModel.fetchComplaintsData();
                }
              },
              icon: const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.primaryEmerald),
              label: const Text(
                'Add Complaint',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryEmerald,
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
                onRefresh: _viewModel.fetchComplaintsData,
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // COMPLAINT SUMMARY SECTION
                          const Text(
                            'Complaint Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 600;
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isWide ? 5 : 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: isWide ? 1.5 : 1.3,
                                children: [
                                  _buildSummaryCard(
                                      'Total', '${_viewModel.totalComplaints}', AppColors.primaryEmerald, AppColors.lightEmerald),
                                  _buildSummaryCard(
                                      'Open', '${_viewModel.openCount}', AppColors.warning, const Color(0xFFFEF3C7)),
                                  _buildSummaryCard(
                                      'In Review', '${_viewModel.inReviewCount}', AppColors.info, const Color(0xFFE0F2FE)),
                                  _buildSummaryCard(
                                      'Resolved', '${_viewModel.resolvedCount}', AppColors.success, const Color(0xFFDCFCE7)),
                                  _buildSummaryCard(
                                      'Closed', '${_viewModel.closedCount}', AppColors.textSecondary, AppColors.border),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // SEARCH & FILTER SECTION
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Search & Filter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _viewModel.clearFilters();
                                },
                                child: const Text('Clear Filters',
                                    style: TextStyle(
                                        color: AppColors.primaryEmerald,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            style: AppTextStyles.inputText,
                            onChanged: (val) => _viewModel.setSearchQuery(val),
                            decoration: InputDecoration(
                              hintText: 'Search by title, student name, or ID...',
                              hintStyle: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: AppColors.textSecondary),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              // Class filter
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _viewModel.selectedClassFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Class',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Classes',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    ..._viewModel.classes.map((cls) {
                                      return DropdownMenuItem<String?>(
                                        value: cls.classId,
                                        child: Text(cls.className,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) =>
                                      _viewModel.setClassFilter(val),
                                ),
                              ),
                              // Student filter
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _viewModel.selectedStudentFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Student',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Students',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    ...availableStudents.map((stu) {
                                      return DropdownMenuItem<String?>(
                                        value: stu.studentId,
                                        child: Text(stu.name,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) =>
                                      _viewModel.setStudentFilter(val),
                                ),
                              ),
                              // Status filter
                              SizedBox(
                                width: 160,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _viewModel.selectedStatusFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Status',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                                  items: [
                                    'All',
                                    'Open',
                                    'In Review',
                                    'Resolved',
                                    'Closed'
                                  ]
                                      .map((st) => DropdownMenuItem(
                                            value: st,
                                            child: Text(st,
                                                overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _viewModel.setStatusFilter(val);
                                    }
                                  },
                                ),
                              ),
                              // Type filter
                              SizedBox(
                                width: 160,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _viewModel.selectedTypeFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Type',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                                  items: [
                                    'All',
                                    'Academic',
                                    'Attendance',
                                    'Behavior',
                                    'Fees',
                                    'Other'
                                  ]
                                      .map((t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(t,
                                                overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _viewModel.setTypeFilter(val);
                                    }
                                  },
                                ),
                              ),
                              // Priority filter
                              SizedBox(
                                width: 160,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _viewModel.selectedPriorityFilter,
                                  isExpanded: true,
                                  style: AppTextStyles.inputText,
                                  decoration: InputDecoration(
                                    labelText: 'Priority',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
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
                                  items: [
                                    'All',
                                    'Low',
                                    'Medium',
                                    'High'
                                  ]
                                      .map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p,
                                                overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      _viewModel.setPriorityFilter(val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // COMPLAINT LIST HEADER
                          Text(
                            'Complaint List (${complaints.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          complaints.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: complaints.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const AddEditComplaintScreen(),
            ),
          );
          if (created == true) {
            _viewModel.fetchComplaintsData();
          }
        },
        backgroundColor: AppColors.primaryEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Complaint', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.report_problem_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No complaints found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try changing your search or filters, or add a new complaint.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Add Complaint',
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const AddEditComplaintScreen(),
                ),
              );
              if (created == true) {
                _viewModel.fetchComplaintsData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    final statusColor = _getStatusColor(complaint.status);
    final priorityColor = _getPriorityColor(complaint.priority);

    // Resolve student name
    final student = _viewModel.students.firstWhere(
      (s) => s.studentId == complaint.studentId,
      orElse: () => StudentModel(
        studentId: '',
        name: 'Student unavailable',
        phone: '',
        parentName: '',
        parentPhone: '',
      ),
    );

    // Resolve class name
    final cls = _viewModel.classes.firstWhere(
      (c) => c.classId == complaint.classId,
      orElse: () => ClassModel(
        classId: '',
        className: 'Class unavailable',
        standard: '',
        medium: '',
        academicYear: '',
      ),
    );

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComplaintDetailsScreen(complaint: complaint),
          ),
        );
        _viewModel.fetchComplaintsData();
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
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.report_gmailerrorred_rounded,
                          color: AppColors.primaryEmerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${student.name} • ${cls.className}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    complaint.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        complaint.type,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${complaint.priority} Priority',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Created: ${_formatDate(complaint.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
