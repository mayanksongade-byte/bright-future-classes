import 'package:flutter/material.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/auth/screens/login_screen.dart';

class AppRouter {
  static const String login = '/login';
  static const String adminDashboard = '/admin_dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
