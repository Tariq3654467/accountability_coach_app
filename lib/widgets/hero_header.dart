import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.greetingName,
    required this.initials,
    required this.onProfileTap,
    required this.pillText,
  });

  final String greetingName;
  final String initials;
  final VoidCallback onProfileTap;
  final String pillText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text('Hi, $greetingName',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -1),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(AppStrings.subtitle,
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF8A8A96), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.accentBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(initials,
                    style: const TextStyle(
                        color: AppColors.accent2, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0EFFF), Color(0xFFFDF4FF)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F7864B4), blurRadius: 8, offset: Offset(0, 2))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.accent2),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(pillText,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
