import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ProfileSheet(),
  );
}

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final _name =
      TextEditingController(text: context.read<ProfileProvider>().profile.displayName);
  late final _phone =
      TextEditingController(text: context.read<ProfileProvider>().profile.phone ?? '');
  late final _username =
      TextEditingController(text: context.read<ProfileProvider>().profile.username ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    String? phoneError;
    if (auth.isRemoteAvailable && auth.isSignedIn) {
      phoneError = await profile.saveAccountProfile(
        username: _username.text,
        displayName: _name.text,
        phone: _phone.text,
      );
    } else {
      await profile.saveDisplayName(_name.text);
      phoneError = await profile.savePhone(_phone.text);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneError)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final profile = context.watch<ProfileProvider>();
    final auth = context.watch<AuthProvider>();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: AppColors.borderHi, borderRadius: BorderRadius.circular(5)),
                ),
              ),
              const Text('Your Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5)),
              const SizedBox(height: 4),
              Text(auth.isRemoteAvailable && auth.isSignedIn
                  ? '${auth.email ?? ''} · ${auth.emailConfirmed ? 'Email verified' : 'Email not verified'}'
                  : 'Personalize your dashboard. Stored on this device.',
                  style: TextStyle(fontSize: 13, color: AppColors.textDim)),
              const SizedBox(height: 20),

              const Text('Display Name',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(controller: _name, maxLength: 30, decoration: const InputDecoration(counterText: '')),
              if (auth.isRemoteAvailable && auth.isSignedIn) ...[
                const SizedBox(height: 14),
                const Text('Username',
                    style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _username,
                  autocorrect: false,
                  decoration: const InputDecoration(prefixText: '@', hintText: 'your_username'),
                ),
              ],
              const SizedBox(height: 14),

              const Text('Phone (for SMS reminders)',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+923001234567'),
              ),
              const SizedBox(height: 6),
              Text(
                profile.hasPhone
                    ? 'SMS is in demo mode by default — no message is actually sent.'
                    : 'Add a number to enable SMS reminders (demo mode by default).',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMute),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notifications.isSupported
                          ? (notifications.permissionGranted
                              ? 'Notifications enabled'
                              : 'Notifications not yet enabled')
                          : 'Notifications aren\'t supported on this platform (e.g. web).',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (notifications.isSupported && !notifications.permissionGranted)
                    TextButton(
                      onPressed: () => context.read<NotificationProvider>().enableReminders(),
                      child: const Text('Enable'),
                    ),
                ],
              ),
              if (notifications.isSupported)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.read<NotificationProvider>().sendTestNotification(),
                    child: const Text('Send test notification'),
                  ),
                ),
              if (profile.hasPhone)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      final result = await context.read<ProfileProvider>().sendTestSms();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(result.message)));
                      }
                    },
                    child: const Text('Send test SMS'),
                  ),
                ),
              if (auth.isRemoteAvailable && auth.isSignedIn)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.logout, size: 17),
                    label: const Text('Sign out'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.red),
                  ),
                ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text(AppStrings.cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
