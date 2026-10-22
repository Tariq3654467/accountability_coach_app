import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 122,
                height: 198,
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(64),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.track_changes, color: Colors.white, size: 88),
              ),
              const SizedBox(height: 38),
              Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 46,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF202532),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Accountability Coach',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your accountability coach',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF898E98),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
