import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth) {
    _sub = _auth.signedInChanges.listen(
      (_) => notifyListeners(),
      onError: (_) {},
    );
  }

  final AuthService _auth;
  StreamSubscription<bool>? _sub;
  bool _busy = false;

  bool get isBusy => _busy;
  bool get isSignedIn => _auth.isSignedIn;
  bool get isRemoteAvailable => _auth.isRemoteAvailable;
  String? get userId => _auth.userId;
  String? get email => _auth.email;
  bool get emailConfirmed => _auth.emailConfirmed;

  Future<AuthResult> _run(Future<AuthResult> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signIn(String email, String password) =>
      _run(() => _auth.signIn(email, password));

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String phone = '',
  }) =>
      _run(() => _auth.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
        phone: phone,
      ));

  Future<AuthResult> resetPassword(String email) =>
      _run(() => _auth.resetPassword(email));

  /// Lets people try the app without an account (data stays on this device).
  void continueOffline() {
    _auth.continueOffline();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
