import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
      if (kIsWeb) {
        return await _signInWeb();
      }
      return await _signInMobile();
    } on FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('popup-closed') ||
          code.contains('cancelled') ||
          code.contains('canceled')) {
        throw GoogleSignInCancelled('Umeghairi kuingia na Google');
      }
      debugPrint('Firebase auth error: ${e.code} - ${e.message}');
      throw Exception(e.message ?? 'Google sign-in imeshindikana');
    } on Exception catch (e) {
      final str = e.toString().toLowerCase();
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

  /// WEB: Firebase popup — HAKUNA origin_mismatch, inatumia firebaseapp.com
  static Future<String?> _signInWeb() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});

    final userCred = await FirebaseAuth.instance.signInWithPopup(provider);
    final idToken = await userCred.user?.getIdToken();
    if (idToken == null) {
      throw Exception('Firebase ID token haipo');
    }
    debugPrint('Web: Firebase ID token (${idToken.substring(0, 20)}...)');
    return idToken;
  }

  /// MOBILE: google_sign_in flow (kama ilivyokuwa)
  static Future<String?> _signInMobile() async {
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
    debugPrint('Mobile: Firebase ID token (${idToken?.substring(0, 20)}...)');
    return idToken;
  }

  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
