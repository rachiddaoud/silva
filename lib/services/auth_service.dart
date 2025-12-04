import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn instance with serverClientId
      await GoogleSignIn.instance.initialize(
        serverClientId: '174370766580-h345ostpe267pl0ambdkte3jji6c8btn.apps.googleusercontent.com',
      );
      
      // Authenticate the user
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential (only idToken is available in google_sign_in 7.2.0)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final dbService = DatabaseService();
        // Create fake history if it doesn't exist (new user)
        await dbService.createFakeHistory(userCredential.user!.uid);
        // Ensure yesterday exists
        await dbService.ensureYesterdayExists(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Handle name update for new users as Apple only sends it once
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          if (appleIdCredential.givenName != null) {
            String displayName = appleIdCredential.givenName!;
            if (appleIdCredential.familyName != null) {
              displayName += ' ${appleIdCredential.familyName}';
            }
            await userCredential.user!.updateDisplayName(displayName);
            await userCredential.user!.reload();
          }
        }

        final dbService = DatabaseService();
        // Create fake history if it doesn't exist (new user)
        await dbService.createFakeHistory(userCredential.user!.uid);
        // Ensure yesterday exists
        await dbService.ensureYesterdayExists(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Track logout before signing out
      await AnalyticsService.instance.logEvent(
        name: AnalyticsEvents.logout,
      );
      
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
      
      // Clear analytics user ID
      await AnalyticsService.instance.setUserId(null);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}
