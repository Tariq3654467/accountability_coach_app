class Validators {
  Validators._();

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRe = RegExp(r'^\+\d{8,15}$');

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter an email address';
    if (!_emailRe.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? goalName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a goal name';
    return null;
  }

  static String? phoneOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!_phoneRe.hasMatch(v.trim())) return 'Use format +923001234567';
    return null;
  }
}
