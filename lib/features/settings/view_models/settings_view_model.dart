import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  SettingsViewModel({
    SettingsRepository? settingsRepository,
    AuthRepository? authRepository,
  })  : _settingsRepository = settingsRepository ?? SettingsRepository(),
        _authRepository = authRepository ?? AuthRepository();

  UserModel? _userProfile;
  UserModel? get userProfile => _userProfile;

  Map<String, dynamic> _instituteSettings = {
    'instituteName': 'Bright Future Classes',
    'address': '',
    'contactNumber': '',
    'email': '',
  };
  Map<String, dynamic> get instituteSettings => _instituteSettings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> loadSettingsData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _settingsRepository.getUserProfile(user.uid),
        _settingsRepository.getInstituteSettings(),
      ]);

      _userProfile = results[0] as UserModel?;
      _instituteSettings = results[1] as Map<String, dynamic>;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unable to load settings data.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({required String name, required String phone}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final cleanName = name.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Name cannot be empty.';
      notifyListeners();
      return false;
    }
    if (cleanPhone.length != 10 || int.tryParse(cleanPhone) == null) {
      _errorMessage = 'Phone number must be exactly 10 digits.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _settingsRepository.updateUserProfile(user.uid, name: cleanName, phone: cleanPhone);
      _userProfile = _userProfile?.copyWith(name: cleanName, phone: cleanPhone);
      _successMessage = 'Profile updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Unable to update profile.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInstituteSettings({
    required String instituteName,
    required String address,
    required String contactNumber,
    required String email,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final cleanName = instituteName.trim();
    final cleanAddress = address.trim();
    final cleanPhone = contactNumber.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Institute name is required.';
      notifyListeners();
      return false;
    }
    if (cleanAddress.isEmpty) {
      _errorMessage = 'Address is required.';
      notifyListeners();
      return false;
    }
    if (cleanPhone.length != 10 || int.tryParse(cleanPhone) == null) {
      _errorMessage = 'Contact number must be exactly 10 digits.';
      notifyListeners();
      return false;
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _settingsRepository.saveInstituteSettings(
        instituteName: cleanName,
        address: cleanAddress,
        contactNumber: cleanPhone,
        email: cleanEmail,
        updatedBy: user.uid,
      );

      _instituteSettings = {
        'instituteName': cleanName,
        'address': cleanAddress,
        'contactNumber': cleanPhone,
        'email': cleanEmail,
      };

      _successMessage = 'Institute information updated successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Unable to update institute information.';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (_) {}
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
