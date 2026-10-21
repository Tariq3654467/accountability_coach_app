import 'package:flutter/foundation.dart';
import '../config/app_strings.dart';
import '../models/enums.dart';
import '../models/dashboard_state.dart';
import '../models/goal.dart';
import '../models/goal_metrics.dart';
import '../models/milestone.dart';
import '../services/ai_service.dart';
import '../services/goal_repository.dart';
import '../services/local_cache_service.dart';
import '../services/metrics_service.dart';
import '../services/milestone_suggester.dart';
import '../services/notification_service.dart';
import '../services/prediction_service.dart';
import '../utils/id_generator.dart';

class GoalProvider extends ChangeNotifier {
  GoalProvider({
    required GoalRepository repository,
    required LocalCacheService cache,
    required AiService ai,
    required NotificationService notifications,
    required PredictionService prediction,
  })  : _repo = repository,
        _cache = cache,
        _ai = ai,
        _notifications = notifications,
        _prediction = prediction;

  final GoalRepository _repo;
  final LocalCacheService _cache;
  final AiService _ai;
  final NotificationService _notifications;
  final PredictionService _prediction;

  List<Goal> _goals = [];
  bool _loading = false;
  bool _busy = false;
  bool _hasLoaded = false;
  String? _userId;
  DashboardState _dashboard = const DashboardState();

  List<Goal> get goals => List.unmodifiable(_goals);
  bool get isLoading => _loading;

  /// True while an AI request is running (show a spinner).
  bool get isBusy => _busy;
  DashboardState get dashboard => _dashboard;
  ReminderPreferences get preferences => _dashboard.preferences;

  OverallStats get stats => MetricsService.overall(_goals);

