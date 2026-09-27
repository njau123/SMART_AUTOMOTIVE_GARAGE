import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/state/auth_state.dart';
import 'core/services/notification_service.dart';
import 'features/auth/screens/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminAuthState.instance.init();

  // FCM
  try {
    await NotificationService.instance.init();
    debugPrint('[FCM] admin NotificationService initialized');
  } catch (e) {
    debugPrint('[FCM] admin init error: $e');
  }
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AdminLoginScreen(),
    );
  }
}
