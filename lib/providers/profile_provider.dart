import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/profile_repository.dart';
import '../services/sms_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ProfileRepository repository, required SmsService sms})
      : _repo = repository,
        _sms = sms;

  final ProfileRepository _repo;
  final SmsService _sms;

  UserProfile _profile = const UserProfile();
  bool _hasLoaded = false;
  String? _userId;

  UserProfile get profile => _profile;
  String get greetingName => _profile.greetingName;
  String get initials => _profile.initials;
  bool get hasPhone => _sms.isValidPhone(_profile.phone);

  /// Called from the proxy provider whenever auth changes. Safe to call during build.
  void syncUser({required bool signedIn, String? userId}) {
    if (!signedIn) {
      if (_hasLoaded) {
        Future.microtask(() {
          _hasLoaded = false;
          _userId = null;
          _profile = const UserProfile();
          notifyListeners();
        });
      }
      return;
    }
    if (!_hasLoaded || userId != _userId) {
      _userId = userId;
      _hasLoaded = true;
      Future.microtask(load);
    }
  }

  Future<void> load() async {
    _profile = await _repo.fetch();
    notifyListeners();
  }

  Future<void> saveDisplayName(String name) async {
    _profile = _profile.copyWith(displayName: name.trim());
    notifyListeners();
    await _repo.save(_profile);
  }

  Future<String?> saveAccountProfile({
    required String username,
    required String displayName,
    required String phone,
  }) async {
    final normalized = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(normalized)) {
      return 'Username must be 3–24 characters using letters, numbers, or underscores.';
    }
    final cleanPhone = phone.trim();
    if (cleanPhone.isNotEmpty && !_sms.isValidPhone(cleanPhone)) {
      return 'Enter a phone number like +923001234567.';
    }
    _profile = UserProfile(
      username: normalized,
      displayName: displayName.trim(),
      phone: cleanPhone.isEmpty ? null : cleanPhone,
      fcmToken: _profile.fcmToken,
    );
    notifyListeners();
    await _repo.save(_profile);
    return null;
  }

  /// Returns an error message, or null on success. An empty string clears the number.
  Future<String?> savePhone(String phone) async {
    final clean = phone.trim();
    if (clean.isNotEmpty && !_sms.isValidPhone(clean)) {
      return 'Enter a phone number like +923001234567.';
    }
    _profile = UserProfile(
      displayName: _profile.displayName,
      phone: clean.isEmpty ? null : clean,
      fcmToken: _profile.fcmToken,
      username: _profile.username,
    );
    notifyListeners();
    await _repo.save(_profile);
    return null;
  }

  Future<void> updateFcmToken(String token) async {
    if (token.isEmpty || token == _profile.fcmToken) return;
    _profile = _profile.copyWith(fcmToken: token);
    notifyListeners();
    await _repo.save(_profile);
  }

  Future<SmsResult> sendSmsReminder(String message) =>
      _sms.sendReminder(phone: _profile.phone, message: message);

  Future<SmsResult> sendTestSms() =>
      sendSmsReminder('Test reminder from Accountability Coach.');
}
