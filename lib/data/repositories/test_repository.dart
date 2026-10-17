import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mark_audit_model.dart';
import '../models/mark_model.dart';
import '../models/notification_model.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';

class TestRepository {
  final FirestoreService _firestoreService;

  TestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateTestId() => _firestoreService.generateTestId();

  Future<void> saveTest(TestModel test) async {
    try {
      await _firestoreService.saveTestDocument(test.testId, test.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to create this test.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to save test.');
    }
  }

  Future<void> updateTest(TestModel test) async {
    try {
      await _firestoreService.updateTestDocument(test.testId, test.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to update this test.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update test.');
    }
  }

  Future<void> cancelTest(String testId) async {
    try {
      await _firestoreService.cancelTestDocument(testId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to cancel this test.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to cancel test.');
    }
  }

  Future<void> deleteTest(String testId, {NotificationModel? adminNotification}) async {
    try {
      // Historical marks and marks audit/history are preserved
      if (adminNotification != null) {
        await _firestoreService.deleteTestWithNotification(
          testId,
          adminNotification.toMap(),
          adminNotification.notificationId,
        );
      } else {
        await _firestoreService.deleteTestDocument(testId);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to delete this test.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete test.');
    }
  }

  Future<List<TestModel>> getAllTests() async {
    try {
      final docs = await _firestoreService.getAllTestDocuments();
      return docs.map((doc) => TestModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<TestModel>> getTestsForClass(String classId) async {
    try {
      final docs = await _firestoreService.getTestDocumentsForClass(classId);
      return docs.map((doc) => TestModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<TestModel?> getTest(String testId) async {
    try {
      final data = await _firestoreService.getTestDocument(testId);
      if (data != null) {
        return TestModel.fromMap(data, testId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMarksBatch(List<MarkModel> marks) async {
    try {
      await _firestoreService.saveMarksBatch(marks);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to save marks for this class.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to save marks.');
    }
  }

  Future<void> saveMarksBatchWithAudit(
      List<MarkModel> marks, List<MarkAuditModel> audits) async {
    try {
      await _firestoreService.saveMarksBatchWithAudit(marks, audits);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. You do not have permission to save marks for this class.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to save marks.');
    }
  }

  Future<List<MarkModel>> getMarksForTest(String testId, {String? classId}) async {
    try {
      final docs = await _firestoreService.getMarkDocumentsForTest(testId, classId: classId);
      return docs.map((doc) => MarkModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<MarkAuditModel>> getMarkAuditsForTest(String testId, {String? classId}) async {
    try {
      final docs = await _firestoreService.getMarkAuditDocumentsForTest(testId, classId: classId);
      return docs.map((doc) => MarkAuditModel.fromMap(doc.data(), doc.id)).toList();
    } catch (_) {
      return [];
    }
  }
}
