import 'package:flutter_test/flutter_test.dart';
import 'package:bright_future_classes/data/models/teacher_model.dart';
import 'package:bright_future_classes/data/models/test_model.dart';
import 'package:bright_future_classes/data/models/mark_model.dart';
import 'package:bright_future_classes/data/models/mark_audit_model.dart';

void main() {
  group('Teacher Model & Subject Authorization Tests', () {
    test('Teacher correctly identifies assigned subjects with case-insensitivity', () {
      final teacher = TeacherModel(
        teacherId: 'teacher_123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        subjects: ['Mathematics', 'Science'],
        classIds: ['class_1', 'class_2'],
      );

      expect(teacher.teachesSubject('Mathematics'), isTrue);
      expect(teacher.teachesSubject('mathematics'), isTrue);
      expect(teacher.teachesSubject('Science'), isTrue);
      expect(teacher.teachesSubject('science'), isTrue);
      expect(teacher.teachesSubject('English'), isFalse);
      expect(teacher.classIds.contains('class_1'), isTrue);
      expect(teacher.classIds.contains('class_3'), isFalse);
    });

    test('Teacher legacy single subject fallback', () {
      final teacher = TeacherModel(
        teacherId: 'teacher_456',
        name: 'Jane Smith',
        email: 'jane@example.com',
        phone: '0987654321',
        subject: 'English',
        classIds: ['class_1'],
      );

      expect(teacher.teachesSubject('English'), isTrue);
      expect(teacher.teachesSubject('english'), isTrue);
      expect(teacher.teachesSubject('Mathematics'), isFalse);
    });
  });

  group('Mark & Audit Model Tests', () {
    test('MarkModel generates unique deterministic ID using testId and studentId', () {
      final markId = MarkModel.generateId('test_001', 'student_999');
      expect(markId, equals('test_001_student_999'));
    });

    test('MarkModel toMap uses exact studentId and testId and preserves classId', () {
      final mark = MarkModel(
        markId: 'test_001_student_999',
        testId: 'test_001',
        studentId: 'student_999',
        classId: 'class_001',
        marks: 45.5,
        isAbsent: false,
        remarks: 'Good progress',
      );

      final map = mark.toMap();
      expect(map['markId'], equals('test_001_student_999'));
      expect(map['testId'], equals('test_001'));
      expect(map['studentId'], equals('student_999'));
      expect(map['classId'], equals('class_001'));
      expect(map['marks'], equals(45.5));
      expect(map['isAbsent'], isFalse);
      expect(map['remarks'], equals('Good progress'));
    });

    test('MarkAuditModel preserves full audit metadata', () {
      final audit = MarkAuditModel(
        auditId: 'audit_001',
        testId: 'test_001',
        testName: 'Midterm Exam',
        classId: 'class_001',
        studentId: 'student_999',
        studentName: 'Alice',
        oldMarks: 40.0,
        newMarks: 45.5,
        editedByUid: 'teacher_uid',
        editedByRole: 'teacher',
        editedByName: 'Mr. Teacher',
      );

      final map = audit.toMap();
      expect(map['auditId'], equals('audit_001'));
      expect(map['testId'], equals('test_001'));
      expect(map['classId'], equals('class_001'));
      expect(map['studentId'], equals('student_999'));
      expect(map['oldMarks'], equals(40.0));
      expect(map['newMarks'], equals(45.5));
      expect(map['editedByUid'], equals('teacher_uid'));
      expect(map['editedByRole'], equals('teacher'));
    });
  });

  group('Test Model Tests', () {
    test('TestModel toMap contains classId and subject for authorization', () {
      final test = TestModel(
        testId: 'test_100',
        testName: 'Algebra Quiz',
        classId: 'class_math_1',
        subject: 'Mathematics',
        testDate: '2026-10-20',
        totalMarks: 50.0,
        passingMarks: 20.0,
        createdBy: 'teacher_uid',
        createdByName: 'John Doe',
        createdByRole: 'teacher',
      );

      final map = test.toMap();
      expect(map['testId'], equals('test_100'));
      expect(map['classId'], equals('class_math_1'));
      expect(map['subject'], equals('Mathematics'));
      expect(map['totalMarks'], equals(50.0));
    });
  });
}
