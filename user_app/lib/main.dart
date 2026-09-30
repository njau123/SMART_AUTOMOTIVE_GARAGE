import 'package:flutter/material.dart';
import 'core/services/web_cache_buster.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/language_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/state/auth_state.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CACHE BUSTER — futa service worker ya zamani
  await WebCacheBuster.checkAndClear();

  // FCM background handler — lazima iwe kabla ya Firebase
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // App lifecycle (haraka)
  AppLifecycleService().initialize();

  // Init zote kwa PARALLEL (haraka mara 2-3)
  await Future.wait([
    _initFirebase(),
    ThemeController.instance.init(),
    AuthState.instance.init(),
  ], eagerError: false);

  // FCM notifications — baada ya Firebase
  try {
    await NotificationService.instance.init();
    debugPrint('[FCM] NotificationService initialized');
  } catch (e) {
    debugPrint('[FCM] NotificationService init error: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const UserApp(),
    ),
  );

  // Background services — bila kusubiri
  UpdateService.init();
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(options: firebaseOptions);
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        // Watch language changes
        final langProvider = context.watch<LanguageProvider>();
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          locale: langProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.light,  // Force light (dark mode inasababisha blur)
          home: const SplashScreen(),
        );
      },
    );
  }
}
