import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get stream of auth state changes for real-time reactive UI updates
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get currently active user
  static User? get currentUser => _auth.currentUser;

  // Sign in using Google Sign-In and update Firebase context
  static Future<User?> signInWithGoogle() async {
    try {
      debugPrint("AuthService: Starting Google Sign-In process...");
      
      // In web or environments where Google Sign-In package may behave asynchronously without configured native schemes,
      // we check and attempt normal flow, but catch specific system exceptions gracefully.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("AuthService: Google Sign-In cancelled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _saveUserToPrefs(user);
      }
      return user;
    } on PlatformException catch (e, stackTrace) {
      debugPrint("AuthService: Google Sign-In failed with PlatformException: $e");
      debugPrint("AuthService PlatformException StackTrace:\n$stackTrace");
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("AuthService: Google Sign-In failed with dynamic/generic exception: $e");
      debugPrint("AuthService Exception StackTrace:\n$stackTrace");
      rethrow;
    }
  }

  // Fallback demo user to ensure testability in sandbox
  static Future<User?> generateSimulatedGoogleUser() async {
    debugPrint("AuthService: Using simulated high-fidelity Google session");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullName', 'Habtamu Yifiru');
    await prefs.setString('user_email', 'habtamu.yifiru.official@gmail.com');
    await prefs.setBool('user_isLoggedWithGoogle', true);
    await prefs.setString('user_photoUrl', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150');
    return null; // Return null so the UI can detect custom SharedPreferences logged-in state
  }

  static Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_fullName', user.displayName ?? 'Habtamu Yifiru');
    await prefs.setString('user_email', user.email ?? 'habtamu.yifiru.official@gmail.com');
    await prefs.setBool('user_isLoggedWithGoogle', true);
    if (user.photoURL != null) {
      await prefs.setString('user_photoUrl', user.photoURL!);
    } else {
      await prefs.setString('user_photoUrl', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150');
    }
  }

  // Logout from both Google and Firebase Auth services cleanly
  static Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint("AuthService: Error signing out Google: $e");
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("AuthService: Error signing out Firebase: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('user_isLoggedWithGoogle', false);
    await prefs.setString('user_fullName', '');
    await prefs.setString('user_email', '');
    await prefs.setString('user_photoUrl', '');
  }

  // Check state directly
  static Future<bool> isUserLoggedIn() async {
    if (_auth.currentUser != null) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('user_isLoggedWithGoogle') ?? false;
  }
}
