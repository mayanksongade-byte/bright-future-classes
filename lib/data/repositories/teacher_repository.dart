import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import '../services/firestore_service.dart';

class TeacherRepository {
  final FirestoreService _firestoreService;

  TeacherRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateTeacherId() {
    return _firestoreService.generateTeacherId();
  }

  Future<void> createTeacher(TeacherModel teacher) async {
    try {
      await _firestoreService.saveTeacherDocument(
        teacher.teacherId,
        teacher.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can create teacher records.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving teacher.');
    }
  }

  Future<List<TeacherModel>> getTeachers() async {
    try {
      final docs = await _firestoreService.getTeachersDocuments();
      return docs
          .map((doc) => TeacherModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch teachers.');
      }
      throw Exception('Failed to load teachers: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading teachers.');
    }
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    try {
      if (teacher.teacherId.isEmpty) {
        throw Exception('Teacher ID is required to update a teacher.');
      }
      await _firestoreService.updateTeacherDocument(
        teacher.teacherId,
        teacher.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can update teachers.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating teacher.');
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      if (teacherId.isEmpty) {
        throw Exception('Teacher ID is required to delete a teacher.');
      }
      await _firestoreService.deleteTeacherDocument(teacherId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can delete teachers.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting teacher.');
    }
  }

  Future<int> getTeacherCount() async {
    try {
      return await _firestoreService.getTeacherCount();
    } catch (_) {
      return 0;
    }
  }
}
