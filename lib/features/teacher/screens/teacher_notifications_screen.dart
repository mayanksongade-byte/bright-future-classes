import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': 'N1',
      'title': 'Faculty Meeting Scheduled',
      'message': 'Monthly staff review meeting tomorrow at 4:00 PM in Conference Room A.',
      'time': '2 hours ago',
      'isRead': false,
      'type': 'Notice',
    },
    {
      'id': 'N2',
      'title': 'Attendance Reminder',
      'message': 'Please submit Class 11-B attendance for today.',
      'time': '5 hours ago',
      'isRead': true,
      'type': 'Reminder',
    },
    {
      'id': 'N3',
      'title': 'New Exam Schedule Published',
      'message': 'Mid-term timetable has been updated by the Admin office.',
      'time': 'Yesterday',
      'isRead': true,
      'type': 'System',
    },
  ];

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
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _mockNotifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notif = _mockNotifications[index];
            final bool isRead = notif['isRead'] as bool;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRead
                    ? AppColors.surface
                    : AppColors.primaryEmerald.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRead
                      ? AppColors.border
                      : AppColors.primaryEmerald.withValues(alpha: 0.3),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notif['title'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            Text(
                              notif['time'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['message'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
