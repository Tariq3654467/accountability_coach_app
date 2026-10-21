import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/dashboard_state.dart';
import '../providers/goal_provider.dart';
import '../providers/notification_provider.dart';

Future<void> showReminderSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderSettingsSheet(),
    );

class ReminderSettingsSheet extends StatefulWidget {
  const ReminderSettingsSheet({super.key});

  @override
  State<ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<ReminderSettingsSheet> {
  late ReminderPreferences _preferences;
  bool _saving = false;
  String? _aiStatus;

  @override
  void initState() {
    super.initState();
    _preferences = context.read<GoalProvider>().preferences;
  }

  Future<void> _pickTime(String current, ValueChanged<String> update) async {
    final parts = current.split(':').map(int.tryParse).toList();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: parts.isNotEmpty ? (parts[0] ?? 9).clamp(0, 23) : 9,
        minute: parts.length > 1 ? (parts[1] ?? 0).clamp(0, 59) : 0,
      ),
    );
    if (time != null) {
      update('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final notifications = context.read<NotificationProvider>();
      if (notifications.isSupported &&
          (_preferences.notificationsEnabled || _preferences.dailyCheckInsEnabled)) {
        final granted = await notifications.enableReminders();
        if (!granted) {
          setState(() => _preferences = _preferences.copyWith(
                notificationsEnabled: false,
                dailyCheckInsEnabled: false,
              ));
          throw StateError('Notification permission was not granted. Reminder settings were not enabled.');
        }
      }
      await context.read<GoalProvider>().updatePreferences(_preferences);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder settings saved.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testAi() async {
    setState(() => _aiStatus = 'Testing AI recommendations…');
    try {
      final count = await context.read<GoalProvider>().testAiConnection();
      if (mounted) setState(() => _aiStatus = 'AI recommendations work: $count task areas received.');
    } catch (error) {
      if (mounted) setState(() => _aiStatus = 'AI test failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(
                  width: 40, height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: AppColors.borderHi, borderRadius: BorderRadius.circular(5)),
                )),
                const Text('Reminders & AI', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Notifications are optional. AI features contact Supabase only when you use them.',
                    style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                const SizedBox(height: 18),
                const Text('Task reminders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable due-date notifications', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('Remind you about unfinished tasks at their scheduled time.',
                      style: TextStyle(fontSize: 10)),
                  value: _preferences.notificationsEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (value) => setState(() =>
                      _preferences = _preferences.copyWith(notificationsEnabled: value)),
                ),
                _TimePreference(
                  title: 'Reminder time',
                  value: _preferences.reminderTime,
                  onTap: () => _pickTime(_preferences.reminderTime, (time) =>
                      setState(() => _preferences = _preferences.copyWith(reminderTime: time))),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Day-start and day-end check-ins', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('A morning nudge and an evening wrap-up.',
                      style: TextStyle(fontSize: 10)),
                  value: _preferences.dailyCheckInsEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (value) => setState(() =>
                      _preferences = _preferences.copyWith(dailyCheckInsEnabled: value)),
                ),
                Row(
                  children: [
                    Expanded(child: _TimePreference(
                      title: 'Day starts',
                      value: _preferences.dayStartTime,
                      onTap: () => _pickTime(_preferences.dayStartTime, (time) =>
                          setState(() => _preferences = _preferences.copyWith(dayStartTime: time))),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _TimePreference(
                      title: 'Day ends',
                      value: _preferences.dayEndTime,
                      onTap: () => _pickTime(_preferences.dayEndTime, (time) =>
                          setState(() => _preferences = _preferences.copyWith(dayEndTime: time))),
                    )),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Uses this device’s local time. The app must be allowed to send notifications.',
                      style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                ),
                const Divider(height: 24),
                const Text('Gemini task recommendations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('AI requests send a goal summary to your configured Supabase Edge Function. Keep the Gemini key server-side.',
                    style: TextStyle(fontSize: 10, height: 1.4, color: AppColors.textDim)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _testAi,
                    child: const Text('Test AI recommendations', style: TextStyle(fontSize: 10)),
                  ),
                ),
                if (_aiStatus != null)
                  Text(_aiStatus!, style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                        child: _saving
                            ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save settings'),
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

class _TimePreference extends StatelessWidget {
  const _TimePreference({required this.title, required this.value, required this.onTap});
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            alignment: Alignment.centerLeft,
            side: const BorderSide(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textDim))),
              Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
            ],
          ),
        ),
      );
}
