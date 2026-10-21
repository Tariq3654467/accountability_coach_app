import '../config/app_config.dart';
import '../models/goal.dart';
import 'local_cache_service.dart';
import 'supabase_service.dart';

class GoalRepository {
  GoalRepository(this._cache);
  final LocalCacheService _cache;

  String? get _uid => SupabaseService.userId;
  String get _scope => _uid ?? '';

  Map<String, dynamic> _payload(Goal g, String uid) => {
        ...g.toJson(),
        'user_id': uid,
        // timestamptz column: send UTC so the instant is preserved
        'created_at': g.createdAt.toUtc().toIso8601String(),
      };

  Future<List<Goal>> fetchAll() async {
    final uid = _uid;
    if (uid != null) {
      try {
        final rows = await SupabaseService.client
            .from(AppConfig.goalsTable)
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false);
        final goals = (rows as List)
            .map((r) => Goal.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        await _cache.writeGoals(goals, scope: _scope);
        return goals;
      } catch (_) {
        // fall through to cache (offline)
      }
    }
    return _cache.readGoals(scope: _scope);
  }

  /// Persists the full list locally, then syncs the changed goal remotely.
  Future<void> upsert(Goal goal, List<Goal> allGoals) async {
    await _cache.writeGoals(allGoals, scope: _scope);
    final uid = _uid;
    if (uid == null) return;
    try {
      await SupabaseService.client
          .from(AppConfig.goalsTable)
          .upsert(_payload(goal, uid));
    } catch (_) {
      // Local copy is saved; remote sync retries on next change.
    }
  }

  Future<void> delete(String id, List<Goal> remaining) async {
    await _cache.writeGoals(remaining, scope: _scope);
    if (_uid == null) return;
    try {
      await SupabaseService.client
          .from(AppConfig.goalsTable)
          .delete()
          .eq('id', id);
    } catch (_) {}
  }
}
