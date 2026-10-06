import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../services/firestore_service.dart';

class ComplaintRepository {
  final FirestoreService _firestoreService;

  ComplaintRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateComplaintId() {
    return _firestoreService.generateComplaintId();
  }

  Future<void> createComplaint(ComplaintModel complaint) async {
    try {
      await _firestoreService.saveComplaintDocument(
        complaint.complaintId,
        complaint.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can create complaints.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving complaint.');
    }
  }

  Future<List<ComplaintModel>> getComplaints() async {
    try {
      final docs = await _firestoreService.getAllComplaintDocuments();
      return docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch complaints.');
      }
      throw Exception('Failed to load complaints: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading complaints.');
    }
  }

  Future<List<ComplaintModel>> getComplaintsForStudent(String studentId) async {
    try {
      final docs = await _firestoreService.getComplaintDocumentsForStudent(studentId);
      return docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ComplaintModel?> getComplaintById(String complaintId) async {
    try {
      final data = await _firestoreService.getComplaintDocument(complaintId);
      if (data != null) {
        return ComplaintModel.fromMap(data, complaintId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateComplaint(ComplaintModel complaint) async {
    try {
      if (complaint.complaintId.isEmpty) {
        throw Exception('Complaint ID is required to update a complaint.');
      }
      await _firestoreService.saveComplaintDocument(
        complaint.complaintId,
        complaint.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can update complaints.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating complaint.');
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    try {
      if (complaintId.isEmpty) {
        throw Exception('Complaint ID is required to delete a complaint.');
      }
      await _firestoreService.deleteComplaintDocument(complaintId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can delete complaints.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting complaint.');
    }
  }
}
