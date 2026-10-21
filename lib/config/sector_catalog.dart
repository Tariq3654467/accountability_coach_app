import 'package:flutter/material.dart';
import '../models/sector.dart';

class SectorCatalog {
  SectorCatalog._();

  static const fallback = Sector('custom', 'Custom', Color(0xFF94A3B8), Icons.star_outline);

  static const all = <Sector>[
    Sector('weight-loss', 'Weight Loss', Color(0xFFF472B6), Icons.monitor_weight_outlined),
    Sector('weight-gain', 'Weight Gain', Color(0xFFFB923C), Icons.monitor_weight_outlined),
    Sector('business', 'Business', Color(0xFF60A5FA), Icons.work_outline),
    Sector('language', 'Language', Color(0xFFA06CFF), Icons.language),
    Sector('intelligence', 'Cognitive', Color(0xFF8B5CF6), Icons.psychology_outlined),
    fallback,
    Sector('career', 'Career', Color(0xFF38BDF8), Icons.work_outline),
    Sector('finance', 'Finance', Color(0xFFF59E0B), Icons.attach_money),
    Sector('mindfulness', 'Mindfulness', Color(0xFFA06CFF), Icons.nightlight_outlined),
    Sector('sleep', 'Sleep', Color(0xFF818CF8), Icons.nightlight_outlined),
    Sector('creative', 'Creative', Color(0xFFEC4899), Icons.star_outline),
    Sector('relationships', 'Relationships', Color(0xFFFB7185), Icons.favorite_border),
    Sector('organization', 'Home', Color(0xFF84CC16), Icons.home_outlined),
    Sector('longevity', 'Longevity', Color(0xFF14B8A6), Icons.favorite_border),
    Sector('academic', 'Academic', Color(0xFF60A5FA), Icons.menu_book_outlined),
    Sector('philanthropy', 'Community', Color(0xFF22C55E), Icons.favorite_border),
    Sector('hydration', 'Hydration', Color(0xFF06B6D4), Icons.water_drop_outlined),
    Sector('posture', 'Posture', Color(0xFFFB923C), Icons.person_outline),
    Sector('steps', 'Steps', Color(0xFF84CC16), Icons.directions_walk),
    Sector('eye-health', 'Eye Health', Color(0xFF38BDF8), Icons.visibility_outlined),
    Sector('breathing', 'Breathing', Color(0xFFA06CFF), Icons.air),
    Sector('nutrition', 'Nutrition', Color(0xFF22C55E), Icons.apple),
    Sector('fasting', 'Fasting', Color(0xFFF59E0B), Icons.schedule),
    Sector('skincare', 'Skincare', Color(0xFFF472B6), Icons.auto_awesome),
    Sector('medication', 'Medication', Color(0xFFEF4444), Icons.medication_outlined),
    Sector('focus', 'Focus', Color(0xFF818CF8), Icons.gps_fixed),
    Sector('digital-detox', 'Digital Detox', Color(0xFF94A3B8), Icons.phone_android),
    Sector('gratitude', 'Gratitude', Color(0xFFF59E0B), Icons.favorite_border),
    Sector('reading', 'Reading', Color(0xFF60A5FA), Icons.menu_book_outlined),
    Sector('vocabulary', 'Vocabulary', Color(0xFF8B5CF6), Icons.psychology_outlined),
    Sector('music', 'Music', Color(0xFFEC4899), Icons.music_note),
    Sector('speaking', 'Speaking', Color(0xFFFB7185), Icons.mic_none),
    Sector('networking', 'Networking', Color(0xFF38BDF8), Icons.groups_outlined),
    Sector('chores', 'Chores', Color(0xFF84CC16), Icons.home_outlined),
    Sector('budget', 'Budget', Color(0xFFF59E0B), Icons.attach_money),
    Sector('prayer', 'Spiritual', Color(0xFFA06CFF), Icons.nightlight_outlined),
  ];

  static Sector byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => fallback);
}
