import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Signs up a student with Supabase Auth (email and password),
  /// and inserts their profile details into the 'student_profiles' table.
  Future<User?> signUpStudent({
    required String fullName,
    required String email,
    required String phoneNumber,
    required int grade,
    required String password,
  }) async {
    try {
      // 1. Sign up user in Supabase Auth
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'grade': grade,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('User registration failed: User is null.');
      }

      // 2. Insert profile data into 'student_profiles' table
      await _client.from('student_profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'grade': grade,
        'email': email,
      });

      // 3. Save local session to SharedPreferences to keep app states synchronized
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_email', email);
      await prefs.setString('user_phoneNumber', phoneNumber);
      await prefs.setString('user_grade', 'Grade $grade');
      await prefs.setBool('is_authenticated', true);

      return user;
    } catch (e) {
      debugPrint("AuthService signUpStudent Error: $e");
      rethrow;
    }
  }

  /// Logs in a student using email and password, fetches their profile,
  /// and synchronizes the session locally with SharedPreferences.
  Future<User?> loginStudent({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in with password
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('User login failed: User is null.');
      }

      // 2. Fetch extra profile information from 'student_profiles'
      final profile = await _client
          .from('student_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // 3. Save local session to SharedPreferences to match UI and existing screens
      final prefs = await SharedPreferences.getInstance();
      if (profile != null) {
        await prefs.setString('user_fullName', profile['full_name'] ?? '');
        await prefs.setString('user_email', profile['email'] ?? email);
        await prefs.setString('user_phoneNumber', profile['phone_number'] ?? '');
        await prefs.setString('user_grade', 'Grade ${profile['grade'] ?? 12}');
      } else {
        await prefs.setString('user_fullName', user.userMetadata?['full_name'] ?? 'Student');
        await prefs.setString('user_email', user.email ?? email);
        await prefs.setString('user_phoneNumber', user.userMetadata?['phone_number'] ?? '');
        await prefs.setString('user_grade', 'Grade 12');
      }
      await prefs.setBool('is_authenticated', true);

      return user;
    } catch (e) {
      debugPrint("AuthService loginStudent Error: $e");
      rethrow;
    }
  }

  /// Logs out the student and clears SharedPreferences
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint("AuthService signOut Error: $e");
    }
  }

  /// Get current session user
  User? get currentUser => _client.auth.currentUser;
}
