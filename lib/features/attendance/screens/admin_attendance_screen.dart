import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/attendance_audit_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/holiday_repository.dart';
import '../../../data/services/firestore_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ClassRepository _classRepository = ClassRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final HolidayRepository _holidayRepository = HolidayRepository();

  bool _isLoading = true;
  List<ClassModel> _classes = [];
  Map<String, String> _classNameToIdMap = {}; // className -> classId
  List<HolidayModel> _holidays = [];
  List<AttendanceModel> _classAttendanceRecords = [];

  String _selectedClassName = '';
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  int _activeTabIndex = 0; // 0 = Mark Attendance, 1 = History

  // Mark Attendance Tab State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _students = [];
  bool _isAttendanceSubmitted = false;

  // History Tab State
  String _historyClassName = '';
  DateTime _historyDate = DateTime.now();
  List<Map<String, dynamic>> _realHistoryRecords = [];
  bool _isHistoryLoading = false;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminClassesAndAttendance();
    _loadHolidays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHolidays() async {
    try {
      final list = await _holidayRepository.getHolidays();
      if (mounted) {
        setState(() {
          _holidays = list;
        });
      }
    } catch (_) {}
  }

  String get _selectedClassId => _classNameToIdMap[_selectedClassName] ?? '';
  String get _historyClassId => _classNameToIdMap[_historyClassName] ?? '';

  bool get _isFutureSelectedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final chosen = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return chosen.isAfter(today);
  }

  String get _formattedDateString {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get _formattedHistoryDateString {
    final y = _historyDate.year.toString().padLeft(4, '0');
    final m = _historyDate.month.toString().padLeft(2, '0');
    final d = _historyDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get _displayHistoryDateString {
    final d = _historyDate.day.toString().padLeft(2, '0');
    final m = _months[_historyDate.month - 1].substring(0, 3);
    return '$d $m ${_historyDate.year}';
  }

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dayStr = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dayStr';
  }

  HolidayModel? _getHolidayForClassAndDate(String classId, String dateStr) {
    if (classId.isEmpty || dateStr.isEmpty) return null;
    for (var h in _holidays) {
      if (h.includesDate(dateStr) && h.appliesToClass(classId)) {
        return h;
      }
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadStudentsAndAttendanceForSelectedClass();
    }
  }

  Future<void> _pickHistoryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _historyDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _historyDate = picked;
      });
      await _loadHistoryForClass();
    }
  }

  Future<void> _loadAdminClassesAndAttendance() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final classes = await _classRepository.getClasses();
      Map<String, String> nameToId = {};

      for (var cls in classes) {
        nameToId[cls.className] = cls.classId;
      }

      if (classes.isNotEmpty) {
        _classes = classes;
        _classNameToIdMap = nameToId;
        _selectedClassName = classes.first.className;
        _historyClassName = classes.first.className;

        await _loadStudentsAndAttendanceForSelectedClass();
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentsAndAttendanceForSelectedClass() async {
    final classId = _activeTabIndex == 0 ? _selectedClassId : _historyClassId;
    if (classId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final allClassAttendance = await _attendanceRepository.getAttendanceForClass(classId);
      _classAttendanceRecords = allClassAttendance;

      final studentDocs = await _firestoreService.getStudentsDocumentsByClassId(classId);
      final studentsList = studentDocs.map((doc) {
        final s = StudentModel.fromMap(doc.data(), doc.id);
        return {
          'id': s.studentId,
          'studentId': s.studentId,
          'name': s.name,
          'rollNo': s.studentId.length > 4 ? s.studentId.substring(s.studentId.length - 4) : s.studentId,
          'status': 'Present',
        };
      }).toList();

      studentsList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      final dateStr = _formattedDateString;
      final existingAttendance = await _attendanceRepository.getAttendanceForClassAndDate(classId, dateStr);

      bool isSubmitted = existingAttendance.isNotEmpty;
      Map<String, String> statusMap = {};
      for (var att in existingAttendance) {
        statusMap[att.studentId] = att.status.toLowerCase() == 'absent' ? 'Absent' : 'Present';
      }

      for (var s in studentsList) {
        if (statusMap.containsKey(s['studentId'])) {
          s['status'] = statusMap[s['studentId']]!;
        }
      }

      if (mounted) {
        setState(() {
          _students = studentsList;
          _isAttendanceSubmitted = isSubmitted;
          _isLoading = false;
        });
      }
      _loadHistoryForClass();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistoryForClass() async {
    final classId = _historyClassId;
    if (classId.isEmpty) return;

    setState(() {
      _isHistoryLoading = true;
    });

    try {
      final studentDocs = await _firestoreService.getStudentsDocumentsByClassId(classId);
      final studentsMap = {
        for (var doc in studentDocs)
          doc.id: StudentModel.fromMap(doc.data(), doc.id)
      };

      final dateStr = _formattedHistoryDateString;
      final classAttendance = await _attendanceRepository.getAttendanceForClassAndDate(classId, dateStr);

      if (classAttendance.isEmpty) {
        if (mounted) {
          setState(() {
            _realHistoryRecords = [];
            _isHistoryLoading = false;
          });
        }
        return;
      }

      int present = classAttendance.where((a) => a.status.toLowerCase() == 'present').length;
      int absent = classAttendance.where((a) => a.status.toLowerCase() == 'absent').length;
      int total = present + absent;
      String percentage = total > 0 ? '${((present / total) * 100).round()}%' : '0%';
      bool hasAdminChanges = classAttendance.any((a) => a.isAdminChanged);
      String submitterName = classAttendance.first.markedByRole == 'admin' ? 'Admin' : 'Teacher';

      final studentDetailsList = classAttendance.map((a) {
        final st = studentsMap[a.studentId];
        return {
          'id': a.studentId,
          'name': st?.name ?? 'Student (${a.studentId})',
          'rollNo': a.studentId.length > 4 ? a.studentId.substring(a.studentId.length - 4) : a.studentId,
          'status': a.status.toLowerCase() == 'absent' ? 'Absent' : 'Present',
          'adminChangeReason': a.adminChangeReason,
          'originalStatus': a.originalStatus,
          'isAdminChanged': a.isAdminChanged,
        };
      }).toList();

      final record = {
        'class': _historyClassName,
        'classId': classId,
        'date': _displayHistoryDateString,
        'canonicalDate': dateStr,
        'fullDate': _displayHistoryDateString,
        'submittedBy': submitterName,
        'submitterName': submitterName,
        'present': present,
        'absent': absent,
        'total': total > 0 ? total : studentsMap.length,
        'percentage': percentage,
        'hasAdminChanges': hasAdminChanges,
        'students': studentDetailsList,
      };

      if (mounted) {
        setState(() {
          _realHistoryRecords = [record];
          _isHistoryLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isHistoryLoading = false;
        });
      }
    }
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

  void _markAllPresent() {
    final activeHoliday = _getHolidayForClassAndDate(_selectedClassId, _formattedDateString);
    if (activeHoliday != null || _isFutureSelectedDate) return;
    setState(() {
      for (var s in _students) {
        s['status'] = 'Present';
      }
    });
  }

  void _showConfirmationDialog() {
    final activeHoliday = _getHolidayForClassAndDate(_selectedClassId, _formattedDateString);
    if (_students.isEmpty || activeHoliday != null || _isFutureSelectedDate) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _isAttendanceSubmitted ? 'Update Attendance?' : 'Save Attendance?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAttendanceSubmitted
                    ? 'Are you sure you want to update attendance records for $_selectedClassName on $_formattedDateString?'
                    : 'Are you sure you want to save attendance for $_selectedClassName on $_formattedDateString?',
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Students', '${_students.length}'),
                    _buildSummaryRow('Present', '$_presentCount', color: AppColors.success),
                    _buildSummaryRow('Absent', '$_absentCount', color: AppColors.error),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitAttendance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_isAttendanceSubmitted ? 'UPDATE' : 'SAVE', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance() async {
    if (_isFutureSelectedDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance cannot be marked for a future date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final classId = _selectedClassId;
    if (classId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dateStr = _formattedDateString;
      final isUpdating = _isAttendanceSubmitted;

      List<AttendanceModel> attendanceList = [];
      for (var s in _students) {
        final studentId = s['studentId'] as String;
        final status = s['status'] as String;
        final attId = AttendanceModel.generateId(classId, studentId, dateStr);

        attendanceList.add(
          AttendanceModel(
            attendanceId: attId,
            classId: classId,
            studentId: studentId,
            date: dateStr,
            status: status,
            markedBy: user.uid,
            markedByRole: 'admin',
          ),
        );
      }

      await _attendanceRepository.saveAttendanceBatch(attendanceList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? 'Attendance updated successfully.' : 'Attendance saved successfully.'),
            backgroundColor: AppColors.primaryEmerald,
          ),
        );
      }

      await _loadStudentsAndAttendanceForSelectedClass();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: AppColors.error),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classNames = _classes.map((c) => c.className).toList();
    final HolidayModel? markTabHoliday = _getHolidayForClassAndDate(_selectedClassId, _formattedDateString);

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
          'Attendance Management',
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
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadAdminClassesAndAttendance();
                  await _loadHolidays();
                },
                color: AppColors.primaryEmerald,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tab Switcher (Mark Attendance vs Attendance History)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _activeTabIndex = 0);
                                      _loadStudentsAndAttendanceForSelectedClass();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _activeTabIndex == 0
                                            ? AppColors.primaryEmerald
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Mark Attendance',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _activeTabIndex == 0
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _activeTabIndex = 1);
                                      _loadHistoryForClass();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _activeTabIndex == 1
                                            ? AppColors.primaryEmerald
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Attendance History',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
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
                            _buildControlsCard(classNames),
                            const SizedBox(height: 16),

                            // Monthly Calendar Grid Card
                            _buildMonthlyCalendarCard(
                              currentClassId: _selectedClassId,
                              selectedDate: _selectedDate,
                              onDateSelected: (cellDate) async {
                                setState(() {
                                  _selectedDate = cellDate;
                                });
                                await _loadStudentsAndAttendanceForSelectedClass();
                              },
                            ),
                            const SizedBox(height: 16),

                            if (_isFutureSelectedDate) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.event_rounded, color: AppColors.textSecondary, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Future attendance cannot be marked.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else if (markTabHoliday != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_available_rounded, color: AppColors.textMain, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${markTabHoliday.title} (${markTabHoliday.type}) is scheduled for $_selectedClassName on $_formattedDateString. Attendance is not required.',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else if (_isAttendanceSubmitted) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightEmerald,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.check_circle_outline_rounded, color: AppColors.darkEmerald, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Attendance for this class and date has been submitted. As an Admin, you can review and update the records below.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkEmerald,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildSummaryCard(),
                            const SizedBox(height: 20),

                            // Students List Header Row
                            _buildStudentsHeaderRow(markTabHoliday != null),
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
                                      return _buildStudentAttendanceTile(student, isHoliday: markTabHoliday != null);
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
                                if (_isFutureSelectedDate)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Text(
                                      'Future Attendance Unavailable',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else if (markTabHoliday != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.border.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      'Official Holiday (${markTabHoliday.title})',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                else
                                  PrimaryButton(
                                    text: _isAttendanceSubmitted ? 'Update Attendance' : 'Save Attendance',
                                    onPressed: _showConfirmationDialog,
                                  ),
                              ],
                            ),
                          ] else ...[
                            // HISTORY TAB
                            _buildHistoryView(classNames),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildControlsCard(List<String> classNames) {
    if (_selectedClassName.isEmpty && classNames.isNotEmpty) {
      _selectedClassName = classNames.first;
    }

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
                    value: classNames.contains(_selectedClassName) ? _selectedClassName : (classNames.isNotEmpty ? classNames.first : null),
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    items: classNames
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() {
                          _selectedClassName = v;
                        });
                        await _loadStudentsAndAttendanceForSelectedClass();
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
                    'Selected Date',
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isFutureSelectedDate ? AppColors.textSecondary : AppColors.textMain,
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

  Widget _buildStudentsHeaderRow(bool isHoliday) {
    final bool isDisabled = isHoliday || _isFutureSelectedDate;

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
        if (!isDisabled)
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
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHoliday
                  ? AppColors.border.withValues(alpha: 0.3)
                  : (_isFutureSelectedDate ? AppColors.background : AppColors.lightEmerald),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isFutureSelectedDate
                  ? 'Future Date'
                  : (isHoliday ? 'Holiday' : 'Submitted'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isHoliday || _isFutureSelectedDate
                    ? AppColors.textMain
                    : AppColors.darkEmerald,
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
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildStudentAttendanceTile(Map<String, dynamic> student, {bool isHoliday = false}) {
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
              student['name'].isNotEmpty ? student['name'][0] : 'S',
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
          Row(
            children: [
              _buildAttendanceToggleButton(
                student,
                'Present',
                AppColors.success,
                isPresent,
                isDisabled: isHoliday || _isFutureSelectedDate,
              ),
              const SizedBox(width: 8),
              _buildAttendanceToggleButton(
                student,
                'Absent',
                AppColors.error,
                !isPresent,
                isDisabled: isHoliday || _isFutureSelectedDate,
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
    bool isSelected, {
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                student['status'] = statusOption;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDisabled ? AppColors.textSecondary.withValues(alpha: 0.4) : activeColor)
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDisabled ? AppColors.border : activeColor)
                : AppColors.border,
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

  // --- MONTHLY CALENDAR GRID WIDGET ---

  Widget _buildMonthlyCalendarCard({
    required String currentClassId,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    final monthName = _months[_focusedMonth.month - 1];
    final int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final DateTime firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final int leadingEmptySlots = (firstDayOfMonth.weekday - 1) % 7; // Monday = 1 -> 0 slots
    final int totalGridCells = leadingEmptySlots + daysInMonth;

    final today = DateTime.now();

    final Set<String> submittedDates = {
      for (var r in _classAttendanceRecords) r.date
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header & Controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName ${_focusedMonth.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Attendance & Holiday Calendar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime.now();
                      });
                      onDateSelected(DateTime.now());
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.lightEmerald,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.today_rounded, size: 14, color: AppColors.darkEmerald),
                          SizedBox(width: 4),
                          Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.darkEmerald,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.chevron_left_rounded, color: AppColors.textMain, size: 22),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.chevron_right_rounded, color: AppColors.textMain, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Weekday Labels (Monday-first)
          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 7-Column Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemCount: totalGridCells,
            itemBuilder: (context, index) {
              if (index < leadingEmptySlots) {
                return const SizedBox.shrink();
              }

              final int dayNumber = index - leadingEmptySlots + 1;
              final DateTime cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final String dateKey = _formatDateKey(cellDate);

              final bool isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final bool isSelected = cellDate.year == selectedDate.year &&
                  cellDate.month == selectedDate.month &&
                  cellDate.day == selectedDate.day;

              final HolidayModel? holiday = _getHolidayForClassAndDate(currentClassId, dateKey);
              final bool hasSubmitted = submittedDates.contains(dateKey);

              Color bgColor = AppColors.background;
              Color borderColor = AppColors.border;
              Color textColor = AppColors.textMain;
              String statusBadgeText = '';

              if (holiday != null) {
                bgColor = AppColors.border.withValues(alpha: 0.3);
                borderColor = AppColors.textSecondary.withValues(alpha: 0.4);
                textColor = AppColors.textMain;
                statusBadgeText = 'H';
              } else if (hasSubmitted) {
                bgColor = AppColors.lightEmerald;
                borderColor = AppColors.primaryEmerald;
                textColor = AppColors.darkEmerald;
                statusBadgeText = '✓';
              } else if (cellDate.isAfter(today)) {
                textColor = AppColors.textSecondary.withValues(alpha: 0.5);
              }

              return InkWell(
                onTap: () => onDateSelected(cellDate),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryEmerald
                          : (isToday ? AppColors.darkEmerald : borderColor),
                      width: isSelected ? 2.0 : (isToday ? 1.5 : 1.0),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (statusBadgeText.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: holiday != null ? AppColors.textSecondary : AppColors.primaryEmerald,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusBadgeText,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isToday)
                        Positioned(
                          top: 3,
                          right: 3,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCalendarLegendItem('✓', 'Submitted', AppColors.primaryEmerald, AppColors.lightEmerald),
              _buildCalendarLegendItem('H', 'Holiday', AppColors.textSecondary, AppColors.border.withValues(alpha: 0.3)),
              _buildCalendarLegendItem('-', 'Not Submitted', AppColors.textSecondary, AppColors.background),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarLegendItem(String code, String label, Color color, Color bg) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color, width: 1.0),
          ),
          child: Text(
            code,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // --- ATTENDANCE HISTORY TAB IMPLEMENTATION ---

  Widget _buildHistoryView(List<String> classNames) {
    if (_historyClassName.isEmpty && classNames.isNotEmpty) {
      _historyClassName = classNames.first;
    }

    final HolidayModel? historyHoliday = _getHolidayForClassAndDate(_historyClassId, _formattedHistoryDateString);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHistorySelectors(classNames),
        const SizedBox(height: 16),

        // Monthly Calendar Grid
        _buildMonthlyCalendarCard(
          currentClassId: _historyClassId,
          selectedDate: _historyDate,
          onDateSelected: (cellDate) async {
            setState(() {
              _historyDate = cellDate;
            });
            await _loadHistoryForClass();
          },
        ),
        const SizedBox(height: 16),

        if (historyHoliday != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, color: AppColors.textMain, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Official Holiday: ${historyHoliday.title} (${historyHoliday.type})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
                if (historyHoliday.note.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Note: ${historyHoliday.note}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Attendance History Heading & List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attendance History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            Text(
              _displayHistoryDateString,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryEmerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _isHistoryLoading
            ? const Center(child: AppLoadingIndicator())
            : _realHistoryRecords.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      historyHoliday != null
                          ? 'Official Holiday scheduled for this date.'
                          : 'No attendance records found for $_displayHistoryDateString.',
                      style: const TextStyle(
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
                    itemCount: _realHistoryRecords.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final record = _realHistoryRecords[index];
                      final bool hasAdminChanges = record['hasAdminChanges'] as bool? ?? false;

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record['date'] as String,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
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
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${record['present']} Present · ${record['absent']} Absent · Submitted by: ${record['submitterName']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasAdminChanges) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Attendance records modified by Admin',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.error,
                                      ),
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
    );
  }

  Widget _buildHistorySelectors(List<String> classNames) {
    if (_historyClassName.isEmpty && classNames.isNotEmpty) {
      _historyClassName = classNames.first;
    }

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
                    value: classNames.contains(_historyClassName) ? _historyClassName : (classNames.isNotEmpty ? classNames.first : null),
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    items: classNames
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() {
                          _historyClassName = v;
                        });
                        await _loadHistoryForClass();
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
              onTap: _pickHistoryDate,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History Date',
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
                        _displayHistoryDateString,
                        style: const TextStyle(
                          fontSize: 13,
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
                        '${record['fullDate']} · $_historyClassName',
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final canonicalDate = record['canonicalDate'] as String? ?? _formattedHistoryDateString;
                              final audits = await _attendanceRepository.getAuditsForClassAndDate(_historyClassId, canonicalDate);
                              if (!context.mounted) return;
                              _showAuditHistoryModal(audits);
                            },
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text('View Change History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.textMain,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ],
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
                              color: AppColors.textSecondary, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No students found.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                        height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final st = filtered[index];
                                  final bool isPres =
                                      st['status'] == 'Present';
                                  final bool isChanged = st['isAdminChanged'] as bool? ?? false;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isPres
                                              ? AppColors.lightEmerald
                                              : AppColors.error
                                                  .withValues(alpha: 0.1),
                                          child: Text(
                                            st['name'].isNotEmpty
                                                ? st['name'][0]
                                                : 'S',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isPres
                                                  ? AppColors.primaryEmerald
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                st['name'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              Text(
                                                'Roll No: ${st['rollNo']}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              if (isChanged)
                                                Text(
                                                  'Original: ${st['originalStatus']} · Changed by Admin',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPres
                                                ? AppColors.lightEmerald
                                                : AppColors.error
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            st['status'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isPres
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

  void _showAuditHistoryModal(List<AttendanceAuditModel> audits) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              const Text(
                'Attendance Change History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
              ),
              const SizedBox(height: 16),
              audits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No change history found for this session.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: audits.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final audit = audits[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Student ID: ${audit.studentId}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('${audit.oldStatus.toUpperCase()} → ${audit.newStatus.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryEmerald)),
                                const SizedBox(height: 2),
                                Text('Changed by: ${audit.changedByName} (${audit.changedByRole})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Reason: "${audit.reason.isNotEmpty ? audit.reason : 'No reason provided'}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMain)),
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
  }
}
