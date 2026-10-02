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
    await _firestore.collection('students').doc(studentId).set(data, SetOptions(merge: true));
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
    await _firestore.collection('teachers').doc(teacherId).set(data, SetOptions(merge: true));
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
    await _firestore.collection('teachers').doc(teacherId).set(data, SetOptions(merge: true));
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
    await _firestore.collection('classes').doc(classId).set(data, SetOptions(merge: true));
  }

  Future<void> updateClassDocument(
      String classId, Map<String, dynamic> data) async {
    await _firestore.collection('classes').doc(classId).set(data, SetOptions(merge: true));
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
    await _firestore.collection('fee_payments').doc(paymentId).set(data, SetOptions(merge: true));
  }

  Future<void> updatePaymentDocument(String paymentId, Map<String, dynamic> data) async {
    await _firestore.collection('fee_payments').doc(paymentId).set(data, SetOptions(merge: true));
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

  // Homework Document Methods
  String generateHomeworkId() {
    return _firestore.collection('homework').doc().id;
  }

  Future<void> saveHomeworkDocument(
      String homeworkId, Map<String, dynamic> data) async {
    await _firestore
        .collection('homework')
        .doc(homeworkId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateHomeworkDocument(
      String homeworkId, Map<String, dynamic> data) async {
    await _firestore.collection('homework').doc(homeworkId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteHomeworkDocument(String homeworkId) async {
    await _firestore.collection('homework').doc(homeworkId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getAllHomeworkDocuments() async {
    final snapshot = await _firestore
        .collection('homework')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> getHomeworkDocument(String homeworkId) async {
    final doc = await _firestore.collection('homework').doc(homeworkId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Test Document Methods
  String generateTestId() {
    return _firestore.collection('tests').doc().id;
  }

  Future<void> saveTestDocument(String testId, Map<String, dynamic> data) async {
    await _firestore.collection('tests').doc(testId).set(data, SetOptions(merge: true));
  }

  Future<void> updateTestDocument(String testId, Map<String, dynamic> data) async {
    await _firestore.collection('tests').doc(testId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteTestDocument(String testId) async {
    await _firestore.collection('tests').doc(testId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllTestDocuments() async {
    final snapshot = await _firestore
        .collection('tests')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> getTestDocument(String testId) async {
    final doc = await _firestore.collection('tests').doc(testId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Mark Document Methods
  Future<void> saveMarkDocument(String markId, Map<String, dynamic> data) async {
    await _firestore.collection('marks').doc(markId).set(data, SetOptions(merge: true));
  }

  Future<void> saveMarksBatch(List<dynamic> marksList) async {
    final batch = _firestore.batch();
    for (var m in marksList) {
      final docRef = _firestore.collection('marks').doc(m.markId);
      batch.set(docRef, m.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getMarkDocumentsForTest(String testId) async {
    final snapshot = await _firestore
        .collection('marks')
        .where('testId', isEqualTo: testId)
        .get();
    return snapshot.docs;
  }

  Future<void> deleteMarkDocument(String markId) async {
    await _firestore.collection('marks').doc(markId).delete();
  }

  Future<void> deleteMarksForTest(String testId) async {
    final snapshot = await _firestore
        .collection('marks')
        .where('testId', isEqualTo: testId)
        .get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Notice Document Methods
  String generateNoticeId() {
    return _firestore.collection('notices').doc().id;
  }

  Future<void> saveNoticeDocument(String noticeId, Map<String, dynamic> data) async {
    await _firestore.collection('notices').doc(noticeId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteNoticeDocument(String noticeId) async {
    await _firestore.collection('notices').doc(noticeId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllNoticeDocuments() async {
    final snapshot = await _firestore
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> getNoticeDocument(String noticeId) async {
    final doc = await _firestore.collection('notices').doc(noticeId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // Complaint Document Methods
  String generateComplaintId() {
    return _firestore.collection('complaints').doc().id;
  }

  Future<void> saveComplaintDocument(String complaintId, Map<String, dynamic> data) async {
    await _firestore.collection('complaints').doc(complaintId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteComplaintDocument(String complaintId) async {
    await _firestore.collection('complaints').doc(complaintId).delete();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllComplaintDocuments() async {
    final snapshot = await _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> getComplaintDocument(String complaintId) async {
    final doc = await _firestore.collection('complaints').doc(complaintId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}
