import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/goal_repository.dart';
import 'services/local_cache_service.dart';
import 'services/notification_service.dart';
import 'services/prediction_service.dart';
import 'services/profile_repository.dart';
import 'services/push_service.dart';
import 'services/sms_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe no-ops if keys/plugins aren't configured — the app still runs locally.
  await SupabaseService.init();

  final cache = LocalCacheService();
  await cache.init();

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(AccountabilityCoachApp(cache: cache, notificationService: notificationService));
}

class AccountabilityCoachApp extends StatelessWidget {
  const AccountabilityCoachApp({
    super.key,
    required this.cache,
    required this.notificationService,
  });

  final LocalCacheService cache;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProxyProvider<AuthProvider, GoalProvider>(
          create: (_) => GoalProvider(
            repository: GoalRepository(cache),
            cache: cache,
            ai: AiService(),
            notifications: notificationService,
            prediction: PredictionService(),
          ),
          update: (_, auth, goals) =>
              goals!..syncUser(signedIn: auth.isSignedIn, userId: auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProfileProvider>(
          create: (_) => ProfileProvider(
            repository: ProfileRepository(cache),
            sms: SmsService(),
          ),
          update: (_, auth, profile) =>
              profile!..syncUser(signedIn: auth.isSignedIn, userId: auth.userId),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(local: notificationService, push: PushService()),
        ),
      ],
      child: MaterialApp(
        title: 'Accountability Coach',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Shows the auth screen or the dashboard depending on sign-in state,
/// and starts push notifications once (best-effort; safe to fail).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _pushStarted = false;

  void _maybeStartPush(bool signedIn) {
    if (!signedIn || _pushStarted) return;
    _pushStarted = true;
    final notifications = context.read<NotificationProvider>();
    final profile = context.read<ProfileProvider>();
    notifications.initPush(onToken: profile.updateFcmToken);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isBusy && !auth.isSignedIn) {
      return const SplashScreen();
    }

    if (!auth.isSignedIn) {
      _pushStarted = false;
      return const AuthScreen();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartPush(true));
    return const HomeScreen();
  }
}
