import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore? _customFirestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  // User Document Methods
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }

  // Student Document Methods
  Future<void> saveStudentDocument(
      String studentId, Map<String, dynamic> data) async {
    await _firestore.collection('students').doc(studentId).set(data);
  }

  Future<bool> checkStudentExists(String studentId) async {
    final docSnapshot =
        await _firestore.collection('students').doc(studentId).get();
    return docSnapshot.exists;
  }

  Future<int> getStudentCount() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs.length;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getStudentsDocuments() async {
    final snapshot = await _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<void> deleteStudentDocument(String studentId) async {
    await _firestore.collection('students').doc(studentId).delete();
  }

  // Teacher Document Methods
  String generateTeacherId() {
    return _firestore.collection('teachers').doc().id;
  }

  Future<void> saveTeacherDocument(
      String teacherId, Map<String, dynamic> data) async {
    await _firestore.collection('teachers').doc(teacherId).set(data);
  }

  Future<int> getTeacherCount() async {
    final snapshot = await _firestore.collection('teachers').get();
    return snapshot.docs.length;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getTeachersDocuments() async {
    final snapshot = await _firestore
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<void> updateTeacherDocument(
      String teacherId, Map<String, dynamic> data) async {
    await _firestore.collection('teachers').doc(teacherId).update(data);
  }

  Future<void> deleteTeacherDocument(String teacherId) async {
    await _firestore.collection('teachers').doc(teacherId).delete();
  }

  // Class Document Methods
  String generateClassId() {
    return _firestore.collection('classes').doc().id;
  }

  Future<void> saveClassDocument(
      String classId, Map<String, dynamic> data) async {
    await _firestore.collection('classes').doc(classId).set(data);
  }

  Future<void> updateClassDocument(
      String classId, Map<String, dynamic> data) async {
    await _firestore.collection('classes').doc(classId).update(data);
  }

  Future<void> deleteClassDocument(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getClassesDocuments() async {
    final snapshot = await _firestore
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamClassesDocuments() {
    return _firestore
        .collection('classes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<int> getClassCount() async {
    final snapshot = await _firestore.collection('classes').get();
    return snapshot.docs.length;
  }

  // Attendance Document Methods
  Future<void> saveAttendanceDocument(
      String attendanceId, Map<String, dynamic> data) async {
    await _firestore
        .collection('attendance')
        .doc(attendanceId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> saveAttendanceBatch(List<dynamic> attendanceList) async {
    final batch = _firestore.batch();
    for (var att in attendanceList) {
      final docRef = _firestore.collection('attendance').doc(att.attendanceId);
      batch.set(docRef, att.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAttendanceDocumentsByClassAndDate(
      String classId, String date) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAttendanceDocumentsByStudent(
      String studentId) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllAttendanceDocuments() async {
    final snapshot = await _firestore.collection('attendance').get();
    return snapshot.docs;
  }

  // Fee Document Methods
  Future<void> saveFeeDocument(String feeId, Map<String, dynamic> data) async {
    await _firestore.collection('fees').doc(feeId).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getFeeDocument(String feeId) async {
    final docSnapshot = await _firestore.collection('fees').doc(feeId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllFeesDocuments() async {
    final snapshot = await _firestore.collection('fees').get();
    return snapshot.docs;
  }

  String generatePaymentId() {
    return _firestore.collection('fee_payments').doc().id;
  }

  Future<void> savePaymentDocument(String paymentId, Map<String, dynamic> data) async {
    await _firestore.collection('fee_payments').doc(paymentId).set(data);
  }

  Future<void> updatePaymentDocument(String paymentId, Map<String, dynamic> data) async {
    await _firestore.collection('fee_payments').doc(paymentId).update(data);
  }

  Future<void> deletePaymentDocument(String paymentId) async {
    await _firestore.collection('fee_payments').doc(paymentId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getPaymentDocumentsForFee(String feeId) async {
    final snapshot = await _firestore
        .collection('fee_payments')
        .where('feeId', isEqualTo: feeId)
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllPaymentDocuments() async {
    final snapshot = await _firestore.collection('fee_payments').get();
    return snapshot.docs;
  }
}