  Goal? goalById(String id) {
    for (final g in _goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  // ---------------------------------------------------------------- session

  /// Called from the proxy provider whenever auth changes. Safe to call during build.
  void syncUser({required bool signedIn, String? userId}) {
    if (!signedIn) {
      if (_hasLoaded || _goals.isNotEmpty) Future.microtask(_clear);
      return;
    }
    if (!_hasLoaded || userId != _userId) {
      _userId = userId;
      _hasLoaded = true;
      Future.microtask(load);
    }
  }

  Future<void> _clear() async {
    _hasLoaded = false;
    _userId = null;
    _goals = [];
    _dashboard = const DashboardState();
    await _notifications.cancelAll();
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _dashboard = await _cache.readDashboardState(scope: _userId ?? '');
      _goals = await _repo.fetchAll();
    } finally {
      _loading = false;
      notifyListeners();
    }
    for (final g in _goals) {
      await _notifications.scheduleForGoal(g, preferences: _dashboard.preferences);
    }
    await _notifications.scheduleDailyCheckIns(_dashboard.preferences);
  }

  Future<void> _saveDashboard(DashboardState value) async {
    _dashboard = value;
    notifyListeners();
    await _cache.writeDashboardState(_dashboard, scope: _userId ?? '');
  }

  Future<void> updatePreferences(ReminderPreferences value) async {
    await _saveDashboard(_dashboard.copyWith(preferences: value));
    await Future.wait(_goals.map((goal) =>
        _notifications.scheduleForGoal(goal, preferences: value)));
    await _notifications.scheduleDailyCheckIns(value);
  }

  Future<void> savePlanReview(String horizon, String text) {
    final reviews = Map<String, String>.of(_dashboard.planReviews)..[horizon] = text;
    return _saveDashboard(_dashboard.copyWith(planReviews: reviews));
  }

  Future<void> addTaskArea({String goalId = '', String title = ''}) async {
    final areas = [..._dashboard.taskAreas, TaskArea(id: IdGenerator.next(), goalId: goalId, title: title)];
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<String> recommendTaskAreas(String goalId) async {
    final goal = goalById(goalId);
    if (goal == null) throw StateError('Select a goal before requesting recommendations.');
    _setBusy(true);
    try {
      final suggestions = await _ai.recommendTaskAreas(goal);
      await _saveDashboard(_dashboard.copyWith(taskAreas: [...suggestions, ..._dashboard.taskAreas]));
      return 'Added ${suggestions.length} editable task areas.';
    } finally {
      _setBusy(false);
    }
  }

  Future<int> testAiConnection() async {
    final goal = _goals.isEmpty
        ? Goal(
            id: 'ai-connection-test',
            name: 'Build a daily reading habit',
            sectorId: 'learning',
            type: GoalType.habit,
            target: '10 minutes a day',
            deadline: DateTime.now().add(const Duration(days: 30)),
            cadence: Cadence.daily,
            createdAt: DateTime.now(),
            milestones: Goal.emptyTiers(),
          )
        : _goals.first;
    _setBusy(true);
    try {
      return (await _ai.recommendTaskAreas(goal)).length;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> updateTaskArea(String id, {String? title, String? goalId}) async {
    final areas = _dashboard.taskAreas.map((area) =>
      area.id == id ? area.copyWith(title: title, goalId: goalId) : area).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<void> toggleTaskArea(String id, DateTime date, bool done) async {
    final areas = _dashboard.taskAreas.map((area) {
      if (area.id != id) return area;
      final dates = Set<String>.of(area.completedDates);
      final key = _dateKey(date);
      if (done) {
        dates.add(key);
      } else {
        dates.remove(key);
      }
      return area.copyWith(completedDates: dates.toList()..sort());
    }).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<void> deleteTaskArea(String id) async {
    await _saveDashboard(_dashboard.copyWith(
      taskAreas: _dashboard.taskAreas.where((area) => area.id != id).toList(),
    ));
  }

  Future<void> addTaskAreaSubtask(String areaId, String title) async {
    final areas = _dashboard.taskAreas.map((area) {
      if (area.id != areaId) return area;
      return area.copyWith(subtasks: [
        ...area.subtasks,
        DashboardSubtask(id: IdGenerator.next(), title: title),
      ]);
    }).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<void> updateTaskAreaSubtask(String areaId, String subtaskId, String title) async {
    final areas = _dashboard.taskAreas.map((area) {
      if (area.id != areaId) return area;
      return area.copyWith(subtasks: area.subtasks.map((subtask) =>
        subtask.id == subtaskId ? subtask.copyWith(title: title) : subtask).toList());
    }).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<void> toggleTaskAreaSubtask(String areaId, String subtaskId, DateTime date, bool done) async {
    final areas = _dashboard.taskAreas.map((area) {
      if (area.id != areaId) return area;
      return area.copyWith(subtasks: area.subtasks.map((subtask) {
        if (subtask.id != subtaskId) return subtask;
        final dates = Set<String>.of(subtask.completedDates);
        final key = _dateKey(date);
        if (done) {
          dates.add(key);
        } else {
          dates.remove(key);
        }
        return subtask.copyWith(completedDates: dates.toList()..sort());
      }).toList());
    }).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  Future<void> deleteTaskAreaSubtask(String areaId, String subtaskId) async {
    final areas = _dashboard.taskAreas.map((area) => area.id != areaId
        ? area
        : area.copyWith(subtasks: area.subtasks.where((subtask) => subtask.id != subtaskId).toList())).toList();
    await _saveDashboard(_dashboard.copyWith(taskAreas: areas));
  }

  // ------------------------------------------------------------ metrics

  ChallengeResult challengeFor(Goal g) => MetricsService.challenge(g);
  ProgressResult progressFor(Goal g) => MetricsService.progress(g);
  SkipImpactResult? skipImpactFor(Goal g) => MetricsService.skipImpact(g);
  PredictionResult predictionFor(Goal g) => _prediction.predict(g);

  // --------------------------------------------------------- tier UI state

  bool isTierOpen(Tier t) => _cache.isTierOpen(t);
  Future<void> setTierOpen(Tier t, bool open) => _cache.setTierOpen(t, open);

  // ------------------------------------------------------------- goal CRUD

  /// Creates a goal with suggested milestones (rule-based, or AI when [useAi]).
  /// Returns the message to show the user.
  Future<String> addGoal({
    required String name,
    required String sectorId,
    GoalType type = GoalType.routine,
    String target = '',
    DateTime? deadline,
    Cadence cadence = Cadence.daily,
    ReminderStyle reminderStyle = ReminderStyle.gentle,
    String notes = '',
    bool useAi = false,
  }) async {
    var goal = Goal(
      id: IdGenerator.next(),
      name: name.trim(),
      sectorId: sectorId,
      type: type,
      target: target.trim(),
      deadline: deadline,
      cadence: cadence,
      reminderStyle: reminderStyle,
      notes: notes.trim(),
      createdAt: DateTime.now(),
      milestones: Goal.emptyTiers(),
    );

    Map<Tier, List<String>> suggested;
    String? note;
    if (useAi) {
      _setBusy(true);
      try {
        final r = await _ai.breakdown(goal);
        suggested = r.milestones;
        note = r.note;
      } finally {
        _setBusy(false);
      }
    } else {
      suggested = MilestoneSuggester.suggest(goal);
    }

    final merged = _merge(goal, suggested);
    goal = merged.goal;

    await _commit(goal);
    await _notifications.scheduleForGoal(goal, preferences: _dashboard.preferences);

    var message = merged.added > 0
        ? AppStrings.fmt(AppStrings.milestonesAdded, {'n': merged.added})
        : AppStrings.goalAdded;
    if (note != null) message = '$message · $note';
    return message;
  }

  /// [edited] must be built from the stored goal with copyWith so id, milestones
  /// and createdAt are preserved.
  Future<String> updateGoal(Goal edited) async {
    if (goalById(edited.id) == null) return AppStrings.goalUpdated;
    await _commit(edited);
    await _notifications.scheduleForGoal(edited, preferences: _dashboard.preferences);
    return AppStrings.goalUpdated;
  }

  Future<String> deleteGoal(String id) async {
    if (goalById(id) == null) return AppStrings.goalDeleted;
    _goals = _goals.where((g) => g.id != id).toList();
    notifyListeners();
    await _notifications.cancelForGoal(id);
    await _repo.delete(id, _goals);
    await _saveDashboard(_dashboard.copyWith(
      taskAreas: _dashboard.taskAreas.where((area) => area.goalId != id).toList(),
    ));
    return AppStrings.goalDeleted;
  }

  // -------------------------------------------------------- milestone ops

  Future<void> addMilestone(
    String goalId,
    Tier tier,
    String text, {
    DateTime? dueDate,
    int weight = 1,
  }) async {
    final clean = text.trim();
    final g = goalById(goalId);
    if (clean.isEmpty || g == null) return;
    await _commit(_withTier(g, tier, (list) {
      final now = DateTime.now();
      list.add(Milestone(
        id: IdGenerator.next(),
        text: clean,
        addedAt: now,
        tier: tier,
        dueDate: dueDate ?? DateTime(now.year, now.month, now.day),
        weight: weight.clamp(1, 10),
      ));
      return list;
    }));
  }

  Future<void> toggleMilestone(String goalId, Tier tier, String milestoneId, {DateTime? date}) async {
    final g = goalById(goalId);
    if (g == null) return;
    await _commit(_withTier(g, tier, (list) {
      final i = list.indexWhere((m) => m.id == milestoneId);
      if (i == -1) return list;
      final milestone = list[i];
      final actionDate = date ?? DateTime.now();
      if (tier == Tier.daily) {
        final key = _dateKey(actionDate);
        final dates = Set<String>.of(milestone.completedDates);
        if (!dates.add(key)) dates.remove(key);
        list[i] = milestone.copyWith(completedDates: dates.toList()..sort());
      } else {
        final nowDone = !milestone.done;
        list[i] = milestone.copyWith(
          done: nowDone,
          doneAt: nowDone ? actionDate : null,
          clearDoneAt: !nowDone,
        );
      }
      return list;
    }));
  }

  Future<void> editMilestone(String goalId, Tier tier, Milestone edited) async {
    final goal = goalById(goalId);
    if (goal == null) return;
    final next = {
      for (final currentTier in Tier.values)
        currentTier: goal.milestonesOf(currentTier).where((item) => item.id != edited.id).toList(),
    };
    next[edited.tier]!.add(edited);
    await _commit(goal.copyWith(milestones: next));
  }

  Future<int> rebalanceOverdue({DateTime? now}) async {
    final today = now ?? DateTime.now();
    var shifted = 0;
    for (final goal in List<Goal>.of(_goals)) {
      var changed = false;
      final tiers = {
        for (final tier in Tier.values)
          tier: goal.milestonesOf(tier).map((milestone) {
            if (tier == Tier.daily || milestone.done ||
                !DateTime(milestone.dueDate.year, milestone.dueDate.month, milestone.dueDate.day)
                    .isBefore(DateTime(today.year, today.month, today.day))) {
              return milestone;
            }
            changed = true;
            shifted++;
            return milestone.copyWith(dueDate: today.add(Duration(days: shifted)));
          }).toList(),
      };
      if (changed) await _commit(goal.copyWith(milestones: tiers));
    }
    return shifted;
  }

  Future<void> deleteMilestone(String goalId, Tier tier, String milestoneId) async {
    final g = goalById(goalId);
    if (g == null) return;
    await _commit(_withTier(g, tier, (list) {
      list.removeWhere((m) => m.id == milestoneId);
      return list;
    }));
  }

  // ------------------------------------------------------------ AI breakdown

  /// Asks for a fresh breakdown and appends only tasks the goal doesn't already have.
  /// Also used by the banner's "Rebalance" button. Returns the message to show.
  Future<String> applyAiBreakdown(String goalId) async {
    final g = goalById(goalId);
    if (g == null) return 'Goal not found';
    _setBusy(true);
    try {
      final r = await _ai.breakdown(g);
      final merged = _merge(g, r.milestones);
      if (merged.added == 0) {
        return r.note ?? 'No new tasks to add';
      }
      await _commit(merged.goal);
      final msg = 'Added ${merged.added} new task${merged.added == 1 ? '' : 's'}';
      return r.note != null ? '$msg · ${r.note}' : msg;
    } finally {
      _setBusy(false);
    }
  }

  // ----------------------------------------------------------- internals

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  /// Applies [changed] to the in-memory list (or inserts it at the top), then persists.
  Future<void> _commit(Goal changed) async {
    final i = _goals.indexWhere((g) => g.id == changed.id);
    if (i == -1) {
      _goals = [changed, ..._goals];
    } else {
      _goals = [..._goals]..[i] = changed;
    }
    notifyListeners();
    await _repo.upsert(changed, _goals);
  }

  Goal _withTier(Goal g, Tier tier, List<Milestone> Function(List<Milestone>) change) {
    final next = {
      for (final t in Tier.values) t: List<Milestone>.of(g.milestonesOf(t)),
    };
    next[tier] = change(next[tier]!);
    return g.copyWith(milestones: next);
  }

  ({Goal goal, int added}) _merge(Goal g, Map<Tier, List<String>> suggested) {
    final next = {
      for (final t in Tier.values) t: List<Milestone>.of(g.milestonesOf(t)),
    };
    var added = 0;
    final now = DateTime.now();
    for (final t in Tier.values) {
      final seen = next[t]!.map((m) => m.text.trim().toLowerCase()).toSet();
      for (final text in suggested[t] ?? const <String>[]) {
        final clean = text.trim();
        if (clean.isEmpty || !seen.add(clean.toLowerCase())) continue;
        next[t]!.add(Milestone(
          id: IdGenerator.next(),
          text: clean,
          addedAt: now,
          tier: t,
          dueDate: now,
        ));
        added++;
      }

      String _dateKey(DateTime date) =>
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
    return (goal: g.copyWith(milestones: next), added: added);
  }
}
