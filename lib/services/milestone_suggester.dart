import '../models/enums.dart';
import '../models/goal.dart';

class MilestoneSuggester {
  MilestoneSuggester._();

  static Map<Tier, List<String>> suggest(Goal goal) {
    final target = goal.target.toLowerCase();
    final s = <Tier, List<String>>{for (final t in Tier.values) t: <String>[]};

    final kgMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(?:kg|kilo)').firstMatch(target);

    if (kgMatch != null && goal.sectorId == 'weight-loss') {
      final kg = double.parse(kgMatch.group(1)!);
      s[Tier.daily] = ['30-min walk or workout', 'Stay within calorie budget', 'Drink 2.5L water'];
      s[Tier.weekly] = ['Weigh in and log', 'Meal prep 3 days'];
      s[Tier.fortnightly] = ['Review progress vs plan'];
      s[Tier.monthly] = ['Lose ${(kg / 3).toStringAsFixed(1)} kg'];
    } else if (goal.sectorId == 'language') {
      s[Tier.daily] = ['15-min practice session', 'Learn 5 new words'];
      s[Tier.weekly] = ['Complete 1 lesson unit'];
      s[Tier.fortnightly] = ['Have a 10-min conversation'];
      s[Tier.monthly] = ['Complete a mock test'];
    } else if (goal.sectorId == 'business') {
      s[Tier.daily] = ['30-min focused work on business'];
      s[Tier.weekly] = ['Ship 1 feature or asset'];
      s[Tier.fortnightly] = ['Talk to 3 potential customers'];
      s[Tier.monthly] = ['Hit a revenue or user milestone'];
    } else if (goal.sectorId == 'steps') {
      s[Tier.daily] = ['Walk 2,000 steps before noon', '15-min walk after lunch', 'Reach daily step goal'];
      s[Tier.weekly] = ['One long walk (60+ min)'];
      s[Tier.fortnightly] = ['Review weekly average'];
      s[Tier.monthly] = ['Increase daily average by 500'];
    } else if (goal.sectorId == 'reading') {
      s[Tier.daily] = ['Read 10 pages'];
      s[Tier.weekly] = ['Finish 1 chapter'];
      s[Tier.fortnightly] = ['Write a short summary'];
      s[Tier.monthly] = ['Finish 1 book'];
    } else if (goal.sectorId == 'finance') {
      s[Tier.daily] = ['Log every expense'];
      s[Tier.weekly] = ['Review weekly spending'];
      s[Tier.fortnightly] = ['Move savings to account'];
      s[Tier.monthly] = ['Reach savings milestone'];
    } else {
      s[Tier.daily] = ['30-min focused work'];
      s[Tier.weekly] = ['Review progress'];
      s[Tier.fortnightly] = ['Adjust approach'];
      s[Tier.monthly] = ['Hit a major milestone'];
    }
    return s;
  }
}
