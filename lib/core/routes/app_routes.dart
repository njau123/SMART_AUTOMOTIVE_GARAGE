import 'package:flutter/material.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return _fade(const LoginScreen());
      case '/signup':
        return _fade(const RegisterScreen());
      case '/forgot-password':
        return _fade(const ForgotPasswordScreen());
      case '/home':
        return _fade(const DashboardScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRouteBuilder _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (c, a, sa) => page,
      transitionsBuilder: (c, a, sa, child) => FadeTransition(opacity: a, child: child),
    );
  }
}
