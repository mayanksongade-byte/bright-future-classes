import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/teacher_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../classes/screens/class_details_screen.dart';

class TeacherAssignedClassesScreen extends StatefulWidget {
  const TeacherAssignedClassesScreen({super.key});

  @override
  State<TeacherAssignedClassesScreen> createState() =>
      _TeacherAssignedClassesScreenState();
}

class _TeacherAssignedClassesScreenState
    extends State<TeacherAssignedClassesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<ClassModel> _assignedClasses = [];
  Map<String, int> _classStudentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadAssignedClasses();
  }

  Future<void> _loadAssignedClasses() async {
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
        Map<String, int> counts = {};

        for (var classId in classIds) {
          final classData = await _firestoreService.getClassDocument(classId);
          if (classData != null) {
            final cls = ClassModel.fromMap(classData, classId);
            classes.add(cls);

            final studentDocs =
                await _firestoreService.getStudentsDocumentsByClassId(classId);
            counts[classId] = studentDocs.length;
          }
        }

        if (mounted) {
          setState(() {
            _assignedClasses = classes;
            _classStudentCounts = counts;
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
          'Assigned Classes',
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
                onRefresh: _loadAssignedClasses,
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
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _assignedClasses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cls = _assignedClasses[index];
                          final count = _classStudentCounts[cls.classId] ?? 0;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ClassDetailsScreen(classModel: cls),
                                  ),
                                );
                                _loadAssignedClasses();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.class_outlined,
                                        color: AppColors.teacherAccent,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cls.className,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Standard: ${cls.standard} • Medium: ${cls.medium} • ${cls.academicYear}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightEmerald,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$count Students',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
