import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class TrialService {
  static const _key = 'trial_first_launch';

  /// Records first launch date if not already stored.
  /// Returns [TrialStatus] with expiry info.
  static Future<TrialStatus> init() async {
    if (!AppConfig.isTrial) return TrialStatus.full();

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);

    final DateTime firstLaunch;
    if (stored == null) {
      firstLaunch = DateTime.now();
      await prefs.setString(_key, firstLaunch.toIso8601String());
    } else {
      firstLaunch = DateTime.parse(stored);
    }

    final expiry = firstLaunch.add(Duration(days: AppConfig.trialDays));
    final daysLeft = expiry.difference(DateTime.now()).inDays;
    final expired = DateTime.now().isAfter(expiry);

    return TrialStatus.trial(
      firstLaunch: firstLaunch,
      expiry: expiry,
      daysLeft: daysLeft.clamp(0, AppConfig.trialDays),
      expired: expired,
    );
  }
}

class TrialStatus {
  final bool isTrial;
  final bool expired;
  final int daysLeft;
  final DateTime? expiry;

  const TrialStatus._({
    required this.isTrial,
    required this.expired,
    required this.daysLeft,
    this.expiry,
  });

  factory TrialStatus.full() => const TrialStatus._(
        isTrial: false,
        expired: false,
        daysLeft: -1,
      );

  factory TrialStatus.trial({
    required DateTime firstLaunch,
    required DateTime expiry,
    required int daysLeft,
    required bool expired,
  }) =>
      TrialStatus._(
        isTrial: true,
        expired: expired,
        daysLeft: daysLeft,
        expiry: expiry,
      );
}
