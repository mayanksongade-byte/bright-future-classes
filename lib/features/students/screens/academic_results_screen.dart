import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_academic_result.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/test_repository.dart';
import '../../tests/screens/test_details_screen.dart';
import '../../tests/view_models/tests_view_model.dart';

class AcademicResultsScreen extends StatefulWidget {
  final StudentModel student;
  final ClassModel? classModel;
  final List<StudentAcademicResult> initialResults;

  const AcademicResultsScreen({
    super.key,
    required this.student,
    this.classModel,
    required this.initialResults,
  });

  @override
  State<AcademicResultsScreen> createState() => _AcademicResultsScreenState();
}

class _AcademicResultsScreenState extends State<AcademicResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TestRepository _testRepository = TestRepository();

  String _selectedSubject = 'All Subjects';
  String _selectedStatus = 'All';
  String _selectedSort = 'Newest First';

  late List<StudentAcademicResult> _allResults;

  @override
  void initState() {
    super.initState();
    _allResults = List.from(widget.initialResults);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _availableSubjects {
    final set = <String>{'All Subjects'};
    for (var r in _allResults) {
      if (r.test.subject.trim().isNotEmpty) {
        set.add(r.test.subject.trim());
      }
    }
    return set.toList()..sort((a, b) => a == 'All Subjects' ? -1 : a.compareTo(b));
  }

  List<StudentAcademicResult> get _filteredResults {
    var list = _allResults;

    // Subject Filter
    if (_selectedSubject != 'All Subjects') {
      list = list
          .where((r) => r.test.subject.trim().toLowerCase() == _selectedSubject.toLowerCase())
          .toList();
    }

    // Search Filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((r) => r.test.testName.toLowerCase().contains(query))
          .toList();
    }

    // Status Filter
    if (_selectedStatus == 'Pass') {
      list = list.where((r) => r.status == 'Pass').toList();
    } else if (_selectedStatus == 'Fail') {
      list = list.where((r) => r.status == 'Fail').toList();
    } else if (_selectedStatus == 'Pending') {
      list = list.where((r) => r.status == 'Pending').toList();
    } else if (_selectedStatus == 'Absent') {
      list = list.where((r) => r.isAbsent).toList();
    } else if (_selectedStatus == 'Archived') {
      list = list.where((r) => r.isArchived).toList();
    }

    // Sorting
    list = List.from(list);
    if (_selectedSort == 'Newest First') {
      list.sort((a, b) => b.test.testDate.compareTo(a.test.testDate));
    } else if (_selectedSort == 'Oldest First') {
      list.sort((a, b) => a.test.testDate.compareTo(b.test.testDate));
    } else if (_selectedSort == 'Subject') {
      list.sort((a, b) => a.test.subject.compareTo(b.test.subject));
    }

    return list;
  }

  Map<String, List<StudentAcademicResult>> get _groupedFilteredResults {
    final Map<String, List<StudentAcademicResult>> map = {};
    for (var r in _filteredResults) {
      final sub = r.test.subject.trim().isEmpty ? 'General' : r.test.subject.trim();
      map.putIfAbsent(sub, () => []).add(r);
    }
    return map;
  }

  Future<void> _openTestDetails(StudentAcademicResult res) async {
    try {
      final fullTest = await _testRepository.getTest(res.test.testId);
      if (fullTest != null && mounted) {
        final item = TestItem(
          test: fullTest,
          classModel: widget.classModel,
          marks: res.mark != null ? [res.mark!] : [],
          studentsInClass: [widget.student],
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TestDetailsScreen(testItem: item),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final groupedMap = _groupedFilteredResults;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.student.name} — Results',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            Text(
              '${widget.classModel?.className ?? "Class"} • Student ID: ${widget.student.studentId}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SEARCH & FILTERS CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search tests by name...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            fillColor: AppColors.background,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dropdowns Row: Subject & Sort
                        Row(
                          children: [
                            // Subject Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSubject,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Subject',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                                items: _availableSubjects.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSubject = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Sort Dropdown
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedSort,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Sort By',
                                  labelStyle: const TextStyle(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                style: const TextStyle(fontSize: 13, color: AppColors.textMain, fontWeight: FontWeight.w600),
                                items: ['Newest First', 'Oldest First', 'Subject'].map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSort = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Status Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: ['All', 'Pass', 'Fail', 'Pending', 'Absent', 'Archived'].map((status) {
                              final isSelected = _selectedStatus == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(status),
                                  selected: isSelected,
                                  onSelected: (_) => setState(() => _selectedStatus = status),
                                  selectedColor: AppColors.primaryEmerald,
                                  backgroundColor: AppColors.background,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.textMain,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primaryEmerald : AppColors.border,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // RESULTS BY SUBJECT
                  if (groupedMap.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
                          SizedBox(height: 12),
                          Text(
                            'No test results match your selected filters.',
                            style: AppTextStyles.subtitle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groupedMap.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final subject = groupedMap.keys.elementAt(index);
                        final subjectResults = groupedMap[subject]!;

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightEmerald,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primaryEmerald),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    subject,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      '${subjectResults.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                const Divider(height: 1, color: AppColors.border),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: subjectResults.length,
                                  separatorBuilder: (context, idx) => const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (context, idx) {
                                    final res = subjectResults[idx];
                                    return _buildTestCardRow(res);
                                  },
                                ),
                              ],
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

  Widget _buildTestCardRow(StudentAcademicResult res) {
    Color badgeColor = AppColors.info;
    Color badgeTextColor = AppColors.info;
    if (res.status == 'Pass') {
      badgeColor = AppColors.lightEmerald;
      badgeTextColor = AppColors.darkEmerald;
    } else if (res.status == 'Fail' || res.status == 'Absent') {
      badgeColor = const Color(0xFFFEE2E2);
      badgeTextColor = AppColors.error;
    } else if (res.status == 'Pending') {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = AppColors.warning;
    }

    return InkWell(
      onTap: () => _openTestDetails(res),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          res.test.testName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (res.isArchived) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Archived',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        res.test.testDate.isNotEmpty ? AppDateFormatter.formatDate(res.test.testDate) : 'Date N/A',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.bar_chart_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Total Marks: ${res.totalMarks.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (res.remarks != null && res.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Remark: "${res.remarks}"',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMain),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  res.marksDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    res.hasMarksValue ? '${res.percentageDisplay} • ${res.status}' : res.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
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
