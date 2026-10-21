import '../config/app_config.dart';
import '../models/user_profile.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';

class ProfileRepository {
  ProfileRepository(this._cache);
  final LocalCacheService _cache;

  String? get _uid => SupabaseService.userId;

  Future<UserProfile> fetch() async {
    final uid = _uid;
    if (uid != null) {
      try {
        final row = await SupabaseService.client
            .from(AppConfig.profilesTable)
            .select()
            .eq('id', uid)
            .maybeSingle();
        if (row != null) {
          final p = UserProfile.fromJson(Map<String, dynamic>.from(row));
          await _cache.writeProfile(p, scope: uid);
          return p;
        }
      } catch (_) {}
    }
    return _cache.readProfile(scope: uid ?? '');
  }

  Future<void> save(UserProfile profile) async {
    final uid = _uid;
    await _cache.writeProfile(profile, scope: uid ?? '');
    if (uid == null) return;
    try {
      await SupabaseService.client
          .from(AppConfig.profilesTable)
          .upsert({
            'id': uid,
            'username': profile.username,
            'display_name': profile.displayName,
            'phone': profile.phone ?? '',
          });
    } catch (_) {}
  }
}
