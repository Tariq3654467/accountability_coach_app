class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// AI calls go through the same Supabase Edge Function as the extension.
  static const aiFunctionName = 'suggest-milestones';
  static const smsFunctionName = 'send-sms-reminder';

  static const goalsTable = 'goals';
  static const profilesTable = 'profiles';

  static const defaultHorizonDays = 90;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
