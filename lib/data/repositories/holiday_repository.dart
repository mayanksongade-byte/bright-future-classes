import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/holiday_model.dart';
import '../services/firestore_service.dart';

class HolidayRepository {
  final FirestoreService _firestoreService;

  HolidayRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateHolidayId() {
    return _firestoreService.generateHolidayId();
  }

  Future<void> saveHoliday(HolidayModel holiday) async {
    try {
      await _firestoreService.saveHolidayDocument(
        holiday.holidayId,
        holiday.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can manage holidays.');
      }
      throw Exception('Failed to save holiday: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving holiday.');
    }
  }

  Future<List<HolidayModel>> getHolidays() async {
    try {
      final docs = await _firestoreService.getHolidaysDocuments();
      final list = docs
          .map((doc) => HolidayModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    } catch (_) {
      return [];
    }
  }

  Stream<List<HolidayModel>> streamHolidays() {
    return _firestoreService.streamHolidaysDocuments().map((docs) {
      final list = docs
          .map((doc) => HolidayModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Future<void> deleteHoliday(String holidayId) async {
    try {
      await _firestoreService.deleteHolidayDocument(holidayId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can delete holidays.');
      }
      throw Exception('Failed to delete holiday: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting holiday.');
    }
  }
}
