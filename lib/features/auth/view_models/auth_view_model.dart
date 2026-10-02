import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserCredential? _userCredential;
  UserCredential? get userCredential => _userCredential;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  Future<bool> loginWithEmail(String emailOrUserId, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _userModel = null;
    notifyListeners();

    try {
      _userCredential = await _authRepository.loginWithEmailOrUserId(
        loginInput: emailOrUserId.trim(),
        password: password.trim(),
      );

      final uid = _userCredential?.user?.uid;
      if (uid == null || uid.isEmpty) {
        _errorMessage = 'Authentication failed. Invalid user session.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userProfile = await _authRepository.getUserProfile(uid);

      if (userProfile == null) {
        _errorMessage =
            'User profile not found. Please contact the administrator.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!userProfile.isActive) {
        _errorMessage =
            'Your account is inactive. Please contact the administrator.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userModel = userProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
