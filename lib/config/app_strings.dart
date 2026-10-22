class AppStrings {
  AppStrings._();

  static const appName = 'Waypoint';
  static const subtitle = "Let's make today count.";
  static const yourGoals = 'Your Goals';
  static const noGoals = 'No goals yet';
  static const noGoalsSub = 'Tap + to add your first goal';
  static const challenge = 'Challenge';
  static const progress = 'Progress';
  static const rebalance = 'Rebalance';
  static const newGoal = 'New Goal';
  static const editGoal = 'Edit Goal';
  static const defineGoal = 'Define what you want to achieve.';
  static const updateGoal = 'Update this goal.';
  static const enterName = 'Enter a goal name';
  static const goalAdded = 'Goal added';
  static const goalUpdated = 'Goal updated';
  static const goalDeleted = 'Goal deleted';
  static const profileSaved = 'Profile saved';
  static const cancelLabel = 'Cancel';

  static const easy = 'Easy';
  static const moderate = 'Moderate';
  static const veryHard = 'Very hard';

  static const activeCount = '{n} active';
  static const needsAttention = '{n} need attention';
  static const addTask = 'Add {tier} task';
  static const confirmDelete = 'Delete "{name}"?';
  static const milestonesAdded = 'Added with {n} suggested milestones';
  static const skipOnTrack = 'On track · finishes {d} days early';
  static const skipBehind = 'Skipped {s} days · projected {d} days late';
  static const skipCritical = 'Skipped {s} days · will miss by {d} days';

  static String fmt(String template, Map<String, Object> vars) {
    var s = template;
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v.toString()));
    return s;
  }
}
