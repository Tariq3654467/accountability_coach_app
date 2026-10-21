import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x0D141428), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: const Column(
        children: [
          Text('🎯', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text(AppStrings.noGoals,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.4)),
          SizedBox(height: 6),
          Text(AppStrings.noGoalsSub, style: TextStyle(fontSize: 14, color: AppColors.textDim)),
        ],
      ),
    );
  }
}
