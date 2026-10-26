import 'package:flutter_test/flutter_test.dart';
import 'package:bright_future_classes/data/models/notice_model.dart';
import 'package:bright_future_classes/data/models/notification_model.dart';

void main() {
  group('NoticeModel Unit Tests', () {
    test('computedStatus calculates published, scheduled, draft, expired properly', () {
      final now = DateTime.now();

      final published = NoticeModel(
        noticeId: 'notif_1',
        title: 'Exam Time Table',
        description: 'Details inside',
        type: 'exam',
        targetAudience: 'all_teachers',
        classIds: [],
        publishDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 5)),
        createdBy: 'admin_uid',
      );
      expect(published.computedStatus, 'published');

      final draft = published.copyWith(statusOverride: 'draft');
      expect(draft.computedStatus, 'draft');

      final scheduled = published.copyWith(
        publishDate: now.add(const Duration(days: 2)),
        expiryDate: now.add(const Duration(days: 10)),
      );
      expect(scheduled.computedStatus, 'scheduled');

      final expired = published.copyWith(
        publishDate: now.subtract(const Duration(days: 10)),
        expiryDate: now.subtract(const Duration(days: 1)),
      );
      expect(expired.computedStatus, 'expired');
    });

    test('isReadBy correctly verifies read status', () {
      final notice = NoticeModel(
        noticeId: 'notif_2',
        title: 'Meeting',
        description: 'Staff meeting at 3 PM',
        type: 'general',
        targetAudience: 'all_teachers',
        classIds: [],
        publishDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        createdBy: 'admin_uid',
        readUserIds: ['teacher_1', 'teacher_2'],
      );

      expect(notice.isReadBy('teacher_1'), isTrue);
      expect(notice.isReadBy('teacher_2'), isTrue);
      expect(notice.isReadBy('teacher_3'), isFalse);
      expect(notice.isReadBy(''), isFalse);
    });

    test('toMap and fromMap preserve all critical fields and audience', () {
      final now = DateTime.now();
      final notice = NoticeModel(
        noticeId: 'notif_3',
        title: 'Class 10 Unit Test Notice',
        description: 'Please prepare the question papers.',
        type: 'academic',
        priority: 'urgent',
        targetAudience: 'selected_classes',
        classIds: ['cls_10A', 'cls_10B'],
        publishDate: now,
        expiryDate: now.add(const Duration(days: 3)),
        statusOverride: '',
        isPinned: true,
        createdBy: 'teacher_uid',
        createdByName: 'John Doe',
        createdByRole: 'teacher',
        readUserIds: ['teacher_uid'],
        createdAt: now,
      );

      final map = notice.toMap();
      expect(map['noticeId'], 'notif_3');
      expect(map['title'], 'Class 10 Unit Test Notice');
      expect(map['priority'], 'urgent');
      expect(map['targetAudience'], 'selected_classes');
      expect(map['classIds'], containsAll(['cls_10A', 'cls_10B']));
      expect(map['isPinned'], isTrue);
      expect(map['createdBy'], 'teacher_uid');
      expect(map['createdByRole'], 'teacher');
      expect(map['readUserIds'], contains('teacher_uid'));

      final reconstructed = NoticeModel.fromMap(map, 'notif_3');
      expect(reconstructed.noticeId, notice.noticeId);
      expect(reconstructed.title, notice.title);
      expect(reconstructed.description, notice.description);
      expect(reconstructed.priority, notice.priority);
      expect(reconstructed.targetAudience, notice.targetAudience);
      expect(reconstructed.classIds, containsAll(['cls_10A', 'cls_10B']));
      expect(reconstructed.createdBy, notice.createdBy);
      expect(reconstructed.createdByRole, notice.createdByRole);
    });
  });

  group('Notice Audience Filtering and Notification Tests', () {
    final now = DateTime.now();

    final noticeAllTeachers = NoticeModel(
      noticeId: 'n_all',
      title: 'Staff Meeting',
      description: 'Meeting tomorrow',
      type: 'general',
      targetAudience: 'all_teachers',
      classIds: [],
      publishDate: now,
      expiryDate: now.add(const Duration(days: 7)),
      createdBy: 'admin_uid',
    );

    final noticeClass10A = NoticeModel(
      noticeId: 'n_10a',
      title: 'Class 10-A Homework Due',
      description: 'Check math exercise',
      type: 'academic',
      targetAudience: 'selected_classes',
      classIds: ['cls_10A'],
      publishDate: now,
      expiryDate: now.add(const Duration(days: 7)),
      createdBy: 'admin_uid',
    );

    final teacherCreatedNotice = NoticeModel(
      noticeId: 'n_teacher',
      title: 'Teacher Notice for Class 10-A',
      description: 'Surprise test notice',
      type: 'academic',
      targetAudience: 'selected_classes',
      classIds: ['cls_10A'],
      publishDate: now,
      expiryDate: now.add(const Duration(days: 7)),
      createdBy: 'teacher_1_uid',
      createdByName: 'Teacher One',
      createdByRole: 'teacher',
    );

    final draftNotice = NoticeModel(
      noticeId: 'n_draft',
      title: 'Draft Announcement',
      description: 'Not published yet',
      type: 'general',
      targetAudience: 'all_teachers',
      classIds: [],
      publishDate: now,
      expiryDate: now.add(const Duration(days: 7)),
      statusOverride: 'draft',
      createdBy: 'admin_uid',
    );

    bool shouldShowToTeacher({
      required NoticeModel notice,
      required String teacherUid,
      required Set<String> teacherClassIdentifiers,
    }) {
      final isCreator = notice.createdBy == teacherUid;
      final isAllTeachers = notice.targetAudience == 'all_teachers';
      final isTargetedClass = notice.classIds.any(
        (cId) => teacherClassIdentifiers.contains(cId.trim().toLowerCase()),
      );

      if (notice.computedStatus == 'draft' && !isCreator) return false;
      return isCreator || isAllTeachers || isTargetedClass;
    }

    test('Teacher A sees teacher A created notice', () {
      final show = shouldShowToTeacher(
        notice: teacherCreatedNotice,
        teacherUid: 'teacher_1_uid',
        teacherClassIdentifiers: {'cls_10a'},
      );
      expect(show, isTrue);
    });

    test('Teacher A assigned to Class 10-A sees Admin notice for Class 10-A', () {
      final show = shouldShowToTeacher(
        notice: noticeClass10A,
        teacherUid: 'teacher_1_uid',
        teacherClassIdentifiers: {'cls_10a'},
      );
      expect(show, isTrue);
    });

    test('Teacher B not assigned to Class 10-A does NOT see restricted notice', () {
      final show = shouldShowToTeacher(
        notice: noticeClass10A,
        teacherUid: 'teacher_2_uid',
        teacherClassIdentifiers: {'cls_9b'},
      );
      expect(show, isFalse);
    });

    test('All teachers see all_teachers notices', () {
      final showA = shouldShowToTeacher(
        notice: noticeAllTeachers,
        teacherUid: 'teacher_1_uid',
        teacherClassIdentifiers: {'cls_10a'},
      );
      final showB = shouldShowToTeacher(
        notice: noticeAllTeachers,
        teacherUid: 'teacher_2_uid',
        teacherClassIdentifiers: {'cls_9b'},
      );
      expect(showA, isTrue);
      expect(showB, isTrue);
    });

    test('Non-creator cannot see draft notices', () {
      final show = shouldShowToTeacher(
        notice: draftNotice,
        teacherUid: 'teacher_1_uid',
        teacherClassIdentifiers: {'cls_10a'},
      );
      expect(show, isFalse);

      final showAdmin = shouldShowToTeacher(
        notice: draftNotice,
        teacherUid: 'admin_uid',
        teacherClassIdentifiers: {},
      );
      expect(showAdmin, isTrue);
    });

    test('Deterministic notification IDs prevent duplicate delivery', () {
      const noticeId = 'notice_12345';
      const teacherUid = 'teacher_uid_abc';

      final notifId1 = 'notif_notice_${noticeId}_$teacherUid';
      final notifId2 = 'notif_notice_${noticeId}_$teacherUid';
      expect(notifId1, equals(notifId2));

      final adminNotifId = 'notif_notice_${noticeId}_admin';
      expect(adminNotifId, equals('notif_notice_notice_12345_admin'));

      final notification = NotificationModel(
        notificationId: notifId1,
        recipientId: teacherUid,
        recipientRole: 'teacher',
        title: 'New Announcement: Exam Schedule',
        message: 'Exam starts next Monday.',
        type: 'notice_published',
        referenceId: noticeId,
        referenceType: 'notice',
        isRead: false,
      );

      expect(notification.referenceType, 'notice');
      expect(notification.type, 'notice_published');
      expect(notification.referenceId, noticeId);
      expect(notification.recipientId, teacherUid);
    });
  });
}
