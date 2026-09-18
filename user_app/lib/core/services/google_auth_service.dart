import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Exception maalum ya kuepusha kuonyesha popup_closed kwa user.
class GoogleSignInCancelled implements Exception {
  final String message;
  GoogleSignInCancelled([this.message = 'Sign-in cancelled']);
  @override
  String toString() => message;
}

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google. Returns Firebase ID token or null if cancelled.
  static Future<String?> signInAndGetIdToken() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final idToken = await userCred.user?.getIdToken();
      debugPrint('Got Firebase ID token: ${idToken?.substring(0, 20)}...');
      return idToken;
    } on Exception catch (e) {
      final str = e.toString().toLowerCase();
      // Handle popup_closed kwa upole
      if (str.contains('popup_closed') ||
          str.contains('popup-closed') ||
          str.contains('cancelled') ||
          str.contains('canceled')) {
        debugPrint('Google sign-in cancelled (popup closed)');
        throw GoogleSignInCancelled('Umeghairi kuingia na Google');
      }
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
