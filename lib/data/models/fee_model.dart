import 'package:cloud_firestore/cloud_firestore.dart';

class FeeModel {
  final String feeId;
  final String studentId;
  final String classId;
  final String academicYear;
  final double totalAmount;
  final double discountAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FeeModel({
    required this.feeId,
    required this.studentId,
    required this.classId,
    required this.academicYear,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  double get finalPayable =>
      (totalAmount - discountAmount).clamp(0.0, double.infinity);

  factory FeeModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = map['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      parsedUpdatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    return FeeModel(
      feeId: docId ?? map['feeId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      academicYear: map['academicYear'] as String? ?? '2026-27',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feeId': feeId,
      'studentId': studentId,
      'classId': classId,
      'academicYear': academicYear,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalPayable': finalPayable,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FeeModel copyWith({
    String? feeId,
    String? studentId,
    String? classId,
    String? academicYear,
    double? totalAmount,
    double? discountAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeeModel(
      feeId: feeId ?? this.feeId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      academicYear: academicYear ?? this.academicYear,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FeePaymentModel {
  final String paymentId;
  final String feeId;
  final String studentId;
  final String classId;
  final double amount;
  final String paymentDate; // YYYY-MM-DD
  final String paymentMethod; // Cash, UPI, Bank Transfer, Other
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FeePaymentModel({
    required this.paymentId,
    required this.feeId,
    required this.studentId,
    required this.classId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  factory FeePaymentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    }

    DateTime? parsedUpdatedAt;
    final rawUpdatedAt = map['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      parsedUpdatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is String) {
      parsedUpdatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    return FeePaymentModel(
      paymentId: docId ?? map['paymentId'] as String? ?? '',
      feeId: map['feeId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      note: map['note'] as String? ?? '',
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'feeId': feeId,
      'studentId': studentId,
      'classId': classId,
      'amount': amount,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      'note': note,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FeePaymentModel copyWith({
    String? paymentId,
    String? feeId,
    String? studentId,
    String? classId,
    double? amount,
    String? paymentDate,
    String? paymentMethod,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeePaymentModel(
      paymentId: paymentId ?? this.paymentId,
      feeId: feeId ?? this.feeId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
