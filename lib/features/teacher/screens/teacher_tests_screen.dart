import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class TeacherTestsScreen extends StatefulWidget {
  const TeacherTestsScreen({super.key});

  @override
  State<TeacherTestsScreen> createState() => _TeacherTestsScreenState();
}

class _TeacherTestsScreenState extends State<TeacherTestsScreen> {
  String _selectedClass = 'All Classes';
  String _selectedSubject = 'All Subjects';
  String _activeStatus = 'All'; // 'All', 'Upcoming', 'Completed'

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _classList = ['All Classes', 'Class 11-B', 'Class 10-B'];
  final List<String> _subjectList = ['All Subjects', 'Gujarati', 'Mathematics', 'English'];

  final List<Map<String, dynamic>> _mockTests = [
    {
      'id': 'TST1',
      'title': 'Unit Test 3 - Geometry',
      'subject': 'Gujarati',
      'class': 'Class 11-B',
      'date': '15 Oct 2026',
      'maxMarks': 50,
      'evaluatedCount': 0,
      'totalStudents': 50,
      'status': 'Upcoming',
      'average': '-',
      'passed': 0,
      'failed': 0,
    },
    {
      'id': 'TST2',
      'title': 'Unit Test 2 - Grammar',
      'subject': 'Gujarati',
      'class': 'Class 11-B',
      'date': '7 Oct 2026',
      'maxMarks': 50,
      'evaluatedCount': 50,
      'totalStudents': 50,
      'status': 'Completed',
      'average': '38.6',
      'passed': 44,
      'failed': 6,
    },
    {
      'id': 'TST3',
      'title': 'Mid-Term Assessment',
      'subject': 'Mathematics',
      'class': 'Class 10-B',
      'date': '25 Sep 2026',
      'maxMarks': 100,
      'evaluatedCount': 50,
      'totalStudents': 50,
      'status': 'Completed',
      'average': '74.2',
      'passed': 46,
      'failed': 4,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  List<Map<String, dynamic>> get _filteredTests {
    return _mockTests.where((test) {
      if (_selectedClass != 'All Classes' && test['class'] != _selectedClass) {
        return false;
      }
      if (_selectedSubject != 'All Subjects' && test['subject'] != _selectedSubject) {
        return false;
      }
      if (_activeStatus != 'All' && test['status'] != _activeStatus) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final title = (test['title'] as String).toLowerCase();
        final subject = (test['subject'] as String).toLowerCase();
        if (!title.contains(q) && !subject.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _getEmptyMessage() {
    if (_searchQuery.trim().isNotEmpty) {
      return 'No tests found.';
    }
    switch (_activeStatus) {
      case 'Upcoming':
        return 'No upcoming tests.';
      case 'Completed':
        return 'No completed tests.';
      case 'All':
      default:
        return 'No tests created yet.';
    }
  }

  void _confirmDeleteTest(Map<String, dynamic> test) {
    final bool isCompleted = test['status'] == 'Completed';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Test?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: Text(
            isCompleted
                ? 'This will remove the test and its result records. Are you sure you want to continue?'
                : 'Are you sure you want to delete this test?',
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
                  _mockTests.removeWhere((t) => t['id'] == test['id']);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Test deleted.'),
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
              child: const Text('Delete Test', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTestModal() {
    final titleController = TextEditingController();
    final maxMarksController = TextEditingController(text: '50');
    String chosenClass = 'Class 11-B';
    String chosenSubject = 'Gujarati';
    DateTime chosenDate = DateTime(2026, 10, 15);

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
                    'Create Class Test',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                    decoration: InputDecoration(
                      labelText: 'Test Title',
                      hintText: 'e.g. Unit Test 4',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: chosenClass,
                          decoration: InputDecoration(
                            labelText: 'Class',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['Class 11-B', 'Class 10-B']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) chosenClass = v;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: chosenSubject,
                          decoration: InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ['Gujarati', 'Mathematics', 'English']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) chosenSubject = v;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Test Date Field with Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: chosenDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2028),
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
                          chosenDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Test Date',
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
                        '${chosenDate.day} ${_monthName(chosenDate.month)} ${chosenDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: maxMarksController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                    decoration: InputDecoration(
                      labelText: 'Maximum Marks',
                      hintText: 'e.g. 50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        final formattedDate =
                            '${chosenDate.day} ${_monthName(chosenDate.month)} ${chosenDate.year}';

                        setState(() {
                          _mockTests.insert(0, {
                            'id': 'TST${DateTime.now().millisecondsSinceEpoch}',
                            'title': titleController.text.trim(),
                            'subject': chosenSubject,
                            'class': chosenClass,
                            'date': formattedDate,
                            'maxMarks': int.tryParse(maxMarksController.text) ?? 50,
                            'evaluatedCount': 0,
                            'totalStudents': 50,
                            'status': 'Upcoming',
                            'average': '-',
                            'passed': 0,
                            'failed': 0,
                          });
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Test scheduled for $formattedDate'),
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
                      child: const Text('Schedule Test', style: AppTextStyles.button),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- UPCOMING MARKS ENTRY FLOW ---
  void _openUpcomingMarksEntryFlow(Map<String, dynamic> test) {
    int step = 0; // 0 = Marks Entry, 1 = Review Results
    String studentSearch = '';
    final int maxMarks = test['maxMarks'] as int;

    final List<Map<String, dynamic>> studentMarks = [
      {'id': 'STU1', 'name': 'Raj Kumar', 'rollNo': '101', 'marks': 42, 'isAbsent': false, 'remark': 'Good improvement'},
      {'id': 'STU2', 'name': 'Priya Sharma', 'rollNo': '102', 'marks': 38, 'isAbsent': false, 'remark': null},
      {'id': 'STU3', 'name': 'Aman Verma', 'rollNo': '103', 'marks': null, 'isAbsent': true, 'remark': 'Absent due to illness'},
      {'id': 'STU4', 'name': 'Neha Gupta', 'rollNo': '104', 'marks': 45, 'isAbsent': false, 'remark': null},
      {'id': 'STU5', 'name': 'Rohan Shah', 'rollNo': '105', 'marks': null, 'isAbsent': false, 'remark': null},
    ];

    void showRemarkModal(Map<String, dynamic> student, StateSetter setModalState) {
      final remarkController = TextEditingController(text: student['remark'] as String? ?? '');

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Student Remark',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student: ${student['name']} (Roll: ${student['rollNo']})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                  decoration: InputDecoration(
                    labelText: 'Remark (Optional)',
                    hintText: 'e.g. Good improvement, Needs more practice',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = remarkController.text.trim();
                  setModalState(() {
                    student['remark'] = text.isNotEmpty ? text : null;
                  });
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Remark'),
              ),
            ],
          );
        },
      );
    }

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
            final int evaluated = studentMarks.where((s) => s['marks'] != null || (s['isAbsent'] as bool)).length;
            final int absent = studentMarks.where((s) => s['isAbsent'] as bool).length;
            final int missing = studentMarks.where((s) => s['marks'] == null && !(s['isAbsent'] as bool)).length;
            final int remarksCount = studentMarks.where((s) => s['remark'] != null && (s['remark'] as String).trim().isNotEmpty).length;

            final List<int> scores = studentMarks
                .where((s) => s['marks'] != null && !(s['isAbsent'] as bool))
                .map((s) => s['marks'] as int)
                .toList();

            final double avg = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0;
            final int highest = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;
            final int lowest = scores.isNotEmpty ? scores.reduce((a, b) => a < b ? a : b) : 0;

            final int passCutoff = (maxMarks * 0.4).round();
            final int passed = scores.where((m) => m >= passCutoff).length;
            final int failed = scores.where((m) => m < passCutoff).length;

            final filteredStudents = studentMarks.where((s) {
              if (studentSearch.trim().isEmpty) return true;
              final q = studentSearch.trim().toLowerCase();
              return (s['name'] as String).toLowerCase().contains(q) ||
                  (s['rollNo'] as String).toLowerCase().contains(q);
            }).toList();

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
                      Text(
                        test['title'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${test['subject']} · ${test['class']} · Date: ${test['date']} · Max Marks: $maxMarks',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (step == 0) ...[
                        // STEP 0 — MARKS ENTRY
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStat('Evaluated', '$evaluated/${studentMarks.length}'),
                              _buildMiniStat('Avg', avg.toStringAsFixed(1)),
                              _buildMiniStat('Passed', '$passed'),
                              _buildMiniStat('Failed', '$failed'),
                              _buildMiniStat('Absent', '$absent'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Search student
                        TextField(
                          style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                          decoration: InputDecoration(
                            hintText: 'Search student by name or roll no.',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              studentSearch = val;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        Expanded(
                          child: filteredStudents.isEmpty
                              ? const Center(
                                  child: Text('No students found.', style: TextStyle(color: AppColors.textSecondary)),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  itemCount: filteredStudents.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final s = filteredStudents[index];
                                    final bool isAb = s['isAbsent'] as bool;
                                    final int? m = s['marks'] as int?;
                                    final String? remark = s['remark'] as String?;
                                    final bool hasRemark = remark != null && remark.trim().isNotEmpty;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      s['name'] as String,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.textMain,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Roll No: ${s['rollNo']}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: isAb,
                                                    activeColor: AppColors.error,
                                                    onChanged: (val) {
                                                      setModalState(() {
                                                        s['isAbsent'] = val ?? false;
                                                        if (val == true) s['marks'] = null;
                                                      });
                                                    },
                                                  ),
                                                  const Text('Absent', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              if (!isAb)
                                                SizedBox(
                                                  width: 58,
                                                  height: 36,
                                                  child: TextField(
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    controller: TextEditingController(text: m != null ? '$m' : '')
                                                      ..selection = TextSelection.collapsed(offset: (m != null ? '$m' : '').length),
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                                    decoration: InputDecoration(
                                                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    onChanged: (val) {
                                                      final parsed = int.tryParse(val);
                                                      if (parsed != null && parsed <= maxMarks) {
                                                        setModalState(() {
                                                          s['marks'] = parsed;
                                                        });
                                                      } else if (val.isEmpty) {
                                                        setModalState(() {
                                                          s['marks'] = null;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () => showRemarkModal(s, setModalState),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: hasRemark
                                                        ? AppColors.lightEmerald
                                                        : AppColors.background,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: hasRemark ? AppColors.primaryEmerald : AppColors.border,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        hasRemark ? Icons.check_circle_outline_rounded : Icons.chat_bubble_outline_rounded,
                                                        size: 13,
                                                        color: hasRemark ? AppColors.darkEmerald : AppColors.textSecondary,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        hasRemark ? 'Remark Added' : 'Remark',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: hasRemark ? AppColors.darkEmerald : AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (hasRemark) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Remark: "$remark"',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.darkEmerald,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                step = 1;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Review Results', style: AppTextStyles.button),
                          ),
                        ),
                      ] else ...[
                        // STEP 1 — REVIEW & CONFIRM
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
                              const Text(
                                'Result Review Summary',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                              ),
                              const SizedBox(height: 12),
                              _buildReviewRow('Total Students', '${studentMarks.length}'),
                              _buildReviewRow('Evaluated', '$evaluated'),
                              _buildReviewRow('Missing Marks', '$missing', isWarning: missing > 0),
                              _buildReviewRow('Absent Students', '$absent'),
                              _buildReviewRow('Student Remarks Added', '$remarksCount'),
                              _buildReviewRow('Class Average', '${avg.toStringAsFixed(1)} / $maxMarks'),
                              _buildReviewRow('Highest Score', '$highest'),
                              _buildReviewRow('Lowest Score', '$lowest'),
                              _buildReviewRow('Passed Students', '$passed'),
                              _buildReviewRow('Failed Students', '$failed'),
                            ],
                          ),
                        ),
                        if (missing > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                                const SizedBox(width: 8),
                                Text(
                                  '$missing students still need marks.',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    step = 0;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Back to Marks', style: TextStyle(color: AppColors.textMain)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _confirmCompleteTest(test, avg.toStringAsFixed(1), passed, failed);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryEmerald,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Complete Test', style: AppTextStyles.button),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  void _confirmCompleteTest(Map<String, dynamic> test, String avg, int passed, int failed) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Complete this test?'),
          content: const Text(
            'After completion, the test will appear in Completed and its result summary will be available.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  test['status'] = 'Completed';
                  test['evaluatedCount'] = test['totalStudents'];
                  test['average'] = avg;
                  test['passed'] = passed;
                  test['failed'] = failed;
                });
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Test marked as Completed!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Test'),
            ),
          ],
        );
      },
    );
  }

  // --- COMPLETED TEST RESULT SUMMARY FLOW ---
  void _openCompletedResultSummary(Map<String, dynamic> test) {
    String searchResultQuery = '';

    final List<Map<String, dynamic>> mockStudentResults = [
      {'name': 'Raj Kumar', 'rollNo': '101', 'marks': 42, 'max': test['maxMarks'], 'percentage': 84, 'grade': 'A', 'result': 'Pass', 'needsAttention': false, 'remark': 'Good improvement in geometry.'},
      {'name': 'Priya Sharma', 'rollNo': '102', 'marks': 38, 'max': test['maxMarks'], 'percentage': 76, 'grade': 'B+', 'result': 'Pass', 'needsAttention': false, 'remark': null},
      {'name': 'Aman Verma', 'rollNo': '103', 'marks': 17, 'max': test['maxMarks'], 'percentage': 34, 'grade': 'F', 'result': 'Fail', 'needsAttention': true, 'remark': 'Absent due to illness.'},
      {'name': 'Neha Gupta', 'rollNo': '104', 'marks': 45, 'max': test['maxMarks'], 'percentage': 90, 'grade': 'A+', 'result': 'Pass', 'needsAttention': false, 'remark': 'Outstanding performance.'},
      {'name': 'Jay Shah', 'rollNo': '105', 'marks': 21, 'max': test['maxMarks'], 'percentage': 42, 'grade': 'C', 'result': 'Pass', 'needsAttention': true, 'remark': 'Low performance. Practice recommended.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSummaryState) {
            final filteredResults = mockStudentResults.where((s) {
              if (searchResultQuery.trim().isEmpty) return true;
              final q = searchResultQuery.trim().toLowerCase();
              return (s['name'] as String).toLowerCase().contains(q) ||
                  (s['rollNo'] as String).toLowerCase().contains(q);
            }).toList();

            final needsAttentionList = mockStudentResults.where((s) => s['needsAttention'] as bool).toList();

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test['title'] as String,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${test['subject']} · ${test['class']} · Date: ${test['date']} · Max Marks: ${test['maxMarks']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightEmerald,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '✓ Completed',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkEmerald),
                            ),
                          ),
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
                              // Summary Stats Grid
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildMetricColumn('Students', '${test['totalStudents']}'),
                                        _buildMetricColumn('Class Avg', '${test['average']}'),
                                        _buildMetricColumn('Highest', '48'),
                                        _buildMetricColumn('Lowest', '17'),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: AppColors.border),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildMetricColumn('Passed', '${test['passed']}', color: AppColors.success),
                                        _buildMetricColumn('Failed', '${test['failed']}', color: AppColors.error),
                                        _buildMetricColumn('Pass Rate', '88%', color: AppColors.primaryEmerald),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Performance Overview
                              const Text(
                                'Performance Overview',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildGradeTag('Excellent', '8'),
                                    _buildGradeTag('Good', '18'),
                                    _buildGradeTag('Average', '15'),
                                    _buildGradeTag('Needs Attention', '9', color: AppColors.error),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Needs Attention Section
                              if (needsAttentionList.isNotEmpty) ...[
                                const Text(
                                  'Needs Attention',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                ),
                                const SizedBox(height: 10),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: needsAttentionList.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final s = needsAttentionList[index];
                                    final String? remark = s['remark'] as String?;
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(s['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                                              Text('${s['percentage']}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                                            ],
                                          ),
                                          if (remark != null && remark.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Remark: "$remark"',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.error),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Student Performance List
                              const Text(
                                'Student Performance',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                                decoration: InputDecoration(
                                  hintText: 'Search student by name or roll no.',
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                                  ),
                                ),
                                onChanged: (val) {
                                  setSummaryState(() {
                                    searchResultQuery = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final res = filteredResults[index];
                                  final bool isFail = res['result'] == 'Fail';
                                  final String? remark = res['remark'] as String?;

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showIndividualResultDetailModal(res),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(res['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain)),
                                                      const SizedBox(height: 2),
                                                      Text('Roll No: ${res['rollNo']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text('${res['marks']} / ${res['max']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isFail ? AppColors.error : AppColors.primaryEmerald)),
                                                    Text('${res['percentage']}% · Grade ${res['grade']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isFail ? AppColors.error : AppColors.textSecondary)),
                                                  ],
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                              ],
                                            ),
                                            if (remark != null && remark.trim().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Teacher Remark: "$remark"',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
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

  void _showIndividualResultDetailModal(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool isFail = result['result'] == 'Fail';
        final String? remark = result['remark'] as String?;

        return Padding(
          padding: const EdgeInsets.all(20),
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
              Text(result['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain)),
              const SizedBox(height: 2),
              Text('Roll Number: ${result['rollNo']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildReviewRow('Marks Obtained', '${result['marks']} / ${result['max']}'),
                    _buildReviewRow('Percentage', '${result['percentage']}%'),
                    _buildReviewRow('Grade', result['grade'] as String),
                    _buildReviewRow('Result', result['result'] as String, isWarning: isFail),
                    if (remark != null && remark.trim().isNotEmpty)
                      _buildReviewRow('Teacher Remark', remark),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMain)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isWarning ? AppColors.error : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? AppColors.textMain)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildGradeTag(String label, String count, {Color? color}) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color ?? AppColors.primaryEmerald)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTests;

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
          'Tests & Marks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryEmerald),
            tooltip: 'Create Test',
            onPressed: _showAddTestModal,
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
                  // Filter Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedClass,
                                  isDense: true,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                  items: _classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedClass = v);
                                  },
                                ),
                              ),
                            ),
                            Container(width: 1, height: 28, color: AppColors.border),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSubject,
                                  isDense: true,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                                  items: _subjectList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _selectedSubject = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),
                        // Status Tabs
                        Row(
                          children: ['All', 'Upcoming', 'Completed'].map((status) {
                            final bool isSelected = _activeStatus == status;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeStatus = status),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryEmerald : AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isSelected ? AppColors.primaryEmerald : AppColors.border),
                                  ),
                                  child: Text(
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Search test...',
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
                  const SizedBox(height: 16),

                  // Filtered Test Cards List
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
                            final test = filtered[index];
                            final bool isCompleted = test['status'] == 'Completed';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (isCompleted) {
                                    _openCompletedResultSummary(test);
                                  } else {
                                    _openUpcomingMarksEntryFlow(test);
                                  }
                                },
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
                                          Expanded(
                                            child: Text(
                                              test['title'] as String,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isCompleted
                                                      ? AppColors.lightEmerald
                                                      : AppColors.border.withValues(alpha: 0.5),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  isCompleted ? '✓ Completed' : 'Upcoming',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isCompleted ? AppColors.darkEmerald : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                onSelected: (value) {
                                                  if (value == 'delete') {
                                                    _confirmDeleteTest(test);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                                        SizedBox(width: 8),
                                                        Text('Delete Test', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${test['subject']} · ${test['class']} · Date: ${test['date']}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1, color: AppColors.border),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Max Marks: ${test['maxMarks']} · ${test['evaluatedCount']} / ${test['totalStudents']} Evaluated',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMain),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                                        ],
                                      ),
                                      if (isCompleted) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Average: ${test['average']} · ${test['passed']} Passed · ${test['failed']} Failed',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
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
}
