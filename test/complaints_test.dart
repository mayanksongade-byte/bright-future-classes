import 'package:flutter_test/flutter_test.dart';
import 'package:bright_future_classes/data/models/complaint_model.dart';
import 'package:bright_future_classes/data/models/teacher_model.dart';
import 'package:bright_future_classes/data/models/class_model.dart';

void main() {
  group('ComplaintModel Tests', () {
    test('toMap and fromMap preserve all critical fields and identifiers', () {
      final now = DateTime(2026, 10, 19, 10, 30);
      final complaint = ComplaintModel(
        complaintId: 'complaint_001',
        studentId: 'student_123',
        classId: 'class_10_a',
        type: 'Academic',
        title: 'Frequent Disruption in Science Class',
        description: 'Student repeatedly talks during instruction.',
        priority: 'High',
        status: 'Open',
        resolutionNote: '',
        createdBy: 'teacher_999',
        createdByName: 'Mrs. Sharma',
        createdByRole: 'teacher',
        incidentDate: '18 Oct 2026',
        activityHistory: [
          {
            'event': 'Complaint reported (19 Oct 2026)',
            'timestamp': now.toIso8601String(),
            'by': 'Mrs. Sharma',
          }
        ],
        createdAt: now,
      );

      final map = complaint.toMap();
      expect(map['studentId'], equals('student_123'));
      expect(map['classId'], equals('class_10_a'));
      expect(map['title'], equals('Frequent Disruption in Science Class'));
      expect(map['priority'], equals('High'));
      expect(map['status'], equals('Open'));
      expect(map['createdBy'], equals('teacher_999'));
      expect(map['createdByRole'], equals('teacher'));
      expect(map['incidentDate'], equals('18 Oct 2026'));
      expect(map['activityHistory'], isNotEmpty);

      final parsed = ComplaintModel.fromMap(map, 'complaint_001');
      expect(parsed.complaintId, equals('complaint_001'));
      expect(parsed.studentId, equals('student_123'));
      expect(parsed.classId, equals('class_10_a'));
      expect(parsed.title, equals('Frequent Disruption in Science Class'));
      expect(parsed.type, equals('Academic'));
      expect(parsed.priority, equals('High'));
      expect(parsed.status, equals('Open'));
      expect(parsed.createdBy, equals('teacher_999'));
      expect(parsed.incidentDate, equals('18 Oct 2026'));
      expect(parsed.activityHistory.first['event'], equals('Complaint reported (19 Oct 2026)'));
    });

    test('copyWith updates status and resolution metadata cleanly', () {
      final now = DateTime(2026, 10, 19, 10, 30);
      final resolvedDate = DateTime(2026, 10, 20, 14, 0);

      final complaint = ComplaintModel(
        complaintId: 'complaint_001',
        studentId: 'student_123',
        classId: 'class_10_a',
        type: 'Academic',
        title: 'Frequent Disruption in Science Class',
        description: 'Student repeatedly talks during instruction.',
        priority: 'High',
        status: 'Open',
        resolutionNote: '',
        createdBy: 'teacher_999',
        createdByName: 'Mrs. Sharma',
        createdByRole: 'teacher',
        incidentDate: '18 Oct 2026',
        createdAt: now,
      );

      final resolved = complaint.copyWith(
        status: 'Resolved',
        resolutionNote: 'Moved seating arrangement to front row and assigned reflective essay.',
        resolvedAt: resolvedDate,
        activityHistory: [
          {'event': 'Complaint reported (19 Oct 2026)'},
          {'event': 'Marked Under Review (19 Oct 2026)'},
          {'event': 'Resolved (20 Oct 2026)'},
        ],
      );

      expect(resolved.status, equals('Resolved'));
      expect(resolved.resolutionNote, contains('seating arrangement'));
      expect(resolved.resolvedAt, equals(resolvedDate));
      expect(resolved.activityHistory.length, equals(3));
      expect(resolved.studentId, equals('student_123'));
      expect(resolved.classId, equals('class_10_a'));
    });
  });

  group('Complaints Summary and Filter Logic Tests', () {
    test('Calculates summary counts accurately with case-insensitivity', () {
      final list = <ComplaintModel>[
        ComplaintModel(
          complaintId: '1',
          studentId: 's1',
          classId: 'c1',
          type: 'Academic',
          title: 'Issue 1',
          description: 'Desc 1',
          priority: 'High',
          status: 'Open',
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '2',
          studentId: 's2',
          classId: 'c1',
          type: 'Homework',
          title: 'Issue 2',
          description: 'Desc 2',
          priority: 'Medium',
          status: 'open', // lower case check
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '3',
          studentId: 's3',
          classId: 'c2',
          type: 'Behavior',
          title: 'Issue 3',
          description: 'Desc 3',
          priority: 'HIGH', // uppercase check
          status: 'Under Review',
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '4',
          studentId: 's4',
          classId: 'c2',
          type: 'Discipline',
          title: 'Issue 4',
          description: 'Desc 4',
          priority: 'Low',
          status: 'In Review', // variant synonym check
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '5',
          studentId: 's5',
          classId: 'c1',
          type: 'Academic',
          title: 'Issue 5',
          description: 'Desc 5',
          priority: 'Low',
          status: 'Resolved',
          createdBy: 'teacher_1',
        ),
      ];

      final openCount = list.where((c) => c.status.toLowerCase() == 'open').length;
      final highPriorityCount = list.where((c) => c.priority.toLowerCase() == 'high').length;
      final inReviewCount = list.where((c) {
        final st = c.status.toLowerCase();
        return st == 'under review' || st == 'in review';
      }).length;
      final resolvedCount = list.where((c) => c.status.toLowerCase() == 'resolved').length;

      expect(openCount, equals(2));
      expect(highPriorityCount, equals(2));
      expect(inReviewCount, equals(2));
      expect(resolvedCount, equals(1));
    });

    test('Status filtering properly filters matching complaints', () {
      final list = <ComplaintModel>[
        ComplaintModel(
          complaintId: '1',
          studentId: 's1',
          classId: 'c1',
          type: 'Academic',
          title: 'Issue 1',
          description: 'Desc 1',
          priority: 'High',
          status: 'Open',
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '2',
          studentId: 's2',
          classId: 'c1',
          type: 'Homework',
          title: 'Issue 2',
          description: 'Desc 2',
          priority: 'Medium',
          status: 'Under Review',
          createdBy: 'teacher_1',
        ),
        ComplaintModel(
          complaintId: '3',
          studentId: 's3',
          classId: 'c2',
          type: 'Behavior',
          title: 'Issue 3',
          description: 'Desc 3',
          priority: 'Low',
          status: 'Resolved',
          createdBy: 'teacher_1',
        ),
      ];

      List<ComplaintModel> filterByStatus(String statusFilter) {
        if (statusFilter == 'All') return list;
        return list.where((c) {
          final s = c.status.toLowerCase();
          final f = statusFilter.toLowerCase();
          if (f == 'under review' || f == 'in review') {
            return s == 'under review' || s == 'in review';
          }
          return s == f;
        }).toList();
      }

      expect(filterByStatus('All').length, equals(3));
      expect(filterByStatus('Open').length, equals(1));
      expect(filterByStatus('Under Review').length, equals(1));
      expect(filterByStatus('Resolved').length, equals(1));
    });
  });

  group('Teacher Scoped Identifier Resolution Tests', () {
    test('Teacher assigned class matching supports both doc ID and class name without collision', () {
      final teacher = TeacherModel(
        teacherId: 'teacher_101',
        name: 'Sharma Sir',
        email: 'sharma@example.com',
        phone: '9876543210',
        subjects: ['Science', 'Physics'],
        classIds: ['class_10_a', 'class_11_b'],
      );

      final classes = [
        ClassModel(classId: 'class_10_a', className: 'Class 10-A', standard: '10', medium: 'English', academicYear: '2026'),
        ClassModel(classId: 'class_11_b', className: 'Class 11-B', standard: '11', medium: 'English', academicYear: '2026'),
        ClassModel(classId: 'class_9_c', className: 'Class 9-C', standard: '9', medium: 'English', academicYear: '2026'),
      ];

      // Aggregate query identifiers
      final queryClassIds = <String>{};
      queryClassIds.addAll(teacher.classIds);
      for (final cls in classes) {
        if (teacher.classIds.contains(cls.classId)) {
          queryClassIds.add(cls.classId);
          queryClassIds.add(cls.className);
        }
      }

      expect(queryClassIds.contains('class_10_a'), isTrue);
      expect(queryClassIds.contains('Class 10-A'), isTrue);
      expect(queryClassIds.contains('class_11_b'), isTrue);
      expect(queryClassIds.contains('Class 11-B'), isTrue);
      expect(queryClassIds.contains('class_9_c'), isFalse);
      expect(queryClassIds.contains('Class 9-C'), isFalse);
    });
  });
}
