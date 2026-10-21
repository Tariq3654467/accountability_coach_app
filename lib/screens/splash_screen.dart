import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
              child: const Icon(Icons.track_changes, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 20),
            const Text(AppStrings.appName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.4)),
            const SizedBox(height: 18),
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
