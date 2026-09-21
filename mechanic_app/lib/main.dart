import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'core/services/notification_router.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  // FCM Init — inafanya kazi kwenye web + mobile
  try {
    await NotificationService.instance.init();
    debugPrint('FCM init completed');
  } catch (e) {
    debugPrint('FCM init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: NotificationRouter.instance.navigatorKey,
      scaffoldMessengerKey: NotificationRouter.instance.scaffoldMessengerKey,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/chat': (context) => const ChatListScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat-screen') {
          final args = settings.arguments as Map?;
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: args?['room_id'] as int? ?? 0,
              roomName: args?['room_name']?.toString() ?? 'Chat',
            ),
          );
        }
        return null;
      },
    );
  }
}
