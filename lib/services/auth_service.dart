// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService().client;
  
  // Add a secret code that only you know
  static const String _secretCode = 'Ss@12345'; // Change this to your secret code

  // Sign In
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // Get user details from database
        final userData = await _supabase
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign Up with secret code
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String storeName,
    required String secretCode, 
  }) async {
    // Verify secret code
    if (secretCode != _secretCode) {
      throw Exception('Invalid secret code. Registration is restricted.');
    }

    try {
      // Validate email format
      if (!email.contains('@') || !email.contains('.')) {
        throw Exception('Please enter a valid email address');
      }

      // Create auth user
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        // Create user profile in database
        final newUser = UserModel(
          id: response.user!.id,
          email: email.trim(),
          fullName: fullName,
          storeName: storeName,
          storeId: response.user!.id,
          role: 'owner',
          createdAt: DateTime.now(),
        );

        await _supabase.from('users').insert(newUser.toJson());
        return newUser;
      }
      return null;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get Current User
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get current user details
  Future<UserModel?> getCurrentUserDetails() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}