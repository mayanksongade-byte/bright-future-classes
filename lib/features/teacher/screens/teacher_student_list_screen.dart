import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../students/screens/student_details_screen.dart';

class TeacherStudentListScreen extends StatefulWidget {
  const TeacherStudentListScreen({super.key});

  @override
  State<TeacherStudentListScreen> createState() =>
      _TeacherStudentListScreenState();
}

class _TeacherStudentListScreenState extends State<TeacherStudentListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<ClassModel> _assignedClasses = [];
  Map<String, List<StudentModel>> _classStudentsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAssignedClassesAndStudents();
  }

  Future<void> _loadAssignedClassesAndStudents() async {
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
        Map<String, List<StudentModel>> classStudentsMap = {};

        for (var classId in classIds) {
          final classData = await _firestoreService.getClassDocument(classId);
          if (classData != null) {
            final cls = ClassModel.fromMap(classData, classId);
            classes.add(cls);

            final studentDocs =
                await _firestoreService.getStudentsDocumentsByClassId(classId);
            final students = studentDocs
                .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
                .toList();
            classStudentsMap[classId] = students;
          }
        }

        if (mounted) {
          setState(() {
            _assignedClasses = classes;
            _classStudentsMap = classStudentsMap;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToStudentDetails(StudentModel student) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(student: student),
      ),
    );
    _loadAssignedClassesAndStudents();
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
          'Assigned Students',
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
                onRefresh: _loadAssignedClassesAndStudents,
                color: AppColors.teacherAccent,
                child: _assignedClasses.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No classes assigned yet.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _assignedClasses.length,
                        itemBuilder: (context, index) {
                          final cls = _assignedClasses[index];
                          final students = _classStudentsMap[cls.classId] ?? [];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    border: Border(
                                      bottom:
                                          BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cls.className,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.lightEmerald,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${students.length} Students',
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
                                if (students.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text(
                                      'No students in this class.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: students.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (context, studentIndex) {
                                      final student = students[studentIndex];
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              _navigateToStudentDetails(
                                                  student),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .lightEmerald,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    color: AppColors
                                                        .primaryEmerald,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        student.name,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: AppColors
                                                              .textMain,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 2),
                                                      Text(
                                                        'ID: ${student.studentId} • Phone: ${student.phone}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .chevron_right_rounded,
                                                  color:
                                                      AppColors.textSecondary,
                                                  size: 20,
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
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
