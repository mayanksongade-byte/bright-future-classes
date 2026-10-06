import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TeacherComplaintsScreen extends StatefulWidget {
  const TeacherComplaintsScreen({super.key});

  @override
  State<TeacherComplaintsScreen> createState() =>
      _TeacherComplaintsScreenState();
}

class _TeacherComplaintsScreenState extends State<TeacherComplaintsScreen> {
  String _activeStatus = 'All'; // 'All', 'Open', 'Under Review', 'Resolved'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _mockComplaints = [
    {
      'id': 'CMP1',
      'studentName': 'Raj Kumar',
      'class': 'Class 11-B',
      'title': 'Homework not completed',
      'category': 'Homework',
      'description': 'Student did not submit homework for the third consecutive time.',
      'actionTaken': 'Spoke with the student and assigned corrective practice.',
      'incidentDate': '5 Oct 2026',
      'reportedDate': '7 Oct 2026',
      'resolvedDate': null,
      'status': 'Open',
      'priority': 'Medium',
      'history': [
        {'date': '7 Oct 2026', 'event': 'Complaint reported', 'status': 'Open'},
      ],
    },
    {
      'id': 'CMP2',
      'studentName': 'Aman Verma',
      'class': 'Class 11-B',
      'title': 'Disruption in Class',
      'category': 'Discipline',
      'description': 'Talking loudly during lecture session.',
      'actionTaken': 'Gave verbal warning and informed parent.',
      'incidentDate': '2 Oct 2026',
      'reportedDate': '3 Oct 2026',
      'resolvedDate': '8 Oct 2026',
      'status': 'Resolved',
      'priority': 'High',
      'history': [
        {'date': '3 Oct 2026', 'event': 'Complaint reported', 'status': 'Open'},
        {'date': '5 Oct 2026', 'event': 'Reviewed with student', 'status': 'Under Review'},
        {'date': '8 Oct 2026', 'event': 'Issue resolved with parent call', 'status': 'Resolved'},
      ],
    },
    {
      'id': 'CMP3',
      'studentName': 'Priya Sharma',
      'class': 'Class 10-B',
      'title': 'Low Test Performance',
      'category': 'Academic',
      'description': 'Scored below passing threshold in Gujarati unit assessment.',
      'actionTaken': 'Recommended remedial classes.',
      'incidentDate': '8 Oct 2026',
      'reportedDate': '9 Oct 2026',
      'resolvedDate': null,
      'status': 'Under Review',
      'priority': 'High',
      'history': [
        {'date': '9 Oct 2026', 'event': 'Complaint reported', 'status': 'Open'},
        {'date': '10 Oct 2026', 'event': 'Under teacher review', 'status': 'Under Review'},
      ],
    },
  ];

  final List<String> _categories = [
    'Academic',
    'Attendance',
    'Discipline',
    'Behaviour',
    'Homework',
    'Other'
  ];

  final List<Map<String, String>> _studentsList = [
    {'name': 'Raj Kumar', 'class': 'Class 11-B'},
    {'name': 'Priya Sharma', 'class': 'Class 11-B'},
    {'name': 'Aman Verma', 'class': 'Class 11-B'},
    {'name': 'Neha Gupta', 'class': 'Class 11-B'},
    {'name': 'Rohan Shah', 'class': 'Class 10-B'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredComplaints {
    return _mockComplaints.where((c) {
      if (_activeStatus != 'All' && c['status'] != _activeStatus) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final name = (c['studentName'] as String).toLowerCase();
        final title = (c['title'] as String).toLowerCase();
        if (!name.contains(q) && !title.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int get _openCount =>
      _mockComplaints.where((c) => c['status'] == 'Open').length;
  int get _highPriorityCount =>
      _mockComplaints.where((c) => c['priority'] == 'High').length;
  int get _underReviewCount =>
      _mockComplaints.where((c) => c['status'] == 'Under Review').length;

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _confirmDeleteComplaint(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Complaint?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: const Text(
            'This complaint has been resolved. Are you sure you want to remove it from the complaint list?',
            style: AppTextStyles.subtitle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mockComplaints.removeWhere((c) => c['id'] == complaint['id']);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Complaint deleted.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete Complaint', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showReportComplaintModal() {
    String selectedStudent = _studentsList.first['name']!;
    String selectedStudentClass = _studentsList.first['class']!;
    String selectedCategory = _categories.first;
    String selectedPriority = 'Medium';
    DateTime incidentDate = DateTime.now();

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final actionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Text(
                      'Report Student Issue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Student Selector
                    DropdownButtonFormField<String>(
                      initialValue: selectedStudent,
                      decoration: InputDecoration(
                        labelText: 'Select Student *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _studentsList
                          .map((s) => DropdownMenuItem(
                                value: s['name'],
                                child: Text('${s['name']} (${s['class']})'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            selectedStudent = v;
                            final found = _studentsList.firstWhere((s) => s['name'] == v);
                            selectedStudentClass = found['class']!;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                      decoration: InputDecoration(
                        labelText: 'Issue Title *',
                        hintText: 'e.g. Homework not submitted',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category & Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedCategory = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedPriority,
                            decoration: InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['Low', 'Medium', 'High']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setModalState(() => selectedPriority = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Incident Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: incidentDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryEmerald,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            incidentDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Incident Date *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.primaryEmerald,
                          ),
                        ),
                        child: Text(
                          '${incidentDate.day} ${_monthName(incidentDate.month)} ${incidentDate.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                      decoration: InputDecoration(
                        labelText: 'Describe the issue *',
                        hintText: 'Describe what happened...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Taken (Optional)
                    TextField(
                      controller: actionController,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                      decoration: InputDecoration(
                        labelText: 'Action Taken (Optional)',
                        hintText: 'e.g. Spoke with student and gave warning',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty ||
                              descController.text.trim().isEmpty) {
                            return;
                          }
                          final formattedDate =
                              '${incidentDate.day} ${_monthName(incidentDate.month)} ${incidentDate.year}';

                          setState(() {
                            _mockComplaints.insert(0, {
                              'id': 'CMP${DateTime.now().millisecondsSinceEpoch}',
                              'studentName': selectedStudent,
                              'class': selectedStudentClass,
                              'title': titleController.text.trim(),
                              'category': selectedCategory,
                              'description': descController.text.trim(),
                              'actionTaken': actionController.text.trim().isNotEmpty
                                  ? actionController.text.trim()
                                  : null,
                              'incidentDate': formattedDate,
                              'reportedDate': 'Today',
                              'resolvedDate': null,
                              'status': 'Open',
                              'priority': selectedPriority,
                              'history': [
                                {'date': 'Today', 'event': 'Complaint reported', 'status': 'Open'},
                              ],
                            });
                          });

                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Issue reported successfully'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Submit Complaint', style: AppTextStyles.button),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showComplaintDetailsModal(Map<String, dynamic> complaint) {
    final actionInputController = TextEditingController(text: complaint['actionTaken'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDetailsState) {
            final String status = complaint['status'] as String;
            final String priority = complaint['priority'] as String;
            final String? actionTaken = complaint['actionTaken'] as String?;
            final List<Map<String, dynamic>> history =
                List<Map<String, dynamic>>.from(complaint['history'] as List? ?? []);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                complaint['studentName'] as String,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                complaint['class'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Issue Details Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      complaint['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildDetailRow('Category', complaint['category'] as String),
                                    _buildDetailRow('Incident Date', complaint['incidentDate'] as String),
                                    _buildDetailRow('Priority', priority, priorityColor: _getPriorityColor(priority)),
                                    _buildDetailRow('Reported Date', complaint['reportedDate'] as String),
                                    if (complaint['resolvedDate'] != null)
                                      _buildDetailRow('Resolved Date', complaint['resolvedDate'] as String),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Description Section
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  complaint['description'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMain,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Action Taken Section
                              if (actionTaken != null && actionTaken.isNotEmpty) ...[
                                const Text(
                                  'Action Taken',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightEmerald,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    actionTaken,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkEmerald,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Activity History
                              const Text(
                                'Activity History',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: history.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final ev = history[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 16,
                                          color: AppColors.primaryEmerald,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${ev['event']} (${ev['date']})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Teacher Actions
                              if (status == 'Open') ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        complaint['status'] = 'Under Review';
                                        history.add({
                                          'date': 'Today',
                                          'event': 'Under teacher review',
                                          'status': 'Under Review'
                                        });
                                      });
                                      setDetailsState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryEmerald,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Mark Under Review'),
                                  ),
                                ),
                              ] else if (status == 'Under Review') ...[
                                Column(
                                  children: [
                                    TextField(
                                      controller: actionInputController,
                                      decoration: InputDecoration(
                                        labelText: 'Action Taken Notes (Optional)',
                                        hintText: 'e.g. Discussed with student and parent',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            complaint['status'] = 'Resolved';
                                            complaint['resolvedDate'] = 'Today';
                                            if (actionInputController.text.trim().isNotEmpty) {
                                              complaint['actionTaken'] = actionInputController.text.trim();
                                            }
                                            history.add({
                                              'date': 'Today',
                                              'event': 'Issue resolved by teacher',
                                              'status': 'Resolved'
                                            });
                                          });
                                          setDetailsState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Mark Resolved'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightEmerald,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.darkEmerald, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        '✓ Resolved on ${complaint['resolvedDate'] ?? 'Recently'}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkEmerald),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? priorityColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: priorityColor ?? AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return Colors.amber.shade700;
      case 'Low':
      default:
        return AppColors.primaryEmerald;
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'Resolved':
        bg = AppColors.lightEmerald;
        fg = AppColors.darkEmerald;
        break;
      case 'Under Review':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade800;
        break;
      case 'Open':
      default:
        bg = AppColors.error.withValues(alpha: 0.1);
        fg = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status == 'Resolved' ? '✓ Resolved' : status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    if (_searchQuery.trim().isNotEmpty) {
      return 'No complaints found.';
    }
    switch (_activeStatus) {
      case 'Open':
        return 'No open complaints.';
      case 'Under Review':
        return 'No complaints under review.';
      case 'Resolved':
        return 'No resolved complaints.';
      case 'All':
      default:
        return 'No complaints recorded yet.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredComplaints;

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
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryEmerald),
            tooltip: 'Report Issue',
            onPressed: _showReportComplaintModal,
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Needs Attention Summary Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryText('Open', '$_openCount', AppColors.error),
                        Container(width: 1, height: 20, color: AppColors.border),
                        _buildSummaryText('High Priority', '$_highPriorityCount', Colors.amber.shade800),
                        Container(width: 1, height: 20, color: AppColors.border),
                        _buildSummaryText('Under Review', '$_underReviewCount', AppColors.primaryEmerald),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Search student or complaint...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 14),

                  // Status Filter Tabs
                  Row(
                    children: ['All', 'Open', 'Under Review', 'Resolved'].map((status) {
                      final bool isSelected = _activeStatus == status;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeStatus = status),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryEmerald : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? AppColors.primaryEmerald : AppColors.border),
                            ),
                            child: Text(
                              status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Complaint List
                  filtered.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _getEmptyMessage(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final complaint = filtered[index];
                            final bool isResolved = complaint['status'] == 'Resolved';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showComplaintDetailsModal(complaint),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                complaint['studentName'] as String,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                complaint['class'] as String,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              _buildStatusChip(complaint['status'] as String),
                                              if (isResolved) ...[
                                                PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  onSelected: (value) {
                                                    if (value == 'delete') {
                                                      _confirmDeleteComplaint(complaint);
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                                          SizedBox(width: 8),
                                                          Text('Delete Complaint', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                      const SizedBox(height: 12),
                                      Text(
                                        complaint['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Incident: ${complaint['incidentDate']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              _buildPriorityChip(complaint['priority'] as String),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryText(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
