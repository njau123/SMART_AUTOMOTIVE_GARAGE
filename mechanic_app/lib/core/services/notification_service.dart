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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

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
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final title = msg.notification?.title ?? 'Notification';
    final body = msg.notification?.body ?? '';
    final type = msg.data['type']?.toString() ?? '';

    IconData icon = Icons.notifications_active;
    Color color = const Color(0xFF1A73E8);
    if (type.contains('chat')) { icon = Icons.chat_bubble; color = Colors.blue; }
    else if (type.contains('payment') || type.contains('obd')) { icon = Icons.payments; color = Colors.green; }
    else if (type.contains('offline_mechanic')) { icon = Icons.person_search; color = Colors.orange; }
    else if (type.contains('ready')) { icon = Icons.handyman; color = Colors.deepOrange; }
    else if (type.contains('service') || type.contains('order')) { icon = Icons.local_shipping; color = Colors.teal; }
    else if (type.contains('alert') || type.contains('emergency')) { icon = Icons.warning; color = Colors.red; }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ]),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(body, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade800)),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Funga'))),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); _handleChatNavigation(msg); },
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                  child: const Text('Fungua'),
                )),
              ]),
            ],
          ),
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
