import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  String _selectedClass = 'Class 11-B';
  DateTime _selectedDate = DateTime.now();
  int _activeTabIndex = 0; // 0 = Mark Attendance, 1 = History

  // Mark Attendance Tab State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // History Tab State
  String _historyClass = 'Class 11-B';
  String _historyMonth = 'October 2026';
  final List<String> _months = [
    'October 2026',
    'September 2026',
    'August 2026'
  ];

  final List<String> _classList = ['Class 11-B', 'Class 10-B'];

  // Mock student list defaulting to Present
  late List<Map<String, dynamic>> _students;

  @override
  void initState() {
    super.initState();
    _initMockStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initMockStudents() {
    _students = [
      {'id': 'STU1', 'name': 'Raj Kumar', 'rollNo': '101', 'status': 'Present'},
      {'id': 'STU2', 'name': 'Priya Sharma', 'rollNo': '102', 'status': 'Present'},
      {'id': 'STU3', 'name': 'Aman Verma', 'rollNo': '103', 'status': 'Present'},
      {'id': 'STU4', 'name': 'Neha Gupta', 'rollNo': '104', 'status': 'Present'},
      {'id': 'STU5', 'name': 'Rohan Shah', 'rollNo': '105', 'status': 'Present'},
    ];
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.trim().isEmpty) {
      return _students;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _students.where((s) {
      final name = (s['name'] as String? ?? '').toLowerCase();
      final rollNo = (s['rollNo'] as String? ?? '').toLowerCase();
      return name.contains(query) || rollNo.contains(query);
    }).toList();
  }

  int get _presentCount =>
      _students.where((s) => s['status'] == 'Present').length;
  int get _absentCount =>
      _students.where((s) => s['status'] == 'Absent').length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var s in _students) {
        s['status'] = 'Present';
      }
    });
  }

  void _saveAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Attendance saved successfully',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
        title: const Text(
          'Attendance',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Switcher
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTabIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 0
                                    ? AppColors.primaryEmerald
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'Mark Attendance',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _activeTabIndex == 0
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTabIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _activeTabIndex == 1
                                    ? AppColors.primaryEmerald
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                'Attendance History',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _activeTabIndex == 1
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_activeTabIndex == 0) ...[
                    // MARK ATTENDANCE TAB
                    _buildControlsCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 20),

                    // Students List Header Row with Mark All Present button
                    _buildStudentsHeaderRow(),
                    const SizedBox(height: 12),

                    // Search Field
                    _buildSearchField(),
                    const SizedBox(height: 14),

                    // Student List or Empty Search State
                    _filteredStudents.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'No students found.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredStudents.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return _buildStudentAttendanceTile(student);
                            },
                          ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        Text(
                          '${_students.length} Students · $_presentCount Present · $_absentCount Absent',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          text: 'Save Attendance',
                          onPressed: _saveAttendance,
                        ),
                      ],
                    ),
                  ] else ...[
                    // HISTORY TAB
                    _buildHistoryView(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Class',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    items: _classList
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedClass = v;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.primaryEmerald),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryColumn('Total Students', '${_students.length}', AppColors.textMain),
          Container(width: 1, height: 24, color: AppColors.border),
          _buildSummaryColumn('Present', '$_presentCount', AppColors.success),
          Container(width: 1, height: 24, color: AppColors.border),
          _buildSummaryColumn('Absent', '$_absentCount', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
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
        ),
      ],
    );
  }

  Widget _buildStudentsHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Students List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        ElevatedButton.icon(
          onPressed: _markAllPresent,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: const Text('Mark All Present'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightEmerald,
            foregroundColor: AppColors.darkEmerald,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textMain,
      ),
      decoration: InputDecoration(
        hintText: 'Search student by name or roll no.',
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryEmerald, width: 1.5),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStudentAttendanceTile(Map<String, dynamic> student) {
    final String currentStatus = student['status'] as String;
    final bool isPresent = currentStatus == 'Present';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isPresent ? AppColors.lightEmerald : AppColors.error.withValues(alpha: 0.1),
            child: Text(
              student['name'][0],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPresent ? AppColors.primaryEmerald : AppColors.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Roll No: ${student['rollNo']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Exactly TWO toggle buttons: Present and Absent
          Row(
            children: [
              _buildAttendanceToggleButton(
                student,
                'Present',
                AppColors.success,
                isPresent,
              ),
              const SizedBox(width: 8),
              _buildAttendanceToggleButton(
                student,
                'Absent',
                AppColors.error,
                !isPresent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceToggleButton(
    Map<String, dynamic> student,
    String statusOption,
    Color activeColor,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          student['status'] = statusOption;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          statusOption,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // --- ATTENDANCE HISTORY TAB IMPLEMENTATION ---

  Widget _buildHistoryView() {
    final List<Map<String, dynamic>> mockDateHistory = [
      {
        'date': '7 Oct 2026',
        'fullDate': '7 October 2026',
        'present': 48,
        'absent': 2,
        'total': 50,
        'percentage': '96%',
        'students': [
          {'name': 'Raj Kumar', 'rollNo': '101', 'status': 'Present'},
          {'name': 'Priya Sharma', 'rollNo': '102', 'status': 'Present'},
          {'name': 'Aman Verma', 'rollNo': '103', 'status': 'Absent'},
          {'name': 'Neha Gupta', 'rollNo': '104', 'status': 'Present'},
          {'name': 'Rohan Shah', 'rollNo': '105', 'status': 'Absent'},
        ],
      },
      {
        'date': '6 Oct 2026',
        'fullDate': '6 October 2026',
        'present': 47,
        'absent': 3,
        'total': 50,
        'percentage': '94%',
        'students': [
          {'name': 'Raj Kumar', 'rollNo': '101', 'status': 'Present'},
          {'name': 'Priya Sharma', 'rollNo': '102', 'status': 'Absent'},
          {'name': 'Aman Verma', 'rollNo': '103', 'status': 'Absent'},
          {'name': 'Neha Gupta', 'rollNo': '104', 'status': 'Present'},
          {'name': 'Rohan Shah', 'rollNo': '105', 'status': 'Present'},
        ],
      },
      {
        'date': '5 Oct 2026',
        'fullDate': '5 October 2026',
        'present': 50,
        'absent': 0,
        'total': 50,
        'percentage': '100%',
        'students': [
          {'name': 'Raj Kumar', 'rollNo': '101', 'status': 'Present'},
          {'name': 'Priya Sharma', 'rollNo': '102', 'status': 'Present'},
          {'name': 'Aman Verma', 'rollNo': '103', 'status': 'Present'},
          {'name': 'Neha Gupta', 'rollNo': '104', 'status': 'Present'},
          {'name': 'Rohan Shah', 'rollNo': '105', 'status': 'Present'},
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Class & Month Selectors
        _buildHistorySelectors(),
        const SizedBox(height: 16),

        // 2. Monthly Summary Card
        _buildMonthlySummaryCard(),
        const SizedBox(height: 20),

        // 3. Attendance History Heading & List
        const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockDateHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final record = mockDateHistory[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDateDetailsModal(record),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record['date'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${record['present']} Present · ${record['absent']} Absent',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightEmerald,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${record['percentage']} Attendance',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkEmerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
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
        const SizedBox(height: 24),

        // 4. Needs Attention Section
        _buildNeedsAttentionSection(),
      ],
    );
  }

  Widget _buildHistorySelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Class',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _historyClass,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    items: _classList
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _historyClass = v;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _historyMonth,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    items: _months
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _historyMonth = v;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text(
                _historyMonth,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightEmerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '92% Class Attendance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('Attendance Days', '20', AppColors.textMain),
              Container(width: 1, height: 24, color: AppColors.border),
              _buildSummaryColumn('Total Present', '184', AppColors.success),
              Container(width: 1, height: 24, color: AppColors.border),
              _buildSummaryColumn('Total Absent', '16', AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsAttentionSection() {
    final mockLowAttendanceStudents = [
      {'name': 'Aman Verma', 'attendance': '68%'},
      {'name': 'Priya Shah', 'attendance': '72%'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Needs Attention',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockLowAttendanceStudents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = mockLowAttendanceStudents[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 20, color: AppColors.error),
                      const SizedBox(width: 10),
                      Text(
                        s['name'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${s['attendance']} Attendance',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDateDetailsModal(Map<String, dynamic> record) {
    String localSearch = '';

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
            final List<Map<String, dynamic>> allStudents =
                List<Map<String, dynamic>>.from(record['students'] as List);
            final filtered = allStudents.where((s) {
              if (localSearch.trim().isEmpty) return true;
              final q = localSearch.trim().toLowerCase();
              return (s['name'] as String).toLowerCase().contains(q) ||
                  (s['rollNo'] as String).toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
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
                        '${record['fullDate']} · $_historyClass',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${record['total']} Students · ${record['present']} Present · ${record['absent']} Absent · ${record['percentage']} Attendance',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'Search student by name or roll no.',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 20, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primaryEmerald, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            localSearch = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No students found.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                        height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final s = filtered[index];
                                  final bool isPresent =
                                      s['status'] == 'Present';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['name'] as String,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textMain,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Roll No: ${s['rollNo']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPresent
                                                ? AppColors.lightEmerald
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            s['status'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isPresent
                                                  ? AppColors.darkEmerald
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
}
