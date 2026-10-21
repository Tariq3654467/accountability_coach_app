import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<void> init() async {
    if (!AppConfig.hasSupabase) return;
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Null when Supabase is unavailable or nobody is signed in.
  static String? get userId => _ready ? client.auth.currentUser?.id : null;
}
