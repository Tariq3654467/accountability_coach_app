import '../config/app_config.dart';
import 'supabase_service.dart';

class SmsResult {
  final bool ok;
  final String message;
  const SmsResult(this.ok, this.message);
}

class SmsService {
  /// Off by default so no SMS credits are spent. Enable with --dart-define=ENABLE_SMS=true
  static const bool enabled = bool.fromEnvironment('ENABLE_SMS');

  static final _phoneRe = RegExp(r'^\+\d{8,15}$');

  bool isValidPhone(String? phone) => phone != null && _phoneRe.hasMatch(phone.trim());

  Future<SmsResult> sendReminder({required String? phone, required String message}) async {
    if (!isValidPhone(phone)) {
      return const SmsResult(false, 'Enter a phone number like +923001234567.');
    }
    if (!enabled) {
      return const SmsResult(true, 'SMS is in demo mode (no message was sent).');
    }
    if (!SupabaseService.isReady || SupabaseService.userId == null) {
      return const SmsResult(false, 'Sign in to send SMS reminders.');
    }
    try {
      await SupabaseService.client.functions.invoke(
        AppConfig.smsFunctionName,
        body: {'to': phone!.trim(), 'message': message},
      );
      return const SmsResult(true, 'SMS reminder sent.');
    } catch (e) {
      return SmsResult(false, 'SMS failed: $e');
    }
  }
}
