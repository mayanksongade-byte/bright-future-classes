import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../tests/screens/add_edit_test_screen.dart';
import '../../tests/screens/enter_marks_screen.dart';
import '../../tests/screens/test_details_screen.dart';
import '../../tests/view_models/tests_view_model.dart';

class TeacherTestsScreen extends StatefulWidget {
  const TeacherTestsScreen({super.key});

  @override
  State<TeacherTestsScreen> createState() => _TeacherTestsScreenState();
}

class _TeacherTestsScreenState extends State<TeacherTestsScreen> {
  late final TestsViewModel _viewModel;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedClassFilter = 'All Classes';
  String _selectedSubjectFilter = 'All Subjects';
  String _selectedStatusFilter = 'All'; // All, Active, Completed

  @override
  void initState() {
    super.initState();
    _viewModel = TestsViewModel();
    _viewModel.addListener(_onViewModelChange);
    _searchController.addListener(_onSearchChanged);
    _loadTeacherData();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  TeacherModel? _currentTeacher;

  Future<void> _loadTeacherData() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _viewModel.fetchTestsData(teacherUid: user.uid);
      try {
        final userDoc = await FirestoreService().getUserDocument(user.uid);
        final customTeacherId = userDoc?['teacherId'] as String? ?? '';
        final customUserId = userDoc?['userId'] as String? ?? '';

        Map<String, dynamic>? teacherData = await FirestoreService().getTeacherDocument(user.uid);
        String resolvedDocId = user.uid;

        if (teacherData == null && customTeacherId.isNotEmpty) {
          teacherData = await FirestoreService().getTeacherDocument(customTeacherId);
          resolvedDocId = customTeacherId;
        }

        if (teacherData == null) {
          final teacherDocs = await FirestoreService().getTeachersDocuments();
          for (var doc in teacherDocs) {
            final data = doc.data();
            final uidVal = data['uid'] as String? ?? '';
            final userIdVal = data['userId'] as String? ?? '';
            final tIdVal = data['teacherId'] as String? ?? '';

            if (doc.id == user.uid ||
                doc.id == customTeacherId ||
                uidVal == user.uid ||
                userIdVal == customUserId ||
                tIdVal == customTeacherId) {
              teacherData = data;
              resolvedDocId = doc.id;
              break;
            }
          }
        }

        if (teacherData != null) {
          _currentTeacher = TeacherModel.fromMap(teacherData, resolvedDocId);
        }
      } catch (_) {}
    } else {
      await _viewModel.fetchTestsData();
    }
    if (mounted) setState(() {});
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

