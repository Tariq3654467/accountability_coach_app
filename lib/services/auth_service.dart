import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthResult {
  final bool ok;
  final String message;
  final bool needsConfirmation;
  const AuthResult(this.ok, this.message, {this.needsConfirmation = false});
}

class AuthService {
  final _offlineController = StreamController<bool>.broadcast();
  bool _offline = false;

  bool get isRemoteAvailable => SupabaseService.isReady;

  /// Local mode (no Supabase keys) counts as signed in so the app is testable.
  bool get isSignedIn =>
      !isRemoteAvailable || _offline || SupabaseService.userId != null;

  String? get userId => SupabaseService.userId;

  String? get email =>
      isRemoteAvailable ? SupabaseService.client.auth.currentUser?.email : null;
  bool get emailConfirmed => !isRemoteAvailable ||
      SupabaseService.client.auth.currentUser?.emailConfirmedAt != null;

  Stream<bool> get signedInChanges {
    if (!isRemoteAvailable) return _offlineController.stream;
    return SupabaseService.client.auth.onAuthStateChange
        .map((_) => isSignedIn)
        .asBroadcastStream();
  }

  void continueOffline() {
    _offline = true;
    _offlineController.add(true);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String phone = '',
  }) async {
    if (!isRemoteAvailable) return const AuthResult(false, 'Supabase is not configured.');
    try {
      final res = await SupabaseService.client.auth
          .signUp(
            email: email.trim().toLowerCase(),
            password: password,
            data: {
              'username': username.trim().toLowerCase(),
              'display_name': displayName.trim(),
              'phone': phone.trim(),
            },
          );
      if (res.session == null) {
        return const AuthResult(true, 'Check your email to confirm your account.',
            needsConfirmation: true);
      }
      return const AuthResult(true, 'Account created.');
    } on AuthException catch (e) {
      return AuthResult(false, e.message);
    } catch (e) {
      return AuthResult(false, 'Sign-up failed: $e');
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    if (!isRemoteAvailable) return const AuthResult(false, 'Supabase is not configured.');
    try {
      await SupabaseService.client.auth
          .signInWithPassword(email: email.trim(), password: password);
      return const AuthResult(true, 'Signed in.');
    } on AuthException catch (e) {
      return AuthResult(false, e.message);
    } catch (e) {
      return AuthResult(false, 'Sign-in failed: $e');
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    if (!isRemoteAvailable) return const AuthResult(false, 'Supabase is not configured.');
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
      return const AuthResult(true, 'Password reset email sent.');
    } on AuthException catch (e) {
      return AuthResult(false, e.message);
    } catch (e) {
      return AuthResult(false, 'Reset failed: $e');
    }
  }

  Future<void> signOut() async {
    _offline = false;
    if (isRemoteAvailable) {
      await SupabaseService.client.auth.signOut();
    } else {
      _offlineController.add(false);
    }
  }
}
