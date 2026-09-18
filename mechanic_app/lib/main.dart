import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: weka try/catch
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // FCM: mobile pekee, na kwa try/catch
  if (!kIsWeb) {
    try {
      // Import kwa dynamic ili web isi-crash
      // Hii inatumia firebase_messaging tu kwenye mobile
      final fcm = _initFcm();  // fire-and-forget
      debugPrint('FCM init started');
      // ignore: unawaited_futures
      fcm;
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  runApp(const MyApp());
}

Future<void> _initFcm() async {
  // Hii haitafanya kitu kwenye web (tunaiacha)
  // Kwenye mobile, firebase_messaging itakuwa available
  debugPrint('FCM would initialize here on mobile');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/chat': (context) => const ChatListScreen(),
      },
    );
  }
}