  List<TestItem> get _filteredTestItems {
    final query = _searchController.text.trim().toLowerCase();
    return _viewModel.testItems.where((item) {
      if (_selectedClassFilter != 'All Classes' &&
          item.classModel != null &&
          item.classModel!.className != _selectedClassFilter) {
        return false;
      }
      if (_selectedSubjectFilter != 'All Subjects' &&
          item.test.subject != _selectedSubjectFilter) {
        return false;
      }
      if (_selectedStatusFilter == 'Active' && (item.test.isCancelled || item.status == 'Completed')) {
        return false;
      }
      if (_selectedStatusFilter == 'Completed' && item.status != 'Completed') {
        return false;
      }
      if (query.isNotEmpty) {
        final testName = item.test.testName.toLowerCase();
        final subject = item.test.subject.toLowerCase();
        if (!testName.contains(query) && !subject.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final testItems = _filteredTestItems;

    final List<String> classNames = [
      'All Classes',
      ..._viewModel.classes.map((c) => c.className),
    ];

    final Set<String> subjectSet = {};
    for (var item in _viewModel.testItems) {
      final sub = item.test.subject.trim();
      if (sub.isNotEmpty) {
        bool isAssigned = true;
        if (_currentTeacher != null) {
          final assignedClassOk = item.classModel != null && _currentTeacher!.classIds.contains(item.classModel!.classId);
          final teachesSubjectOk = _currentTeacher!.teachesSubject(sub);
          isAssigned = assignedClassOk && teachesSubjectOk;
        }
        if (isAssigned) {
          subjectSet.add(sub);
        }
      }
    }
    final List<String> subjectNames = ['All Subjects', ...subjectSet.toList()..sort()];

    if (!subjectNames.contains(_selectedSubjectFilter)) {
      _selectedSubjectFilter = 'All Subjects';
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
        title: const Text(
          'Tests & Marks Workspace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryEmerald),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddEditTestScreen(
                    preloadedClasses: _viewModel.classes,
                  ),
                ),
              );
              _loadTeacherData();
            },
            tooltip: 'Schedule Test',
          ),
          const SizedBox(width: 8),
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
                onRefresh: _loadTeacherData,
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
                          // Filters Card
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
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Filter Tests',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        if (_selectedClassFilter != 'All Classes' ||
                                            _selectedSubjectFilter != 'All Subjects' ||
                                            _selectedStatusFilter != 'All' ||
                                            _searchController.text.isNotEmpty)
                                          TextButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _selectedClassFilter = 'All Classes';
                                                _selectedSubjectFilter = 'All Subjects';
                                                _selectedStatusFilter = 'All';
                                              });
                                            },
                                            child: const Text('Clear Filters',
                                                style: TextStyle(
                                                    color: AppColors.error,
                                                    fontSize: 12)),
                                          ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => AddEditTestScreen(
                                                  preloadedClasses: _viewModel.classes,
                                                ),
                                              ),
                                            );
                                            _loadTeacherData();
                                          },
                                          icon: const Icon(Icons.add_rounded, size: 16),
                                          label: const Text('Schedule Test'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryEmerald,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 500;
                                    if (isWide) {
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  initialValue: classNames.contains(_selectedClassFilter) ? _selectedClassFilter : classNames.first,
                                                  isExpanded: true,
                                                  style: AppTextStyles.inputText,
                                                  decoration: InputDecoration(
                                                    labelText: 'Class',
                                                    filled: true,
                                                    fillColor: AppColors.background,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  items: classNames
                                                      .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null) setState(() => _selectedClassFilter = val);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  initialValue: subjectNames.contains(_selectedSubjectFilter) ? _selectedSubjectFilter : subjectNames.first,
                                                  isExpanded: true,
                                                  style: AppTextStyles.inputText,
                                                  decoration: InputDecoration(
                                                    labelText: 'Subject',
                                                    filled: true,
                                                    fillColor: AppColors.background,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  items: subjectNames
                                                      .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null) setState(() => _selectedSubjectFilter = val);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<String>(
                                                  initialValue: _selectedStatusFilter,
                                                  isExpanded: true,
                                                  style: AppTextStyles.inputText,
                                                  decoration: InputDecoration(
                                                    labelText: 'Status',
                                                    filled: true,
                                                    fillColor: AppColors.background,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  items: const ['All', 'Active', 'Completed']
                                                      .map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis)))
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null) setState(() => _selectedStatusFilter = val);
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  style: AppTextStyles.inputText,
                                                  decoration: InputDecoration(
                                                    labelText: 'Search Test Name / Subject',
                                                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                    filled: true,
                                                    fillColor: AppColors.background,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                      borderSide: const BorderSide(color: AppColors.border),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                      borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          DropdownButtonFormField<String>(
                                            initialValue: classNames.contains(_selectedClassFilter) ? _selectedClassFilter : classNames.first,
                                            isExpanded: true,
                                            style: AppTextStyles.inputText,
                                            decoration: InputDecoration(
                                              labelText: 'Class',
                                              filled: true,
                                              fillColor: AppColors.background,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            items: classNames
                                                .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedClassFilter = val);
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            initialValue: subjectNames.contains(_selectedSubjectFilter) ? _selectedSubjectFilter : subjectNames.first,
                                            isExpanded: true,
                                            style: AppTextStyles.inputText,
                                            decoration: InputDecoration(
                                              labelText: 'Subject',
                                              filled: true,
                                              fillColor: AppColors.background,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            items: subjectNames
                                                .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedSubjectFilter = val);
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          DropdownButtonFormField<String>(
                                            initialValue: _selectedStatusFilter,
                                            isExpanded: true,
                                            style: AppTextStyles.inputText,
                                            decoration: InputDecoration(
                                              labelText: 'Status',
                                              filled: true,
                                              fillColor: AppColors.background,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            items: const ['All', 'Active', 'Completed']
                                                .map((st) => DropdownMenuItem(value: st, child: Text(st, overflow: TextOverflow.ellipsis)))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) setState(() => _selectedStatusFilter = val);
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _searchController,
                                            style: AppTextStyles.inputText,
                                            decoration: InputDecoration(
                                              labelText: 'Search Test Name / Subject',
                                              labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              filled: true,
                                              fillColor: AppColors.background,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(color: AppColors.border),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Assigned Class Tests (${testItems.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          testItems.isEmpty
                              ? Container(
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
                                        Icons.assignment_turned_in_outlined,
                                        size: 48,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No tests found for assigned classes.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Schedule a test to start entering student marks.',
                                        style: AppTextStyles.subtitle,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      PrimaryButton(
                                        text: 'Schedule New Test',
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => AddEditTestScreen(
                                                preloadedClasses: _viewModel.classes,
                                              ),
                                            ),
                                          );
                                          _loadTeacherData();
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: testItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = testItems[index];
                                    return _buildTeacherTestCard(item);
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

  Widget _buildTeacherTestCard(TestItem item) {
    final bool isCancelled = item.test.isCancelled;
    Color statusColor = AppColors.warning;
    String statusTitle = item.status;

    if (isCancelled) {
      statusColor = AppColors.error;
      statusTitle = 'Cancelled';
    } else if (item.status == 'Completed') {
      statusColor = AppColors.success;
    } else if (item.status == 'Partially Entered') {
      statusColor = AppColors.info;
    }

    final timingTag = item.dateTimingTag;

    return Container(
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
          // Header Row: Icon, Title, Class/Subject, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.lightEmerald,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCancelled ? Icons.cancel_outlined : Icons.quiz_outlined,
                        color: isCancelled ? AppColors.error : AppColors.primaryEmerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.test.testName,
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
                            '${item.classModel != null ? item.classModel!.className : 'Class'} • ${item.test.subject}',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Creator Attribution Row
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.creatorAttribution,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Timing & Evaluated Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Date: ${item.test.testDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (timingTag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: timingTag == 'Today'
                              ? AppColors.primaryEmerald
                              : AppColors.lightEmerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timingTag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: timingTag == 'Today' ? Colors.white : AppColors.darkEmerald,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.marksEnteredCount}/${item.totalStudents} Evaluated',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Marks Editor Attribution Row
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, size: 14, color: AppColors.primaryEmerald),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.editorAttribution} • Max: ${item.test.totalMarks.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons (Enter Marks & Details only)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!isCancelled && !item.isFutureExamDate)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EnterMarksScreen(testItem: item),
                      ),
                    );
                    _loadTeacherData();
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Enter / Edit Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else if (!isCancelled && item.isFutureExamDate)
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EnterMarksScreen(testItem: item),
                      ),
                    );
                    _loadTeacherData();
                  },
                  icon: const Icon(Icons.lock_clock_outlined, size: 16, color: AppColors.textSecondary),
                  label: Text('Marks on ${item.test.testDate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TestDetailsScreen(testItem: item),
                    ),
                  );
                  _loadTeacherData();
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMain,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
