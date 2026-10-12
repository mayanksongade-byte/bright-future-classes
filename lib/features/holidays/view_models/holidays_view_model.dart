import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/holiday_model.dart';
import '../../../data/repositories/holiday_repository.dart';

class HolidaysViewModel extends ChangeNotifier {
  final HolidayRepository _holidayRepository;

  HolidaysViewModel({HolidayRepository? holidayRepository})
      : _holidayRepository = holidayRepository ?? HolidayRepository();

  List<HolidayModel> _holidays = [];
  List<HolidayModel> get holidays => List.unmodifiable(_holidays);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<void> loadHolidays() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _holidays = await _holidayRepository.getHolidays();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveHoliday({
    String? holidayId,
    required String title,
    required String type,
    required String startDate,
    required String endDate,
    List<String> applicableClassIds = const [],
    String note = '',
  }) async {
    if (title.trim().isEmpty) {
      _errorMessage = 'Holiday name is required.';
      notifyListeners();
      return false;
    }

    if (startDate.isEmpty) {
      _errorMessage = 'Start date is required.';
      notifyListeners();
      return false;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _errorMessage = 'Admin session not found.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = holidayId ?? _holidayRepository.generateHolidayId();
      final finalEndDate = endDate.isNotEmpty ? endDate : startDate;

      final holiday = HolidayModel(
        holidayId: id,
        title: title.trim(),
        type: type,
        startDate: startDate,
        endDate: finalEndDate,
        applicableClassIds: applicableClassIds,
        note: note.trim(),
        createdBy: currentUser.uid,
      );

      await _holidayRepository.saveHoliday(holiday);
      await loadHolidays();

      _successMessage = 'Holiday saved successfully.';
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

  Future<bool> deleteHoliday(String holidayId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _holidayRepository.deleteHoliday(holidayId);
      await loadHolidays();
      _successMessage = 'Holiday deleted successfully.';
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

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
