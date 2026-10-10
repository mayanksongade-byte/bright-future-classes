import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/attendance_audit_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<ClassModel> _assignedClasses = [];
  Map<String, String> _classNameToIdMap = {}; // className -> classId

  String _selectedClassName = '';
  DateTime _selectedDate = DateTime.now();
  int _activeTabIndex = 0; // 0 = Mark Attendance, 1 = History

  // Mark Attendance Tab State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _students = []; // id, studentId, name, rollNo, status
  bool _isAttendanceSubmitted = false;

  // History Tab State
  String _historyClassName = '';
  DateTime _historyDate = DateTime.now();
  List<Map<String, dynamic>> _realHistoryRecords = [];
  bool _isHistoryLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherClassesAndAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _selectedClassId => _classNameToIdMap[_selectedClassName] ?? '';
  String get _historyClassId => _classNameToIdMap[_historyClassName] ?? '';

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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = _historyDate.day.toString().padLeft(2, '0');
    final m = months[_historyDate.month - 1];
    return '$d $m ${_historyDate.year}';
  }

  Future<void> _loadTeacherClassesAndAttendance() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
        final teacherId = userDoc?['teacherId'] as String? ?? currentUser.uid;
        final teacherData = await _firestoreService.getTeacherDocument(teacherId);
        final teacher = teacherData != null
            ? TeacherModel.fromMap(teacherData, teacherId)
            : null;
        final classIds = teacher?.classIds ?? [];

        List<ClassModel> classes = [];
        Map<String, String> nameToId = {};

        for (var classId in classIds) {
          final classData = await _firestoreService.getClassDocument(classId);
          if (classData != null) {
            final cls = ClassModel.fromMap(classData, classId);
            classes.add(cls);
            nameToId[cls.className] = classId;
          }
        }

        if (classes.isNotEmpty) {
          _assignedClasses = classes;
          _classNameToIdMap = nameToId;
          _selectedClassName = classes.first.className;
          _historyClassName = classes.first.className;

          await _loadStudentsAndAttendanceForSelectedClass();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudentsAndAttendanceForSelectedClass() async {
    final classId = _selectedClassId;
    if (classId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Load real students for class
      final studentDocs = await _firestoreService.getStudentsDocumentsByClassId(classId);
      final studentsList = studentDocs.map((doc) {
        final s = StudentModel.fromMap(doc.data(), doc.id);
        return {
          'id': s.studentId,
          'studentId': s.studentId,
          'name': s.name,
          'rollNo': s.studentId.length > 4 ? s.studentId.substring(s.studentId.length - 4) : s.studentId,
          'status': 'Present', // default
        };
      }).toList();

      // Sort by name
      studentsList.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // 2. Load existing attendance for class and date
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

      // Get attendance for selected class and selected date
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
      String submitterName = classAttendance.first.markedByName.isNotEmpty
          ? classAttendance.first.markedByName
          : 'Teacher';

      List<Map<String, dynamic>> studentRows = [];
      studentsMap.forEach((studentId, student) {
        final att = classAttendance.firstWhere(
          (a) => a.studentId == studentId,
          orElse: () => AttendanceModel(
            attendanceId: '',
            studentId: studentId,
            classId: classId,
            date: dateStr,
            status: 'Present',
            markedBy: '',
          ),
        );
        studentRows.add({
          'name': student.name,
          'rollNo': studentId.length > 4 ? studentId.substring(studentId.length - 4) : studentId,
          'status': att.status.toLowerCase() == 'absent' ? 'Absent' : 'Present',
          'originalStatus': att.originalStatus,
          'isAdminChanged': att.isAdminChanged,
          'adminChangeReason': att.adminChangeReason,
        });
      });

      final record = {
        'date': _displayHistoryDateString,
        'canonicalDate': dateStr,
        'fullDate': _displayHistoryDateString,
        'present': present,
        'absent': absent,
        'total': total > 0 ? total : studentsMap.length,
        'percentage': percentage,
        'hasAdminChanges': hasAdminChanges,
        'submitterName': submitterName,
        'students': studentRows,
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
      await _loadStudentsAndAttendanceForSelectedClass();
    }
  }

  Future<void> _pickHistoryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _historyDate,
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
        _historyDate = picked;
      });
      await _loadHistoryForClass();
    }
  }

  void _markAllPresent() {
    if (_isAttendanceSubmitted) return;
    setState(() {
      for (var s in _students) {
        s['status'] = 'Present';
      }
    });
  }

  void _showConfirmationDialog() {
    if (_isAttendanceSubmitted || _students.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Save Attendance?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to save attendance?',
                style: TextStyle(fontSize: 14, color: AppColors.textMain),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once attendance is saved, it cannot be changed.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
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
                _saveAttendance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CONFIRM & SAVE', style: TextStyle(fontWeight: FontWeight.w700)),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_isAttendanceSubmitted) return;
    final classId = _selectedClassId;
    final currentUser = _authService.currentUser;
    if (classId.isEmpty || currentUser == null) return;

    final userDoc = await _firestoreService.getUserDocument(currentUser.uid);
    final teacherName = userDoc?['name'] as String? ?? 'Teacher';

    final dateStr = _formattedDateString;
    List<AttendanceModel> attendanceList = [];

    for (var s in _students) {
      final studentId = s['studentId'] as String;
      final status = s['status'] as String;
      final attId = AttendanceModel.generateId(classId, studentId, dateStr);

      attendanceList.add(
        AttendanceModel(
          attendanceId: attId,
          studentId: studentId,
          classId: classId,
          date: dateStr,
          status: status,
          markedBy: currentUser.uid,
          markedByRole: 'teacher',
          markedByName: teacherName,
        ),
      );
    }

    final sessionData = {
      'sessionId': '${classId}_$dateStr',
      'classId': classId,
      'className': _selectedClassName,
      'date': dateStr,
      'submittedBy': currentUser.uid,
      'submittedByRole': 'teacher',
      'submittedByName': teacherName,
    };

    try {
      await _attendanceRepository.saveAttendanceBatch(attendanceList, sessionData: sessionData);

      // Create notification for admin
      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';
      final notification = NotificationModel(
        notificationId: notificationId,
        recipientId: 'admin',
        recipientRole: 'admin',
        type: 'attendance_submitted',
        title: 'Attendance Submitted',
        message: 'Teacher $teacherName submitted attendance for Class $_selectedClassName on $dateStr ($_presentCount Present, $_absentCount Absent).',
        referenceId: '${classId}_$dateStr',
        referenceType: 'attendance',
        isRead: false,
      );
      await NotificationRepository().createNotification(notification);

      if (mounted) {
        setState(() {
          _isAttendanceSubmitted = true;
        });
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
        _loadHistoryForClass();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classNames = _assignedClasses.isNotEmpty
        ? _assignedClasses.map((c) => c.className).toList()
        : ['No Classes Assigned'];

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
        child: _isLoading
            ? const Center(child: AppLoadingIndicator())
            : SingleChildScrollView(
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
                          _buildControlsCard(classNames),
                          const SizedBox(height: 16),
                          if (_isAttendanceSubmitted) ...[
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
                                  Icon(Icons.lock_outline_rounded, color: AppColors.darkEmerald, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Attendance for this class and date has already been submitted and cannot be edited by a Teacher.',
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
                              if (_isAttendanceSubmitted)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightEmerald,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Attendance already submitted',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkEmerald,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              else
                                PrimaryButton(
                                  text: 'Save Attendance',
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
                    value: classNames.contains(_selectedClassName) ? _selectedClassName : classNames.first,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
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
        if (!_isAttendanceSubmitted)
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
              color: AppColors.lightEmerald,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Locked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.darkEmerald,
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
      onTap: _isAttendanceSubmitted
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

  Widget _buildHistoryView(List<String> classNames) {
    if (_historyClassName.isEmpty && classNames.isNotEmpty) {
      _historyClassName = classNames.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Class & Calendar Selectors
        _buildHistorySelectors(classNames),
        const SizedBox(height: 16),

        // 2. Attendance History Heading & List
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
                      'No attendance records found for $_displayHistoryDateString.',
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
                                  '${record['present']} Present · ${record['absent']} Absent · By: ${record['submitterName']}',
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
                                      'Admin Changes',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
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
    return Container(
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
                        value: classNames.contains(_historyClassName) ? _historyClassName : classNames.first,
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary),
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
                        'Select Date',
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
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _historyDate = DateTime.now();
                });
                _loadHistoryForClass();
              },
              icon: const Icon(Icons.today_rounded, size: 16, color: AppColors.primaryEmerald),
              label: const Text('Today', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.w600, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        '${record['fullDate']} · $_historyClassName (Read-Only)',
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
