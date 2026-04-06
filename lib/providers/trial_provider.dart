import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/trial_service.dart';

final trialStatusProvider = FutureProvider<TrialStatus>((ref) {
  return TrialService.init();
});
