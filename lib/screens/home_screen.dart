import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/profile_provider.dart';
import '../models/enums.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/empty_state.dart';
import '../widgets/goal_card.dart';
import '../widgets/planning_panel.dart';
import '../widgets/stats_row.dart';
import 'goal_form_sheet.dart';
import 'profile_sheet.dart';
import 'reminder_settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _goalsKey = GlobalKey();
  DateTime _selectedDate = DateTime.now();
  String _activeTab = 'today';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.fmt(AppStrings.confirmDelete, {'name': name})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final msg = await context.read<GoalProvider>().deleteGoal(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _scrollToGoals() {
    final target = _goalsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  void _setTab(String tab) {
    setState(() => _activeTab = tab);
    if (tab == 'goals' || tab == 'habits' || tab == 'insights') _scrollToGoals();
  }

  void _goToday() {
    _setTab('today');
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectTab(String tab) {
    if (tab == 'today') {
      _goToday();
    } else {
      _setTab(tab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wideLayout = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            if (wideLayout)
              _Sidebar(
                activeTab: _activeTab,
                onTab: _selectTab,
                onToday: _goToday,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                  onRefresh: context.read<GoalProvider>().load,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1480),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            constraints.maxWidth >= 850 ? 42 : 20,
                            0,
                            constraints.maxWidth >= 850 ? 42 : 20,
                            40,
                          ),
                          child: _DashboardBody(
                            wideLayout: constraints.maxWidth >= 850,
                            goalsKey: _goalsKey,
                            onDelete: _confirmDelete,
                            selectedDate: _selectedDate,
                            onDateSelected: (date) => setState(() => _selectedDate = date),
                            activeTab: _activeTab,
                            onTab: _selectTab,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.wideLayout,
    required this.goalsKey,
    required this.onDelete,
    required this.selectedDate,
    required this.onDateSelected,
    required this.activeTab,
    required this.onTab,
  });

  final bool wideLayout;
  final GlobalKey goalsKey;
  final Future<void> Function(BuildContext, String, String) onDelete;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String activeTab;
  final ValueChanged<String> onTab;

  String _dateLabel() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = goals.stats;
    final nextTask = _nextMilestone(goals.goals, selectedDate);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Topbar(
          wideLayout: wideLayout,
          onProfileTap: () => showProfileSheet(context),
          onSettingsTap: () => showReminderSettingsSheet(context),
        ),
        if (!wideLayout) ...[
          const SizedBox(height: 12),
          _MobileTabs(activeTab: activeTab, onTab: onTab),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 20),
          child: wideLayout
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _Welcome(profileName: profile.greetingName, date: _dateLabel())),
                    const SizedBox(width: 18),
                    _NewGoalButton(onPressed: () => showGoalFormSheet(context)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Welcome(profileName: profile.greetingName, date: _dateLabel()),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _NewGoalButton(onPressed: () => showGoalFormSheet(context)),
                    ),
                  ],
                ),
        ),
        _MomentumBanner(
          title: stats.done > 0 ? 'Your momentum is building.' : 'Your next small step starts here',
          description: stats.done > 0
              ? 'Every completed task is progress worth celebrating.'
              : 'Complete a task today to keep your momentum moving.',
          tag: stats.withinReach > 0
              ? '${stats.withinReach} goal${stats.withinReach == 1 ? '' : 's'} within reach'
              : 'A little progress goes a long way',
        ),
        const SizedBox(height: 14),
        StatsRow(stats: stats),
        const SizedBox(height: 26),
        ActivityTimeline(
          selectedDate: selectedDate,
          onDateSelected: onDateSelected,
          onRebalance: () async {
            final count = await goals.rebalanceOverdue();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(count == 0 ? 'Your plan is up to date.' : 'Your overdue tasks have a fresh schedule.'),
              ));
            }
          },
        ),
        const SizedBox(height: 18),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _GoalsSection(
                key: goalsKey,
                goals: goals,
                onDelete: onDelete,
                activeTab: activeTab,
              )),
              const SizedBox(width: 18),
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    _RightRail(goals: goals, nextTask: nextTask, selectedDate: selectedDate),
                    const SizedBox(height: 11),
                    PlanningPanel(selectedDate: selectedDate),
                  ],
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GoalsSection(key: goalsKey, goals: goals, onDelete: onDelete, activeTab: activeTab),
              const SizedBox(height: 24),
              _RightRail(goals: goals, nextTask: nextTask, selectedDate: selectedDate),
              const SizedBox(height: 11),
              PlanningPanel(selectedDate: selectedDate),
            ],
          ),
      ],
    );
  }

  Milestone? _nextMilestone(List<Goal> goals, DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);
    for (final goal in goals) {
      for (final task in goal.allMilestones) {
        final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        if (task.tier == Tier.daily) {
          if (!selected.isBefore(due) &&
              (goal.deadline == null || !selected.isAfter(DateTime(goal.deadline!.year, goal.deadline!.month, goal.deadline!.day))) &&
              !task.isDoneOn(selected)) return task;
        } else if (!task.done && due == selected) {
          return task;
        }
      }
    }
    return null;
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.wideLayout,
    required this.onProfileTap,
    required this.onSettingsTap,
  });
  final bool wideLayout;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final notifications = context.read<NotificationProvider>();
    return Container(
      height: 62,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                children: [
                  const TextSpan(text: 'Your space'),
                  const TextSpan(text: '   /   ', style: TextStyle(color: AppColors.textMute)),
                  TextSpan(text: wideLayout ? 'Today' : 'Waypoint', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          if (wideLayout) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF24C895)),
                  SizedBox(width: 7),
                  Text('Saved on this device', style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          IconButton(
            tooltip: 'Send a test reminder',
            onPressed: () async {
              await notifications.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test reminder sent if notifications are supported.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_none, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textDim,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Reminder and AI settings',
            onPressed: onSettingsTap,
            icon: const Icon(Icons.settings_outlined, size: 19),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textDim,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(24),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              child: Text(profile.initials, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.profileName, required this.date});
  final String profileName;
  final String date;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date.toUpperCase(),
              style: const TextStyle(fontSize: 9, color: AppColors.textDim, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Hi, '),
                TextSpan(text: profileName),
                const TextSpan(text: '  ✦', style: TextStyle(color: Color(0xFFF4A94D), fontSize: 21)),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.7),
          ),
          const SizedBox(height: 3),
          const Text('Small steps become momentum. Let’s make today count.',
              style: TextStyle(fontSize: 13, color: AppColors.textDim)),
        ],
      );
}

