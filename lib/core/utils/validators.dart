class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? validatePhone(String? value, [String fieldName = 'phone number']) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(cleanPhone)) {
      return 'Please enter a valid $fieldName';
    }
    return null;
  }

  static String? validate10DigitPhone(String? value, [String fieldName = 'Phone number']) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final trimmed = value.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(trimmed)) {
      return '$fieldName must be exactly 10 digits (numbers only)';
    }
    return null;
  }

  static String? validateDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select Date of Birth';
    }
    final date = DateTime.tryParse(value.trim());
    if (date == null) {
      return 'Please select a valid date';
    }
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final birthDate = DateTime(date.year, date.month, date.day);
    if (birthDate.isAfter(todayDate)) {
      return 'Date of Birth cannot be in the future';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateEmailOrUserId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter Email or User ID';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  static String? validateTeacherPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter login password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateLoginUserId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter Login User ID';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'User ID must be at least 3 characters';
    }
    if (trimmed.length > 20) {
      return 'User ID cannot exceed 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return 'User ID can only contain letters, numbers, _ and - (no spaces)';
    }
    return null;
  }
}
