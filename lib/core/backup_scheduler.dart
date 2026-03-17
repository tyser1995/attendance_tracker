import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_manager.dart';

const _kScheduleKey = 'backup_schedule_times'; // JSON list of "HH:mm" strings
const _kLastFiredKey = 'backup_last_fired'; // JSON map {"HH:mm": "YYYY-MM-DD"}

// Notifier that emits a message each time an auto-backup fires (or fails).
// ShellScreen listens to this and shows a SnackBar.
final backupEventProvider = StateProvider<String?>((ref) => null);

class BackupScheduleNotifier extends AsyncNotifier<List<String>> {
  Timer? _timer;

  @override
  Future<List<String>> build() async {
    final times = await _loadTimes();
    _startTimer();
    ref.onDispose(() => _timer?.cancel());
    return times;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> addTime(String hhmm) async {
    final current = List<String>.from(state.valueOrNull ?? []);
    if (current.contains(hhmm)) return;
    current
      ..add(hhmm)
      ..sort();
    await _saveTimes(current);
    state = AsyncValue.data(current);
  }

  Future<void> removeTime(String hhmm) async {
    final updated =
        (state.valueOrNull ?? []).where((t) => t != hhmm).toList();
    await _saveTimes(updated);
    state = AsyncValue.data(updated);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    // Check every 30 seconds so we never miss a scheduled minute.
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => _checkAndBackup());
  }

  Future<void> _checkAndBackup() async {
    final times = state.valueOrNull ?? [];
    if (times.isEmpty) return;

    final now = DateTime.now();
    final hhmm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!times.contains(hhmm)) return;

    // Avoid duplicate trigger within the same minute/day
    final prefs = await SharedPreferences.getInstance();
    final lastFired = Map<String, String>.from(
        jsonDecode(prefs.getString(_kLastFiredKey) ?? '{}'));
    if (lastFired[hhmm] == today) return;

    lastFired[hhmm] = today;
    await prefs.setString(_kLastFiredKey, jsonEncode(lastFired));

    try {
      await BackupManager.exportBackup();
      ref.read(backupEventProvider.notifier).state =
          'Auto-backup downloaded at $hhmm';
    } catch (e) {
      ref.read(backupEventProvider.notifier).state =
          'Auto-backup failed at $hhmm: $e';
    }
  }

  Future<List<String>> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScheduleKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List)..sort();
  }

  Future<void> _saveTimes(List<String> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kScheduleKey, jsonEncode(times));
  }
}

final backupScheduleProvider =
    AsyncNotifierProvider<BackupScheduleNotifier, List<String>>(
        BackupScheduleNotifier.new);
