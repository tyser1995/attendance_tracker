class AppConfig {
  AppConfig._();

  static const bool isTrial =
      bool.fromEnvironment('TRIAL_MODE', defaultValue: false);

  /// How many days the trial lasts from first launch.
  static const int trialDays =
      int.fromEnvironment('TRIAL_DAYS', defaultValue: 30);

  /// Maximum number of active students allowed in trial mode.
  static const int trialStudentLimit =
      int.fromEnvironment('TRIAL_STUDENT_LIMIT', defaultValue: 50);
}
