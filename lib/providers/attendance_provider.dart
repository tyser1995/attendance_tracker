import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/abstract/attendance_source.dart';
import '../data/sources/local/local_attendance_source.dart';
import '../data/sources/remote/remote_attendance_source.dart';
import '../models/attendance_record.dart';
import 'db_config_provider.dart';

final attendanceSourceProvider = Provider<AttendanceSource>((ref) {
  final useRemote = ref.watch(useRemoteDbProvider);
  return useRemote ? RemoteAttendanceSource() : LocalAttendanceSource();
});

final attendanceRefreshProvider = StateProvider<int>((ref) => 0);

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final attendanceByDateProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, date) async {
  ref.watch(attendanceRefreshProvider);
  return ref.read(attendanceSourceProvider).getByDate(date);
});

final attendanceByStudentProvider =
    FutureProvider.family<List<AttendanceRecord>, String>((ref, idNumber) async {
  ref.watch(attendanceRefreshProvider);
  return ref.read(attendanceSourceProvider).getByStudent(idNumber);
});

final todaySummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(attendanceRefreshProvider);
  return ref.read(attendanceSourceProvider).getTodaySummary();
});

// Scanner notifier
class ScannerNotifier extends Notifier<AttendanceScanState> {
  @override
  AttendanceScanState build() => const AttendanceScanState.idle();

  Future<void> log(String idNumber) async {
    state = const AttendanceScanState.loading();
    try {
      final src = ref.read(attendanceSourceProvider);
      final result = await src.log(idNumber);
      if (result.success) {
        ref.read(attendanceRefreshProvider.notifier).state++;
        state = AttendanceScanState.success(result.message, result.record);
      } else {
        state = AttendanceScanState.error(result.message);
      }
    } catch (e) {
      state = AttendanceScanState.error('Error: $e');
    }
  }

  void reset() => state = const AttendanceScanState.idle();
}

final scannerProvider =
    NotifierProvider<ScannerNotifier, AttendanceScanState>(ScannerNotifier.new);

class AttendanceScanState {
  final ScanStatus status;
  final String? message;
  final AttendanceRecord? record;

  const AttendanceScanState._(this.status, this.message, this.record);

  const AttendanceScanState.idle()
      : this._(ScanStatus.idle, null, null);
  const AttendanceScanState.loading()
      : this._(ScanStatus.loading, null, null);
  const AttendanceScanState.success(String msg, AttendanceRecord? rec)
      : this._(ScanStatus.success, msg, rec);
  const AttendanceScanState.error(String msg)
      : this._(ScanStatus.error, msg, null);
}

enum ScanStatus { idle, loading, success, error }
