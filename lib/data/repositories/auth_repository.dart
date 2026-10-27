import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthRepository({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService();

  Future<UserCredential> loginWithEmailOrUserId({
    required String loginInput,
    required String password,
  }) async {
    final trimmedInput = loginInput.trim();
    if (trimmedInput.isEmpty) {
      throw Exception('Please enter Student ID, User ID or Email.');
    }
    if (password.trim().isEmpty) {
      throw Exception('Please enter your password.');
    }

    final isEmail =
        RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedInput);

    String emailToUse = trimmedInput;

    if (!isEmail) {
      final formattedUserId = trimmedInput.toUpperCase();
      Map<String, dynamic>? loginData =
          await _firestoreService.getLoginIdDocument(formattedUserId);

      if (loginData == null) {
        final userDocs =
            await _firestoreService.getUsersDocumentsByUserId(formattedUserId);
        if (userDocs.isNotEmpty) {
          final uDoc = userDocs.first.data();
          final email = uDoc['email'] as String? ?? '';
          final role = (uDoc['role'] as String? ?? 'admin').toLowerCase();
          final isActive = uDoc['isActive'] as bool? ?? true;
          if (email.isNotEmpty) {
            loginData = {
              'authEmail': email,
              'isActive': isActive,
              'role': role,
            };
          }
        }
      }

      if (loginData == null) {
        final studentDoc =
            await _firestoreService.getStudentDocument(formattedUserId);
        if (studentDoc != null) {
          final uid = studentDoc['userId'] as String? ??
              studentDoc['uid'] as String? ??
              '';
          if (uid.isNotEmpty) {
            final userDoc = await _firestoreService.getUserDocument(uid);
            if (userDoc != null) {
              final email = userDoc['email'] as String? ?? '';
              final role = (userDoc['role'] as String? ?? 'student').toLowerCase();
              final isActive = userDoc['isActive'] as bool? ?? true;
              if (email.isNotEmpty) {
                loginData = {
                  'authEmail': email,
                  'isActive': isActive,
                  'role': role,
                };
              }
            }
          }
        }
      }

      if (loginData == null) {
        throw Exception(
            'No account found for Student ID / User ID "$formattedUserId".');
      }

      final isActive = loginData['isActive'] as bool? ?? false;
      if (!isActive) {
        throw Exception(
            'Your account is inactive. Please contact the administrator.');
      }

      final authEmail = loginData['authEmail'] as String? ?? '';
      if (authEmail.isEmpty) {
        throw Exception(
            'No account associated with Student ID / User ID "$formattedUserId".');
      }

      emailToUse = authEmail;
    }

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return loginWithEmailOrUserId(loginInput: email, password: password);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final data = await _firestoreService.getUserDocument(uid);
      if (data == null) return null;

      final String rawRole = data['role'] as String? ?? '';
      String resolvedRole = rawRole.toLowerCase();
      if (resolvedRole.isEmpty) {
        if (data['teacherId'] != null && (data['teacherId'] as String).isNotEmpty) {
          resolvedRole = 'teacher';
        } else if (data['studentId'] != null && (data['studentId'] as String).isNotEmpty) {
          resolvedRole = 'student';
        } else {
          resolvedRole = 'admin';
        }
      }

      final updatedData = Map<String, dynamic>.from(data);
      updatedData['role'] = resolvedRole;

      return UserModel.fromMap(uid, updatedData);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied. Unable to access user profile.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unable to load user profile. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
        return 'Invalid credentials. Please check your Student ID / User ID and password.';
      case 'user-not-found':
        return 'No account found with these credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid Student ID, User ID or Email.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Sign-in is not enabled for this project.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