class _NewGoalButton extends StatelessWidget {
  const _NewGoalButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New goal'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      );
}

class _MomentumBanner extends StatelessWidget {
  const _MomentumBanner({required this.title, required this.description, required this.tag});
  final String title;
  final String description;
  final String tag;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 125),
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF7565F6), Color(0xFF8150E4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: const [BoxShadow(color: Color(0x307556DF), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: -8,
              child: Icon(Icons.auto_awesome, size: 82, color: Colors.white.withOpacity(.15)),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✦  YOUR WEEKLY MOMENTUM',
                      style: TextStyle(fontSize: 9, letterSpacing: 1.1, color: Color(0xFFE6E1FF), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFFF1EDFF))),
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(16)),
                    child: Text(tag, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    super.key,
    required this.goals,
    required this.onDelete,
    required this.activeTab,
  });
  final GoalProvider goals;
  final Future<void> Function(BuildContext, String, String) onDelete;
  final String activeTab;

  @override
  Widget build(BuildContext context) {
    final stats = goals.stats;
    final visibleGoals = goals.goals.where((goal) {
      if (activeTab == 'habits') return goal.type == GoalType.habit;
      return true;
    }).toList();
    final sectionTitle = switch (activeTab) {
      'habits' => 'Your habits',
      'insights' => 'Goal insights',
      _ => AppStrings.yourGoals,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sectionTitle,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.2)),
                  const SizedBox(height: 3),
                  Text(
                    stats.needAttention > 0
                        ? '${AppStrings.fmt(AppStrings.activeCount, {'n': stats.goals})} · ${AppStrings.fmt(AppStrings.needsAttention, {'n': stats.needAttention})}'
                        : '${AppStrings.fmt(AppStrings.activeCount, {'n': stats.goals})} · A little progress, consistently.',
                    style: const TextStyle(fontSize: 10, color: AppColors.textDim),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (goals.isLoading && goals.goals.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (visibleGoals.isEmpty)
          const EmptyState()
        else
          for (final goal in visibleGoals)
            GoalCard(
              goal: goal,
              onEdit: () => showGoalFormSheet(context, goal: goal),
              onDelete: () => onDelete(context, goal.id, goal.name),
            ),
      ],
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail({
    required this.goals,
    required this.nextTask,
    required this.selectedDate,
  });
  final GoalProvider goals;
  final Milestone? nextTask;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    var total = 0;
    var done = 0;
    for (final goal in goals.goals) {
      for (final task in goal.allMilestones) {
        final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        if (task.tier == Tier.daily) {
          final deadline = goal.deadline == null
              ? null
              : DateTime(goal.deadline!.year, goal.deadline!.month, goal.deadline!.day);
          if (date.isBefore(due) || (deadline != null && date.isAfter(deadline))) continue;
          total++;
          if (task.isDoneOn(date)) done++;
        } else if (date == due) {
          total++;
          if (task.done) done++;
        }
      }
    }
    final firstGoal = goals.goals.isEmpty ? null : goals.goals.first;
    final prediction = firstGoal == null ? null : goals.predictionFor(firstGoal);
    return Column(
      children: [
        _RailCard(
          icon: Icons.auto_awesome,
          title: "Today's challenge",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 11),
              Text(
                nextTask == null
                    ? (total == 0 ? 'Choose one small step and make it happen.' : "You've done today's steps. Celebrate that.")
                    : 'Quick win: ${nextTask.text}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, height: 1.5, color: AppColors.textDim),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$done of $total done', style: const TextStyle(fontSize: 9, color: AppColors.textDim)),
                  const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFF5A54C)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: total == 0 ? 0 : done / total,
                  backgroundColor: AppColors.surface2,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent2),
                ),
              ),
            ],
          ),
        ),
        if (prediction != null) ...[
          const SizedBox(height: 11),
          _RailCard(
            icon: Icons.insights,
            title: 'Success outlook',
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${prediction.percent}%',
                      style: const TextStyle(fontSize: 27, height: 1, fontWeight: FontWeight.w800, color: AppColors.accent)),
                  const SizedBox(height: 7),
                  Text('${prediction.verdict} · ${prediction.detail}',
                      style: const TextStyle(fontSize: 9, height: 1.5, color: AppColors.textDim)),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: AppColors.accentBg, borderRadius: BorderRadius.circular(13)),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.accent2),
              SizedBox(width: 8),
              Expanded(
                child: Text('Small, consistent actions create lasting momentum. Keep your next step realistic.',
                    style: TextStyle(fontSize: 9, height: 1.6, color: AppColors.textDim)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [BoxShadow(color: Color(0x05241D4B), blurRadius: 12, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: AppColors.accentBg, borderRadius: BorderRadius.circular(7)),
                  child: Icon(icon, size: 12, color: AppColors.accent2),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
            child,
          ],
        ),
      );
}

