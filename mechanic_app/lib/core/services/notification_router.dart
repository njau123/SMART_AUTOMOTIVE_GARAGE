import 'package:flutter/material.dart';

/// Global router kwa navigation from notifications.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  /// Global navigator key — weka kwenye MaterialApp.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Global scaffold messenger key — kwa snackbars.
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Navigate to chat screen.
  void openChatRoom(int roomId, String roomName) {
    navigatorKey.currentState?.pushNamed(
      '/chat-screen',
      arguments: {'room_id': roomId, 'room_name': roomName},
    );
  }

  /// Navigate to chat list.
  void openChatList() {
    navigatorKey.currentState?.pushNamed('/chat');
  }
}
