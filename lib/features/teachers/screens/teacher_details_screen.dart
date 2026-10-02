import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/class_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../classes/screens/class_details_screen.dart';
import 'add_teacher_screen.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherDetailsScreen({super.key, required this.teacher});

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  late TeacherModel _teacher;

  final TeacherRepository _teacherRepository = TeacherRepository();
  final ClassRepository _classRepository = ClassRepository();
  final StudentRepository _studentRepository = StudentRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  bool _isLoading = true;
  List<ClassModel> _assignedClasses = [];
  Map<String, int> _classStudentCounts = {};
  int _totalStudentsAssigned = 0;

  int _todayPresent = 0;
  int _todayAbsent = 0;
  bool _hasTodayAttendance = false;

  @override
  void initState() {
    super.initState();
    _teacher = widget.teacher;
    _loadAllTeacherDetails();
  }

  Future<void> _loadAllTeacherDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Resolve Assigned Classes
      final allClasses = await _classRepository.getClasses();
      final assigned = allClasses
          .where((cls) => _teacher.classIds.contains(cls.classId))
          .toList();
      _assignedClasses = assigned;

      // 2. Resolve Student Counts per class and total
      final allStudents = await _studentRepository.getStudents();
      final Map<String, int> counts = {};
      int totalCount = 0;

      for (var cls in assigned) {
        final studentsInClass =
            allStudents.where((s) => s.classId == cls.classId).length;
        counts[cls.classId] = studentsInClass;
        totalCount += studentsInClass;
      }
      _classStudentCounts = counts;
      _totalStudentsAssigned = totalCount;

      // 3. Resolve Today's Attendance Summary for assigned classes
      try {
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        int present = 0;
        int absent = 0;
        bool hasRecords = false;

        for (var cls in assigned) {
          final attList = await _attendanceRepository.getAttendanceForClassAndDate(
              cls.classId, todayStr);
          if (attList.isNotEmpty) {
            hasRecords = true;
            for (var att in attList) {
              if (att.status.toLowerCase() == 'present') {
                present++;
              } else if (att.status.toLowerCase() == 'absent') {
                absent++;
              }
            }
          }
        }
        _todayPresent = present;
        _todayAbsent = absent;
        _hasTodayAttendance = hasRecords;
      } catch (_) {}

    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditTeacher() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddTeacherScreen(teacherToEdit: _teacher),
      ),
    );

    if (updated == true && mounted) {
      try {
        final teachers = await _teacherRepository.getTeachers();
        final refreshed = teachers.firstWhere(
          (t) => t.teacherId == _teacher.teacherId,
          orElse: () => _teacher,
        );
        setState(() {
          _teacher = refreshed;
        });
        _loadAllTeacherDetails();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _teacher.status.toLowerCase() == 'active';

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
          'Teacher Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryEmerald),
            onPressed: _navigateToEditTeacher,
            tooltip: 'Edit Teacher',
          ),
        ],
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER CARD
                        _buildHeaderCard(isActive),
                        const SizedBox(height: 20),

                        // SECTION 1 — PERSONAL INFORMATION
                        _buildSectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _buildInfoRow('Full Name', _teacher.name),
                            _buildInfoRow('Teacher ID', _teacher.teacherId),
                            _buildInfoRow('Status', isActive ? 'Active' : 'Inactive'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 2 — CONTACT INFORMATION
                        _buildSectionCard(
                          title: 'Contact Information',
                          icon: Icons.phone_outlined,
                          children: [
                            _buildInfoRow('Email', _teacher.email),
                            _buildInfoRow('Phone', _teacher.phone),
                            _buildInfoRow('Address',
                                _teacher.address.isNotEmpty ? _teacher.address : '-'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 3 — LOGIN INFORMATION
                        _buildSectionCard(
                          title: 'Login Information',
                          icon: Icons.badge_outlined,
                          children: [
                            _buildInfoRow('Login User ID',
                                (_teacher.userId != null && _teacher.userId!.isNotEmpty)
                                    ? _teacher.userId!
                                    : 'N/A'),
                            _buildInfoRow('Account Status',
                                isActive ? 'Active' : 'Inactive'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 4 — ASSIGNED CLASSES
                        _buildSectionCard(
                          title: 'Assigned Classes (${_assignedClasses.length})',
                          icon: Icons.class_outlined,
                          children: [
                            if (_assignedClasses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No classes assigned to this teacher.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _assignedClasses.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1, color: AppColors.border),
                                itemBuilder: (context, index) {
                                  final cls = _assignedClasses[index];
                                  final studentCount =
                                      _classStudentCounts[cls.classId] ?? 0;
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ClassDetailsScreen(
                                            classModel: cls,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cls.className,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textMain,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Standard: ${cls.standard} • Medium: ${cls.medium} • ${cls.academicYear}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.lightEmerald,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$studentCount Students',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.darkEmerald,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 5 — STUDENT SUMMARY
                        _buildSectionCard(
                          title: 'Student Summary',
                          icon: Icons.people_outline_rounded,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    size: 32,
                                    color: AppColors.teacherAccent,
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Students Assigned',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$_totalStudentsAssigned Students',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 6 — ATTENDANCE SUMMARY
                        _buildSectionCard(
                          title: 'Attendance Summary',
                          icon: Icons.calendar_today_outlined,
                          children: [
                            if (!_hasTodayAttendance)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No attendance marked today for assigned classes.',
                                  style: AppTextStyles.subtitle,
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Present Today',
                                      value: '$_todayPresent',
                                      color: AppColors.primaryEmerald,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricBox(
                                      label: 'Absent Today',
                                      value: '$_todayAbsent',
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // SECTION 7 — TEACHING ACTIVITY
                        _buildSectionCard(
                          title: 'Teaching Activity',
                          icon: Icons.analytics_outlined,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: 18, color: AppColors.primaryEmerald),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Active faculty member in good standing.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // EDIT TEACHER ACTION BUTTON
                        PrimaryButton(
                          text: 'Edit Teacher Profile',
                          onPressed: _navigateToEditTeacher,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Text(
                  _teacher.name.isNotEmpty ? _teacher.name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teacherAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _teacher.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Teacher ID: ${_teacher.teacherId}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.lightEmerald
                      : AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.darkEmerald : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_teacher.userId != null && _teacher.userId!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 16, color: AppColors.primaryEmerald),
                const SizedBox(width: 6),
                Text(
                  'Login User ID: ${_teacher.userId}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryEmerald,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryEmerald),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
