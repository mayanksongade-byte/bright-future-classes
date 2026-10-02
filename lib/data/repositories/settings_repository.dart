import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class SettingsRepository {
  final FirestoreService _firestoreService;

  SettingsRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final data = await _firestoreService.getUserDocument(uid);
      if (data == null) return null;
      return UserModel.fromMap(uid, data);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to access user profile.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (_) {
      throw Exception('Unable to load user profile.');
    }
  }

  Future<void> updateUserProfile(String uid, {required String name, required String phone}) async {
    try {
      await _firestoreService.updateUserProfileDocument(uid, {
        'name': name.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can update profile.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (_) {
      throw Exception('Unable to update profile.');
    }
  }

  Future<Map<String, dynamic>> getInstituteSettings() async {
    try {
      final data = await _firestoreService.getInstituteSettingsDocument();
      if (data != null) {
        return data;
      }
      return {
        'instituteName': 'Bright Future Classes',
        'address': '',
        'contactNumber': '',
        'email': '',
      };
    } catch (_) {
      return {
        'instituteName': 'Bright Future Classes',
        'address': '',
        'contactNumber': '',
        'email': '',
      };
    }
  }

  Future<void> saveInstituteSettings({
    required String instituteName,
    required String address,
    required String contactNumber,
    required String email,
    required String updatedBy,
  }) async {
    try {
      await _firestoreService.saveInstituteSettingsDocument({
        'instituteName': instituteName.trim(),
        'address': address.trim(),
        'contactNumber': contactNumber.trim(),
        'email': email.trim().toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only admins can update institute settings.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (_) {
      throw Exception('Unable to save institute settings.');
    }
  }
}