class _MobileTabs extends StatelessWidget {
  const _MobileTabs({required this.activeTab, required this.onTab});

  final String activeTab;
  final ValueChanged<String> onTab;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in const [
              (id: 'today', label: 'Today', icon: Icons.grid_view_rounded),
              (id: 'goals', label: 'Goals', icon: Icons.track_changes),
              (id: 'habits', label: 'Habits', icon: Icons.repeat_rounded),
              (id: 'insights', label: 'Insights', icon: Icons.insights_outlined),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  selected: activeTab == tab.id,
                  onSelected: (_) => onTab(tab.id),
                  avatar: Icon(tab.icon, size: 15),
                  label: Text(tab.label),
                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: AppColors.border),
                  selectedColor: AppColors.accentBg,
                  backgroundColor: AppColors.surface,
                ),
              ),
          ],
        ),
      );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.activeTab,
    required this.onTab,
    required this.onToday,
  });
  final String activeTab;
  final ValueChanged<String> onTab;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    return Container(
      width: 230,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 25, 18, 18),
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 35, height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.track_changes, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waypoint', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('ACCOUNTABILITY COACH', style: TextStyle(fontSize: 8, color: AppColors.accent, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Today',
            selected: activeTab == 'today',
            onTap: onToday,
          ),
          const SizedBox(height: 6),
          _SidebarItem(
            icon: Icons.track_changes,
            label: 'Goals',
            selected: activeTab == 'goals',
            onTap: () => onTab('goals'),
          ),
          const SizedBox(height: 6),
          _SidebarItem(
            icon: Icons.repeat_rounded,
            label: 'Habits',
            selected: activeTab == 'habits',
            onTap: () => onTab('habits'),
          ),
          const SizedBox(height: 6),
          _SidebarItem(
            icon: Icons.insights_outlined,
            label: 'Insights',
            selected: activeTab == 'insights',
            onTap: () => onTab('insights'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18, color: AppColors.green),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Local by default', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('AI shares details only when you ask.', style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => showProfileSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  child: Text(profile.initials, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.greetingName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const Text('Local profile', style: TextStyle(fontSize: 9, color: AppColors.textDim)),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: AppColors.textDim, size: 19),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.accentBg : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 17, color: selected ? AppColors.accent : AppColors.textDim),
                const SizedBox(width: 11),
                Text(label, style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.accent : AppColors.textDim,
                )),
              ],
            ),
          ),
        ),
      );
}
