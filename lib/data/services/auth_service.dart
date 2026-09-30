import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth? _customFirebaseAuth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _customFirebaseAuth = firebaseAuth;

  FirebaseAuth get _firebaseAuth =>
      _customFirebaseAuth ?? FirebaseAuth.instance;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
