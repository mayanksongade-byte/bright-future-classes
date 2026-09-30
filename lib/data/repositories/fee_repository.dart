import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import '../services/firestore_service.dart';

class FeeRepository {
  final FirestoreService _firestoreService;

  FeeRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> saveFee(FeeModel fee) async {
    try {
      await _firestoreService.saveFeeDocument(fee.feeId, fee.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can manage fees.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving fee.');
    }
  }

  Future<FeeModel?> getFee(String feeId) async {
    try {
      final data = await _firestoreService.getFeeDocument(feeId);
      if (data == null) return null;
      return FeeModel.fromMap(data, feeId);
    } catch (_) {
      return null;
    }
  }

  Future<List<FeeModel>> getAllFees() async {
    try {
      final docs = await _firestoreService.getAllFeesDocuments();
      return docs
          .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String generatePaymentId() {
    return _firestoreService.generatePaymentId();
  }

  Future<void> savePayment(FeePaymentModel payment) async {
    try {
      await _firestoreService.savePaymentDocument(payment.paymentId, payment.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can manage payments.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving payment.');
    }
  }

  Future<void> updatePayment(FeePaymentModel payment) async {
    try {
      await _firestoreService.updatePaymentDocument(payment.paymentId, payment.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can manage payments.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating payment.');
    }
  }

  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestoreService.deletePaymentDocument(paymentId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Only active admins can manage payments.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting payment.');
    }
  }

  Future<List<FeePaymentModel>> getPaymentsForFee(String feeId) async {
    try {
      final docs = await _firestoreService.getPaymentDocumentsForFee(feeId);
      return docs
          .map((doc) => FeePaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<FeePaymentModel>> getAllPayments() async {
    try {
      final docs = await _firestoreService.getAllPaymentDocuments();
      return docs
          .map((doc) => FeePaymentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
