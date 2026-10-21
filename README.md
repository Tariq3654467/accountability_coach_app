# Accountability Coach — Flutter app (complete, runnable)

## What's in this zip
The app runs in **local-only mode** without Supabase or Firebase. Its dashboard
includes:
- sign in, sign up, password reset, profile editing, and continue-without-account
- goals with sectors, type, target, deadline, cadence, and reminder style
- rule-based milestone suggestions, plus optional Supabase AI suggestions
- daily, weekly, fortnightly, monthly, and one-time tasks with date-aware
  completion history
- a week timeline, overdue-task rebalancing, progress meters, and a local
  success-prediction estimate
- editable task areas and subtasks, plan horizons, and retrospective notes
- reminder preferences and daily check-ins on supported mobile platforms

The Flutter dashboard follows the extension's purple-and-lavender visual system,
with responsive desktop navigation and a mobile tab bar. Goal, profile, and
notification actions remain native to Flutter rather than embedding the
extension UI. Goal, timeline, and planning data are stored locally by default;
account-based sync and AI recommendations require the matching Supabase
configuration and backend functions.

## How to run it
```bash
flutter pub get
flutter run -d chrome        # quickest way to test in a browser
# or
flutter run                  # on a connected device/emulator
```
On first launch, tap **"Continue without an account"** — everything works
locally from there (saved via SharedPreferences / browser storage on web).

To enable account sign-in and Supabase-backed services:
```bash
flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=xxxx
```

To enable SMS (off by default, costs nothing until turned on):
```bash
flutter run --dart-define=ENABLE_SMS=true
```

## Supabase setup
Configure the Supabase URL and anon key above, then apply the SQL migrations in
the repository's `supabase/migrations` directory. AI milestone and task-area
recommendations also require the deployed `suggest-milestones` Edge Function.

## Notes
- Web builds skip local notifications. Reminder scheduling is available on
  supported mobile platforms and requires notification permission.
- SMS is in demo mode by default (`ENABLE_SMS` defaults to false) — the test
  button reports success without sending anything or spending credits.
- Nothing here touches your network or any other project until you run
  `flutter pub get` / `flutter run` yourself.
