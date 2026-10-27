import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/student_model.dart';
import '../services/firestore_service.dart';

class StudentRepository {
  final FirestoreService _firestoreService;

  StudentRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<void> createStudent(StudentModel student) async {
    try {
      final exists = await _firestoreService.checkStudentExists(
        student.studentId,
      );
      if (exists) {
        throw Exception(
          'Student ID "${student.studentId}" already exists. Please use a unique ID.',
        );
      }
      await _firestoreService.saveStudentDocument(
        student.studentId,
        student.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Only active admins can create student records.',
        );
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving student.');
    }
  }

  Future<String> createStudentAccountWithAuth({
    required StudentModel student,
    required String password,
    String email = '',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      try {
        secondaryApp = Firebase.app('SecondaryStudentApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryStudentApp',
          options: Firebase.app().options,
        );
      }

      final studentIdUpper = student.studentId.trim().toUpperCase();
      final authEmail = email.trim().isNotEmpty
          ? email.trim()
          : '${studentIdUpper.toLowerCase()}@student.brightfuture.local';

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password.trim(),
      );

      final user = cred.user!;
      final uid = user.uid;

      if (email.trim().isNotEmpty) {
        try {
          await user.sendEmailVerification();
        } catch (_) {}
      }

      await _firestoreService.saveUserDocument(uid, {
        'uid': uid,
        'email': authEmail,
        'role': 'student',
        'studentId': student.studentId,
        'name': student.name,
        'isActive': true,
        'isEmailVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestoreService.saveLoginIdDocument(studentIdUpper, {
        'userId': studentIdUpper,
        'authEmail': authEmail,
        'role': 'student',
        'isActive': true,
        'studentId': student.studentId,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final updatedStudent = student.copyWith(userId: uid);
      await _firestoreService.saveStudentDocument(
        student.studentId,
        updatedStudent.toMap(),
      );

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Student ID "$student.studentId" is already registered.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid student authentication identity.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      }
      throw Exception('Authentication error: ${e.message}');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Only active admins can create student accounts.',
        );
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while creating student account.');
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    try {
      if (student.studentId.isEmpty) {
        throw Exception('Student ID is required to update a student.');
      }
      await _firestoreService.saveStudentDocument(
        student.studentId,
        student.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Only active admins can update student records.',
        );
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating student.');
    }
  }

  Future<List<StudentModel>> getStudents() async {
    try {
      final docs = await _firestoreService.getStudentsDocuments();
      return docs
          .map((doc) => StudentModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch students.');
      }
      throw Exception('Failed to load students: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading students.');
    }
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      final data = await _firestoreService.getStudentDocument(studentId);
      if (data == null) return null;
      return StudentModel.fromMap(data, studentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      if (studentId.isEmpty) {
        throw Exception('Student ID is required to delete a student.');
      }
      await _firestoreService.deleteStudentDocument(studentId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Only active admins can delete students.',
        );
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting student.');
    }
  }

  Future<int> getStudentCount() async {
    try {
      return await _firestoreService.getStudentCount();
    } catch (_) {
      return 0;
    }
  }

  Future<void> resetStudentPassword({
    required String studentId,
    required String newPassword,
    required String adminUid,
  }) async {
    final cleanPassword = newPassword.trim();
    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final formattedStudentId = studentId.trim().toUpperCase();
    Map<String, dynamic>? loginData =
        await _firestoreService.getLoginIdDocument(formattedStudentId);

    String authEmail = loginData?['authEmail'] as String? ?? '';
    String targetUid = loginData?['uid'] as String? ?? '';

    if (authEmail.isEmpty) {
      final studentDoc = await _firestoreService.getStudentDocument(studentId);
      if (studentDoc != null) {
        final uid = studentDoc['userId'] as String? ??
            studentDoc['uid'] as String? ??
            studentId;
        final userDoc = await _firestoreService.getUserDocument(uid);
        if (userDoc != null) {
          authEmail = userDoc['email'] as String? ?? '';
          targetUid = uid;
        }
      }
    }

    if (authEmail.isEmpty) {
      authEmail = '${formattedStudentId.toLowerCase()}@student.brightfuture.local';
    }

    if (authEmail.contains('@') &&
        !authEmail.endsWith('@student.brightfuture.local') &&
        !authEmail.endsWith('@brightfutureclasses.app')) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: authEmail);
      } catch (_) {}
    }

    await _firestoreService.savePasswordResetAudit({
      'adminUid': adminUid,
      'targetId': studentId,
      'targetRole': 'student',
      'targetUid': targetUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
