import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import '../constants/app_constants.dart';

/// Service ya kusimamia FCM push notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Request permission + register token + setup handlers.
  Future<void> init() async {
    try {
      // 0. Init local notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotif.initialize(initSettings);
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // 1. Request permission (iOS + Web)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Permission denied');
        return;
      }

      // 2. Get FCM token
      final token = await _fcm.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('FCM token: ${token.substring(0, 20)}...');
        await _registerToken(token);
      } else {
        debugPrint('FCM: No token available');
      }

      // 3. Listen for token refresh
      _fcm.onTokenRefresh.listen(_registerToken);

      // 4. Foreground messages (kwenye app wakati inatumika)
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 5. Notification tap (user aki-click notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await NotificationAPI.registerDeviceToken(token);
      debugPrint('FCM token registered to backend');
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }

  /// Popup ya foreground message — LOCAL NOTIFICATION (pop on screen bar).
  void _onForegroundMessage(RemoteMessage msg) {
    debugPrint('FCM foreground: ${msg.notification?.title}');

    // RING + VIBRATE
    _playNotificationAlert();

    final title = msg.notification?.title ?? 'Notification';
    final body = msg.notification?.body ?? '';
    final type = msg.data['type']?.toString() ?? '';

    _showLocalNotification(title: title, body: body, type: type);
  }

  /// Onyesha local notification — inalia + inaonekana kwenye screen bar.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_garage_main',
      'Smart Garage',
      channelDescription: 'Smart Garage notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: type,
      );
    } catch (e) {
      debugPrint('Local notif error: $e');
    }
  }

  /// User aki-click notification.
  void _onNotificationTap(RemoteMessage msg) {
    debugPrint('FCM tap: ${msg.data}');
    _handleChatNavigation(msg);
  }

  void _handleChatNavigation(RemoteMessage msg) {
    final type = msg.data['type'];
    if (type == 'chat_message') {
      debugPrint('Navigate to chat room ${msg.data['room_id']}');
      // Baadaye tutaweka navigation hapa kwa Navigator key
    }
  }

  /// Global navigator key (kwa navigation from notification).
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;


  void _playNotificationAlert() {
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        try { HapticFeedback.mediumImpact(); } catch (_) {}
      });
    } catch (_) {}
  }

  /// Clear ALL devices za user (logout safety).
  Future<void> clearAllDevices() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null || token.isEmpty) return;
      await http.post(
        Uri.parse('${AppConstants.baseUrl}notifications/devices/clear-all/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('FCM: All devices cleared for user');
    } catch (e) {
      debugPrint('FCM clear-all error: $e');
    }
  }

  /// Unregister token (kwenye logout).
  Future<void> unregister() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _fcm.deleteToken();
        debugPrint('FCM token deleted');
      }
    } catch (e) {
      debugPrint('FCM unregister error: $e');
    }
  }
}

/// Background message handler (lazima iwe top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  debugPrint('FCM background: ${msg.notification?.title}');
}
