import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';

class TeacherPasswordResetClient {
  final http.Client _httpClient;
  final String _baseUrl;

  TeacherPasswordResetClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.backendBaseUrl).replaceAll(RegExp(r'/+$'), '');

  /// Calls the secure external Node.js backend to update the password of an existing teacher account.
  ///
  /// Flow:
  /// 1. Obtains current Admin's Firebase ID token using [adminUser.getIdToken()].
  /// 2. Sends HTTP POST to [backendBaseUrl]/api/teachers/reset-password with Bearer token header.
  /// 3. Validates backend response.
  /// 4. Does NOT create a new account or change the teacher's UID.
  Future<Map<String, dynamic>> resetTeacherPassword({
    required String teacherId,
    required String newPassword,
    required User adminUser,
  }) async {
    final cleanTeacherId = teacherId.trim().toUpperCase();
    final cleanPassword = newPassword.trim();

    if (cleanTeacherId.isEmpty) {
      throw Exception('Teacher ID cannot be empty.');
    }
    if (cleanPassword.length < 8) {
      throw Exception('Password must be at least 8 characters long.');
    }

    // 1. Get current Admin's Firebase ID token
    final String? idToken = await adminUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Authentication session expired. Please sign in again.');
    }

    // 2. Prepare HTTP request
    final uri = Uri.parse('$_baseUrl/api/teachers/reset-password');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    };
    final body = jsonEncode({
      'teacherId': cleanTeacherId,
      'newPassword': cleanPassword,
    });

    debugPrint('[TeacherPasswordResetClient] Requesting password reset for teacher $cleanTeacherId from $_baseUrl');

    // 3. Dispatch POST request
    final http.Response response;
    try {
      response = await _httpClient
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('[TeacherPasswordResetClient] Network error: $e');
      throw Exception(
        'Unable to reach password reset server at $_baseUrl. Please check your internet connection and server status.',
      );
    }

    // 4. Handle response
    Map<String, dynamic> responseData = {};
    try {
      if (response.body.isNotEmpty) {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Non-JSON response
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final success = responseData['success'] as bool? ?? false;
      if (!success) {
        final msg = responseData['message'] as String? ?? 'Operation failed without confirmation.';
        throw Exception(msg);
      }
      debugPrint('[TeacherPasswordResetClient] Successfully reset password for teacher $cleanTeacherId');
      return responseData;
    } else {
      final errorMsg = responseData['message'] as String? ??
          'Password reset failed (HTTP ${response.statusCode}).';
      debugPrint('[TeacherPasswordResetClient] Server error (${response.statusCode}): $errorMsg');
      throw Exception(errorMsg);
    }
  }
}
