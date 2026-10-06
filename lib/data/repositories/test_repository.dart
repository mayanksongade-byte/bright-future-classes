import '../models/mark_model.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';

class TestRepository {
  final FirestoreService _firestoreService;

  TestRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateTestId() => _firestoreService.generateTestId();

  Future<void> saveTest(TestModel test) async {
    await _firestoreService.saveTestDocument(test.testId, test.toMap());
  }

  Future<void> updateTest(TestModel test) async {
    await _firestoreService.updateTestDocument(test.testId, test.toMap());
  }

  Future<void> deleteTest(String testId) async {
    // Delete associated marks first
    await _firestoreService.deleteMarksForTest(testId);
    await _firestoreService.deleteTestDocument(testId);
  }

  Future<List<TestModel>> getAllTests() async {
    final docs = await _firestoreService.getAllTestDocuments();
    return docs.map((doc) => TestModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<TestModel>> getTestsForClass(String classId) async {
    final docs = await _firestoreService.getTestDocumentsForClass(classId);
    return docs.map((doc) => TestModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<TestModel?> getTest(String testId) async {
    final data = await _firestoreService.getTestDocument(testId);
    if (data != null) {
      return TestModel.fromMap(data, testId);
    }
    return null;
  }

  Future<void> saveMarksBatch(List<MarkModel> marks) async {
    await _firestoreService.saveMarksBatch(marks);
  }

  Future<List<MarkModel>> getMarksForTest(String testId) async {
    final docs = await _firestoreService.getMarkDocumentsForTest(testId);
    return docs.map((doc) => MarkModel.fromMap(doc.data(), doc.id)).toList();
  }
}
