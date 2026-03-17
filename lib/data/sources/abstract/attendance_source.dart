import '../../../models/attendance_record.dart';

abstract class AttendanceSource {
  /// Log a time entry (auto-detects next status 1–4)
  /// Returns result with success/message
  Future<AttendanceLogResult> log(String idNumber);

  /// Get all attendance records for a specific date
  Future<List<AttendanceRecord>> getByDate(String date);

  /// Get all records for a student
  Future<List<AttendanceRecord>> getByStudent(String idNumber);

  /// Get today's last log for a student
  Future<AttendanceRecord?> getTodayLastLog(String idNumber);

  /// Get date range records
  Future<List<AttendanceRecord>> getByDateRange(String from, String to);

  /// Delete a record
  Future<void> delete(String id);

  /// Get today's summary count
  Future<Map<String, int>> getTodaySummary();
}

class AttendanceLogResult {
  final bool success;
  final String message;
  final AttendanceRecord? record;

  const AttendanceLogResult({
    required this.success,
    required this.message,
    this.record,
  });
}
