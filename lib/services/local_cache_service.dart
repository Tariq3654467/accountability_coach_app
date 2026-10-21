import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../models/dashboard_state.dart';
import '../models/goal.dart';
import '../models/user_profile.dart';

class LocalCacheService {
  static const _goalsKey = 'ac_goals_v2';
  static const _profileKey = 'ac_profile_v2';
  static const _tierKey = 'ac_tier_state_';
  static const _dashboardKey = 'ac_dashboard_state_v1';

  SharedPreferences? _prefs;
  bool get isAvailable => _prefs != null;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  String _k(String base, String scope) => scope.isEmpty ? base : '${base}_$scope';

  Future<List<Goal>> readGoals({String scope = ''}) async {
    final raw = _prefs?.getString(_k(_goalsKey, scope));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeGoals(List<Goal> goals, {String scope = ''}) async {
    await _prefs?.setString(
        _k(_goalsKey, scope), jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  Future<UserProfile> readProfile({String scope = ''}) async {
    final raw = _prefs?.getString(_k(_profileKey, scope));
    if (raw == null || raw.isEmpty) return const UserProfile();
    try {
      return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> writeProfile(UserProfile p, {String scope = ''}) async {
    await _prefs?.setString(_k(_profileKey, scope), jsonEncode(p.toJson()));
  }

  Future<DashboardState> readDashboardState({String scope = ''}) async {
    final raw = _prefs?.getString(_k(_dashboardKey, scope));
    if (raw == null || raw.isEmpty) return const DashboardState();
    try {
      return DashboardState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const DashboardState();
    }
  }

  Future<void> writeDashboardState(DashboardState state, {String scope = ''}) async {
    await _prefs?.setString(_k(_dashboardKey, scope), jsonEncode(state.toJson()));
  }

  bool isTierOpen(Tier t) => _prefs?.getString('$_tierKey${t.name}') == 'open';

  Future<void> setTierOpen(Tier t, bool open) async {
    await _prefs?.setString('$_tierKey${t.name}', open ? 'open' : 'closed');
  }
}
