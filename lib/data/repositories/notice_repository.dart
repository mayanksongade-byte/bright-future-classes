import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../services/firestore_service.dart';

class NoticeRepository {
  final FirestoreService _firestoreService;

  NoticeRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateNoticeId() {
    return _firestoreService.generateNoticeId();
  }

  Future<void> createNotice(NoticeModel notice) async {
    try {
      await _firestoreService.saveNoticeDocument(
        notice.noticeId,
        notice.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can create notices.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving notice.');
    }
  }

  Future<List<NoticeModel>> getNotices() async {
    try {
      final docs = await _firestoreService.getAllNoticeDocuments();
      return docs
          .map((doc) => NoticeModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch notices.');
      }
      throw Exception('Failed to load notices: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading notices.');
    }
  }

  Future<NoticeModel?> getNoticeById(String noticeId) async {
    try {
      final data = await _firestoreService.getNoticeDocument(noticeId);
      if (data != null) {
        return NoticeModel.fromMap(data, noticeId);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateNotice(NoticeModel notice) async {
    try {
      if (notice.noticeId.isEmpty) {
        throw Exception('Notice ID is required to update a notice.');
      }
      await _firestoreService.saveNoticeDocument(
        notice.noticeId,
        notice.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can update notices.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating notice.');
    }
  }

  Future<void> deleteNotice(String noticeId) async {
    try {
      if (noticeId.isEmpty) {
        throw Exception('Notice ID is required to delete a notice.');
      }
      await _firestoreService.deleteNoticeDocument(noticeId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can delete notices.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting notice.');
    }
  }
}
