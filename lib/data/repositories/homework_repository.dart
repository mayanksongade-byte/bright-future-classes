import '../models/homework_model.dart';
import '../services/firestore_service.dart';

class HomeworkRepository {
  final FirestoreService _firestoreService;

  HomeworkRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateHomeworkId() => _firestoreService.generateHomeworkId();

  Future<void> saveHomework(HomeworkModel homework) async {
    await _firestoreService.saveHomeworkDocument(
        homework.homeworkId, homework.toMap());
  }

  Future<void> updateHomework(HomeworkModel homework) async {
    await _firestoreService.updateHomeworkDocument(
        homework.homeworkId, homework.toMap());
  }

  Future<void> deleteHomework(String homeworkId) async {
    await _firestoreService.deleteHomeworkDocument(homeworkId);
  }

  Future<List<HomeworkModel>> getAllHomework() async {
    final docs = await _firestoreService.getAllHomeworkDocuments();
    return docs
        .map((doc) => HomeworkModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<HomeworkModel?> getHomework(String homeworkId) async {
    final data = await _firestoreService.getHomeworkDocument(homeworkId);
    if (data != null) {
      return HomeworkModel.fromMap(data, homeworkId);
    }
    return null;
  }
}
