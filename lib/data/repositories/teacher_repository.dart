import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/teacher_model.dart';
import '../services/firestore_service.dart';

class TeacherRepository {
  final FirestoreService _firestoreService;

  TeacherRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String generateTeacherId() {
    return _firestoreService.generateTeacherId();
  }

  Future<void> createTeacher({
    required TeacherModel teacher,
    required String loginUserId,
    required String password,
  }) async {
    final formattedUserId = loginUserId.trim().toUpperCase();
    final internalAuthEmail =
        "${formattedUserId.toLowerCase()}@brightfutureclasses.app";

    // 1. Check if login_ids/{formattedUserId} mapping already exists
    final existingLoginIdDoc =
        await _firestoreService.getLoginIdDocument(formattedUserId);
    if (existingLoginIdDoc != null) {
      throw Exception(
          'Teacher User ID $formattedUserId already exists. Please choose another User ID.');
    }

    // 2. Inspect if an existing teacher/user document with userId == formattedUserId exists
    Map<String, dynamic>? existingUser;
    try {
      existingUser = await _firestoreService.getUserByUserId(formattedUserId);
    } catch (_) {}

    if (existingUser != null) {
      final existingUid = existingUser['uid'] as String? ?? '';
      final existingEmail = (existingUser['email'] as String? ?? '').isNotEmpty
          ? existingUser['email'] as String
          : internalAuthEmail;

      // Create/fix login_ids/TCH001 mapping for this existing teacher
      final loginMappingData = {
        'userId': formattedUserId,
        'authEmail': existingEmail,
        'role': 'teacher',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _firestoreService.saveLoginIdDocument(
          formattedUserId, loginMappingData);

      // Ensure users/{existingUid} and teachers/{teacher.teacherId} contain userId = formattedUserId
      if (existingUid.isNotEmpty) {
        await _firestoreService.updateUserProfileDocument(existingUid, {
          'userId': formattedUserId,
          'isActive': true,
          'role': 'teacher',
        });
      }
      final teacherWithUserId = teacher.copyWith(userId: formattedUserId);
      await _firestoreService.saveTeacherDocument(
        teacherWithUserId.teacherId,
        teacherWithUserId.toMap(),
      );
      return;
    }

    // 3. Create Firebase Auth user on secondary app instance so Admin remains logged in
    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;
    String? createdAuthUid;
    String authEmailUsed = internalAuthEmail;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryTeacherApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      UserCredential? userCredential;
      try {
        userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: internalAuthEmail,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If internal email is already in use, try teacher's entered email
          try {
            userCredential = await secondaryAuth.createUserWithEmailAndPassword(
              email: teacher.email.trim(),
              password: password,
            );
            authEmailUsed = teacher.email.trim();
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      createdAuthUid = userCredential.user?.uid;
      if (createdAuthUid == null || createdAuthUid.isEmpty) {
        throw Exception('Failed to create authentication account.');
      }

      // 4. Create users/{authUid}
      final userDocData = {
        'uid': createdAuthUid,
        'userId': formattedUserId,
        'name': teacher.name,
        'email': teacher.email.trim(),
        'role': 'teacher',
        'isActive': true,
        'phone': teacher.phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 5. Create login_ids/{formattedUserId}
      final loginMappingData = {
        'userId': formattedUserId,
        'authEmail': authEmailUsed,
        'role': 'teacher',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        await _firestoreService.saveUserDocument(createdAuthUid, userDocData);
        await _firestoreService.saveLoginIdDocument(
            formattedUserId, loginMappingData);

        // 6. Create teachers/{teacherId}
        final teacherWithUserId = teacher.copyWith(userId: formattedUserId);
        await _firestoreService.saveTeacherDocument(
          teacherWithUserId.teacherId,
          teacherWithUserId.toMap(),
        );
      } catch (firestoreError) {
        // Rollback / cleanup auth user if Firestore creation failed
        try {
          await secondaryAuth.currentUser?.delete();
        } catch (_) {}
        if (firestoreError is FirebaseException) {
          if (firestoreError.code == 'permission-denied') {
            throw Exception(
                'Permission denied. Only active admins can create teacher records.');
          }
          throw Exception('Database error (${firestoreError.code}): ${firestoreError.message}');
        }
        throw Exception('Failed to save teacher record: ${firestoreError.toString()}');
      }

      // Cleanup secondary auth/app
      try {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      } catch (_) {}

    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while saving teacher: ${e.toString()}');
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This User ID/Email is already registered. Please choose another User ID or Email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password is too weak. Please choose a password with at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<List<TeacherModel>> getTeachers() async {
    try {
      final docs = await _firestoreService.getTeachersDocuments();
      return docs
          .map((doc) => TeacherModel.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to fetch teachers.');
      }
      throw Exception('Failed to load teachers: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while loading teachers.');
    }
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    try {
      if (teacher.teacherId.isEmpty) {
        throw Exception('Teacher ID is required to update a teacher.');
      }
      await _firestoreService.updateTeacherDocument(
        teacher.teacherId,
        teacher.toMap(),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can update teachers.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while updating teacher.');
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      if (teacherId.isEmpty) {
        throw Exception('Teacher ID is required to delete a teacher.');
      }
      await _firestoreService.deleteTeacherDocument(teacherId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
            'Permission denied. Only active admins can delete teachers.');
      }
      throw Exception('Database error (${e.code}): ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred while deleting teacher.');
    }
  }

  Future<int> getTeacherCount() async {
    try {
      return await _firestoreService.getTeacherCount();
    } catch (_) {
      return 0;
    }
  }
}
