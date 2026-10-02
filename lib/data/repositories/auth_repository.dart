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
      throw Exception('Please enter Email or User ID.');
    }
    if (password.trim().isEmpty) {
      throw Exception('Please enter your password.');
    }

    final isEmail =
        RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedInput);

    String emailToUse = trimmedInput;

    if (!isEmail) {
      final formattedUserId = trimmedInput.toUpperCase();
      final loginData = await _firestoreService.getLoginIdDocument(formattedUserId);

      if (loginData == null) {
        throw Exception('Teacher User ID $formattedUserId does not exist.');
      }

      final isActive = loginData['isActive'] as bool? ?? false;
      if (!isActive) {
        throw Exception(
            'Your account is inactive. Please contact the administrator.');
      }

      final authEmail = loginData['authEmail'] as String? ?? '';
      if (authEmail.isEmpty) {
        throw Exception(
            'No email address associated with User ID "$formattedUserId".');
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
      return UserModel.fromMap(uid, data);
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
        return 'Invalid User ID/email or password. Please check your credentials and try again.';
      case 'user-not-found':
        return 'No account found with these credentials.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address or User ID.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
