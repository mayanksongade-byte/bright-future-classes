import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../services/firestore_service.dart';

class ClassRepository {
  final FirestoreService _firestoreService;

  ClassRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> createClass(ClassModel classModel) async {
    try {
      final String classId = classModel.classId.isNotEmpty
          ? classModel.classId
          : _firestoreService.generateClassId();

      final updatedModel = classModel.copyWith(classId: classId);

      await _firestoreService.saveClassDocument(
        classId,
        updatedModel.toMap(),
      );
      return classId;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can create classes.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while creating class.');
    }
  }

  Future<List<ClassModel>> getClasses() async {
    try {
      final docs = await _firestoreService.getClassesDocuments();
      final classes = docs
          .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
          .toList();
      final uniqueMap = <String, ClassModel>{};
      for (var c in classes) {
        uniqueMap[c.classId] = c;
      }
      return uniqueMap.values.toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch classes.');
      }
      throw Exception('Failed to load classes: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading classes.');
    }
  }

  Stream<List<ClassModel>> streamClasses() {
    return _firestoreService.streamClassesDocuments().map((docs) {
      final classes = docs
          .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
          .toList();
      final uniqueMap = <String, ClassModel>{};
      for (var c in classes) {
        uniqueMap[c.classId] = c;
      }
      return uniqueMap.values.toList();
    });
  }

  Future<void> updateClass(ClassModel classModel) async {
    try {
      if (classModel.classId.isEmpty) {
        throw Exception('Class ID is required to update a class.');
      }
      await _firestoreService.updateClassDocument(
        classModel.classId,
        classModel.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can update classes.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating class.');
    }
  }

  Future<void> deleteClass(String classId) async {
    try {
      if (classId.isEmpty) {
        throw Exception('Class ID is required to delete a class.');
      }
      await _firestoreService.deleteClassDocument(classId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can delete classes.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting class.');
    }
  }

  Future<int> getClassCount() async {
    try {
      return await _firestoreService.getClassCount();
    } catch (_) {
      return 0;
    }
  }
}
