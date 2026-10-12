import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../data/models/attendance_audit_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/firestore_service.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  Future<void> _markAsRead(NotificationModel notif) async {
    if (!notif.isRead) {
      try {
        await _notificationRepository.markAsRead(notif.notificationId);
      } catch (_) {}
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notif) async {
    await _markAsRead(notif);

    if (notif.referenceType == 'attendance' && notif.referenceId != null) {
      // referenceId is classId_date
      final parts = notif.referenceId!.split('_');
      if (parts.length >= 2) {
        final classId = parts[0];
        final date = parts.sublist(1).join('_');
        
        // Load attendance and audits for this session
        final attendanceRecords = await _attendanceRepository.getAttendanceForClassAndDate(classId, date);
        final audits = await _attendanceRepository.getAuditsForClassAndDate(classId, date);

        // Fetch student names using class-scoped query to satisfy Teacher Firestore Security Rules
        final Map<String, String> studentNamesMap = {};
        try {
          final studentDocs = await _firestoreService.getStudentsDocumentsByClassId(classId);
          for (var doc in studentDocs) {
            final data = doc.data();
            final docId = doc.id;
            final mapStudentId = data['studentId'] as String? ?? '';
            final name = data['name'] as String? ?? data['fullName'] as String? ?? '';

            if (name.isNotEmpty && !name.startsWith('Student ')) {
              studentNamesMap[docId] = name;
              studentNamesMap[docId.trim().toUpperCase()] = name;
              if (mapStudentId.isNotEmpty) {
                studentNamesMap[mapStudentId] = name;
                studentNamesMap[mapStudentId.trim().toUpperCase()] = name;
              }
            }
          }
        } catch (e) {
          debugPrint('[TeacherNotificationsScreen] Error loading class student names for classId "$classId": $e');
        }

        // Fallback: If map is still empty, try general students list if permitted
        if (studentNamesMap.isEmpty) {
          try {
            final allStudentDocs = await _firestoreService.getStudentsDocuments();
            for (var doc in allStudentDocs) {
              final data = doc.data();
              final docId = doc.id;
              final mapStudentId = data['studentId'] as String? ?? '';
              final name = data['name'] as String? ?? data['fullName'] as String? ?? '';

              if (name.isNotEmpty && !name.startsWith('Student ')) {
                studentNamesMap[docId] = name;
                studentNamesMap[docId.trim().toUpperCase()] = name;
                if (mapStudentId.isNotEmpty) {
                  studentNamesMap[mapStudentId] = name;
                  studentNamesMap[mapStudentId.trim().toUpperCase()] = name;
                }
              }
            }
          } catch (e) {
            debugPrint('[TeacherNotificationsScreen] Error loading all student documents: $e');
          }
        }

        if (!mounted) return;
        _showTeacherAttendanceAuditModal(classId, date, attendanceRecords, audits, studentNamesMap);
      }
    }
  }

  void _confirmDeleteNotification(NotificationModel notif, String currentUserUid) {
    if (notif.recipientId != currentUserUid) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Notification?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.of(dialogContext).pop();
                try {
                  await _notificationRepository.deleteNotification(notif.notificationId);
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Notification deleted.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete notification: ${e.toString().replaceAll("Exception: ", "")}'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showTeacherAttendanceAuditModal(
    String classId,
    String date,
    List<AttendanceModel> records,
    List<AttendanceAuditModel> audits,
    Map<String, String> studentNamesMap,
  ) {
    String resolveName(String studentId) {
      if (studentNamesMap.containsKey(studentId)) {
        return studentNamesMap[studentId]!;
      }
      final normalized = studentId.trim().toUpperCase();
      if (studentNamesMap.containsKey(normalized)) {
        return studentNamesMap[normalized]!;
      }
      debugPrint('[TeacherNotificationsScreen] DIAGNOSTIC: Student record not found for studentId: "$studentId" in classId "$classId". Total mapped keys: ${studentNamesMap.length}');
      return 'Student ($studentId)';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  const Text(
                    'Attendance Updated by Admin (Read-Only)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $date · Class ID: $classId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (audits.isNotEmpty) ...[
                    const Text(
                      'Admin Change History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: audits.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final audit = audits[index];
                          final realName = resolveName(audit.studentId);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  realName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                Text(
                                  'Student ID: ${audit.studentId}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${audit.oldStatus.toUpperCase()} → ${audit.newStatus.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                                Text(
                                  'Reason: "${audit.reason.isNotEmpty ? audit.reason : 'No reason provided'}"',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Current Attendance Records',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: records.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final att = records[index];
                        final bool isPres = att.status.toLowerCase() == 'present';
                        final realName = resolveName(att.studentId);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isPres
                                    ? AppColors.lightEmerald
                                    : AppColors.error.withValues(alpha: 0.1),
                                child: Text(
                                  realName.isNotEmpty ? realName[0] : 'S',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      realName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'Student ID: ${att.studentId}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (att.isAdminChanged)
                                      const Text(
                                        'Updated by Admin',
                                        style: TextStyle(
                                          fontSize: 11,
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
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  att.status.toUpperCase(),
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
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

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
          'Notifications',
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
        child: user == null
            ? const Center(child: Text('Please log in.'))
            : StreamBuilder<List<NotificationModel>>(
                stream: _notificationRepository.streamNotificationsForRecipient(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: AppLoadingIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load notifications.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No notifications found.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final bool isRead = notif.isRead;

                      return InkWell(
                        onTap: () => _handleNotificationTap(notif),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.surface
                                : AppColors.primaryEmerald
                                    .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRead
                                  ? AppColors.border
                                  : AppColors.primaryEmerald
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.teacherAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w700,
                                              color: AppColors.textMain,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          notif.createdAt != null
                                              ? '${notif.createdAt!.day}/${notif.createdAt!.month}/${notif.createdAt!.year}'
                                              : 'Recent',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif.message,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (val) {
                                  if (val == 'delete') {
                                    _confirmDeleteNotification(notif, user.uid);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded,
                                            size: 18, color: AppColors.error),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
