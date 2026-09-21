import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'notification_router.dart';

/// Service ya kusimamia FCM push notifications.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;

  /// Request permission + register token + setup handlers.
  Future<void> init() async {
    try {
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

  /// Popup ya foreground message.
  void _onForegroundMessage(RemoteMessage msg) {
    debugPrint('FCM foreground: ${msg.notification?.title}');

    final title = msg.notification?.title ?? 'Notification';
    final body = msg.notification?.body ?? '';

    NotificationRouter.instance.scaffoldMessengerKey.currentState
        ?.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Fungua',
          onPressed: () => _handleChatNavigation(msg),
        ),
      ),
    );
  }

  /// User aki-click notification.
  void _onNotificationTap(RemoteMessage msg) {
    debugPrint('FCM tap: ${msg.data}');
    _handleChatNavigation(msg);
  }

  void _handleChatNavigation(RemoteMessage msg) {
    final type = msg.data['type'];
    final roomIdStr = msg.data['room_id']?.toString();

    debugPrint('FCM nav: type=$type room=$roomIdStr');

    if (type == 'chat_message' && roomIdStr != null && roomIdStr.isNotEmpty) {
      final roomId = int.tryParse(roomIdStr);
      if (roomId != null && roomId > 0) {
        NotificationRouter.instance.openChatRoom(
          roomId,
          msg.notification?.title ?? 'Chat',
        );
      }
    } else if (type == 'chat_message') {
      // Kama room_id haipo — fungua chat list
      NotificationRouter.instance.openChatList();
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
