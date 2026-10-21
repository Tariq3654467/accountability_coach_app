import '../config/app_config.dart';
import '../config/sector_catalog.dart';
import '../models/dashboard_state.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import 'milestone_suggester.dart';
import 'supabase_service.dart';
import '../utils/id_generator.dart';

class AiBreakdownResult {
  final Map<Tier, List<String>> milestones;
  final bool fromAi;
  final String? note;
  const AiBreakdownResult(this.milestones, {required this.fromAi, this.note});
}

class AiService {
  Future<AiBreakdownResult> breakdown(Goal goal) async {
    if (!SupabaseService.isReady || SupabaseService.userId == null) {
      return AiBreakdownResult(MilestoneSuggester.suggest(goal),
          fromAi: false, note: 'AI needs a signed-in Supabase session. Used suggestions.');
    }
    try {
      final res = await SupabaseService.client.functions.invoke(
        AppConfig.aiFunctionName,
        body: {'goal': _goalPayload(goal)},
      );
      final parsed = _parse(res.data);
      if (parsed != null) return AiBreakdownResult(parsed, fromAi: true);
    } catch (_) {}
    return AiBreakdownResult(MilestoneSuggester.suggest(goal),
        fromAi: false, note: 'AI unavailable. Used suggestions.');
  }

  Map<Tier, List<String>>? _parse(dynamic data) {
    if (data is! Map) return null;
    if (data['milestones'] is List) {
      final parsed = <Tier, List<String>>{for (final tier in Tier.values) tier: <String>[]};
      for (final item in (data['milestones'] as List).whereType<Map>()) {
        final tierName = item['tier']?.toString().toLowerCase();
        final tier = enumByName(Tier.values, tierName, Tier.daily);
        final text = item['title']?.toString().trim() ?? '';
        if (text.isNotEmpty) parsed[tier]!.add(text.length > 120 ? text.substring(0, 120) : text);
      }
      return parsed.values.every((items) => items.isEmpty) ? null : parsed;
    }
    if (data['milestones'] is! Map) return null;
    final raw = data['milestones'] as Map;
    final out = <Tier, List<String>>{for (final t in Tier.values) t: <String>[]};
    var total = 0;
    for (final t in Tier.values) {
      final list = raw[t.name];
      if (list is List) {
        for (final item in list.whereType<String>().take(8)) {
          final s = item.trim();
          if (s.isEmpty) continue;
          out[t]!.add(s.length > 120 ? s.substring(0, 120) : s);
          total++;
        }
      }
    }
    return total == 0 ? null : out;
  }

  Future<List<TaskArea>> recommendTaskAreas(Goal goal) async {
    if (!SupabaseService.isReady || SupabaseService.userId == null) {
      throw StateError('Task-area recommendations require a signed-in Supabase account.');
    }
    final result = await SupabaseService.client.functions.invoke(
      AppConfig.aiFunctionName,
      body: {'mode': 'task-areas', 'goal': _goalPayload(goal)},
    );
    final data = result.data;
    if (data is! Map || data['taskAreas'] is! List || (data['taskAreas'] as List).length != 3) {
      throw const FormatException('The AI service returned an unexpected task-area response.');
    }
    return (data['taskAreas'] as List).map((raw) {
      if (raw is! Map || raw['title'] is! String || raw['subtasks'] is! List) {
        throw const FormatException('The AI service returned an invalid task recommendation.');
      }
      final title = (raw['title'] as String).trim();
      final subtasks = (raw['subtasks'] as List).whereType<String>().map((item) => item.trim()).toList();
      if (title.isEmpty || title.length > 100 || subtasks.length != 2 ||
          subtasks.any((item) => item.isEmpty || item.length > 120)) {
        throw const FormatException('The AI service returned an invalid task recommendation.');
      }
      return TaskArea(
        id: IdGenerator.next(),
        goalId: goal.id,
        title: title,
        subtasks: subtasks.map((item) => DashboardSubtask(id: IdGenerator.next(), title: item)).toList(),
      );
    }).toList();
  }

  Map<String, dynamic> _goalPayload(Goal goal) => {
        'id': goal.id,
        'title': goal.name,
        'sector': SectorCatalog.byId(goal.sectorId).name,
        'type': goal.type.label,
        'target': goal.target,
        'deadline': goal.deadline?.toIso8601String().substring(0, 10),
        'cadence': goal.cadence.label,
      };
}
