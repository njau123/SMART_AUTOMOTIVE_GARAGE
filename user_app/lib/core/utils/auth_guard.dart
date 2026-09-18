
import 'package:flutter/material.dart';
import '../../core/state/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';

class AuthGuard {
  AuthGuard._();

  static bool requireLogin(BuildContext context) {
    if (AuthState.instance.isLoggedIn) return true;
    _showLoginPrompt(context);
    return false;
  }

  static void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.blue, size: 26),
            SizedBox(width: 10),
            Text("Ingia Kwanza"),
          ],
        ),
        content: const Text(
            "Ili kuendelea na huduma hii, tafadhali ingia kwenye account yako."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Ghairi"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text("Ingia Sasa"),
          ),
        ],
      ),
    );
  }

  static void openProtected(BuildContext context, Widget screen) {
    if (requireLogin(context)) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }
}
