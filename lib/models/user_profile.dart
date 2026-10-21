class UserProfile {
  final String displayName;
  final String? phone;
  final String? fcmToken;
  final String? username;

  const UserProfile({this.displayName = '', this.phone, this.fcmToken, this.username});

  String get greetingName => displayName.isEmpty ? 'there' : displayName;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.map((w) => w[0]).take(2).join().toUpperCase();
  }

  UserProfile copyWith({String? displayName, String? phone, String? fcmToken, String? username}) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        fcmToken: fcmToken ?? this.fcmToken,
        username: username ?? this.username,
      );

  Map<String, dynamic> toJson() =>
      {'display_name': displayName, 'phone': phone, 'username': username, 'fcm_token': fcmToken};

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        displayName: (j['display_name'] ?? '') as String,
        phone: j['phone'] as String?,
        fcmToken: j['fcm_token'] as String?,
        username: j['username'] as String?,
      );
}
