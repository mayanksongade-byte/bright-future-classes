import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../services/firestore_service.dart';

class AttendanceRepository {
  final FirestoreService _firestoreService;

  AttendanceRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> saveAttendanceBatch(List<AttendanceModel> attendanceList) async {
    try {
      await _firestoreService.saveAttendanceBatch(attendanceList);
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw Exception("You don't have permission to save attendance.");
        case 'unavailable':
        case 'network-request-failed':
          throw Exception(
              "Unable to connect to the server. Please check your internet connection and try again.");
        case 'failed-precondition':
          throw Exception("Attendance could not be saved. Please try again.");
        case 'already-exists':
          throw Exception(
              "Attendance already exists for this date. Your changes have been updated.");
        case 'not-found':
          throw Exception(
              "The selected attendance record could not be found. Please refresh and try again.");
        default:
          throw Exception(
              "Something went wrong while saving attendance. Please try again.");
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
          "Something went wrong while saving attendance. Please try again.");
    }
  }

  Future<List<AttendanceModel>> getAttendanceForClassAndDate(
      String classId, String date) async {
    try {
      final docs = await _firestoreService
          .getAttendanceDocumentsByClassAndDate(classId, date);
      return docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw Exception("You don't have permission to view attendance.");
        case 'unavailable':
        case 'network-request-failed':
          throw Exception(
              "Unable to connect to the server. Please check your internet connection and try again.");
        default:
          throw Exception("Unable to load attendance. Please try again.");
      }
    } catch (_) {
      throw Exception("Unable to load attendance. Please try again.");
    }
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(
      String studentId) async {
    try {
      final docs =
          await _firestoreService.getAttendanceDocumentsByStudent(studentId);
      return docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw Exception("You don't have permission to view attendance.");
        case 'unavailable':
        case 'network-request-failed':
          throw Exception(
              "Unable to connect to the server. Please check your internet connection and try again.");
        default:
          throw Exception("Unable to load attendance. Please try again.");
      }
    } catch (_) {
      throw Exception("Unable to load attendance. Please try again.");
    }
  }

  Future<List<AttendanceModel>> getAllAttendance() async {
    try {
      final docs = await _firestoreService.getAllAttendanceDocuments();
      return docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
