import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/firestore_service.dart';

class StudentRepository {
  final FirestoreService _firestoreService;

  StudentRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> createStudent(StudentModel student) async {
    try {
      final exists =
          await _firestoreService.checkStudentExists(student.studentId);
      if (exists) {
        throw Exception(
            'Student ID "${student.studentId}" already exists. Please use a unique ID.');
      }
      await _firestoreService.saveStudentDocument(
        student.studentId,
        student.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can create student records.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving student.');
    }
  }

  Future<List<StudentModel>> getStudents() async {
    try {
      final docs = await _firestoreService.getStudentsDocuments();
      return docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch students.');
      }
      throw Exception('Failed to load students: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading students.');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      if (studentId.isEmpty) {
        throw Exception('Student ID is required to delete a student.');
      }
      await _firestoreService.deleteStudentDocument(studentId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can delete students.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting student.');
    }
  }

  Future<int> getStudentCount() async {
    try {
      return await _firestoreService.getStudentCount();
    } catch (_) {
      return 0;
    }
  }
}
