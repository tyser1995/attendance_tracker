import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/attendance_record.dart';
import '../../../models/id_pattern.dart';
import '../abstract/attendance_source.dart';

class RemoteAttendanceSource implements AttendanceSource {
  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  @override
  Future<AttendanceLogResult> log(String idNumber) async {
    // 1. Validate patterns
    final patternRows = await _client
        .from('id_patterns')
        .select()
        .eq('status', 'active');
    final patterns = (patternRows as List).map((e) => IdPattern.fromMap(e as Map<String, dynamic>)).toList();

    if (patterns.isNotEmpty) {
      final isValid = patterns.any((p) => p.validate(idNumber));
      if (!isValid) {
        return AttendanceLogResult(
          success: false,
          message: "❌ ID '$idNumber' does not match any allowed pattern.",
        );
      }
    }

    // 2. Find student
    final studentRows = await _client
        .from('students')
        .select()
        .eq('idnumber', idNumber)
        .eq('is_deleted', false);
    if ((studentRows as List).isEmpty) {
      return AttendanceLogResult(
        success: false,
        message: "❌ No student found with ID '$idNumber'.",
      );
    }
    final student = studentRows.first;
    final studentName = '${student['fn']} ${student['ln']}';
    final today = _todayStr();

    // 3. Get last log today
    final lastLogs = await _client
        .from('attendances')
        .select()
        .eq('idnumber', idNumber)
        .eq('created_date', today)
        .order('id', ascending: false)
        .limit(1);

    final lastStatus =
        (lastLogs as List).isEmpty ? 0 : lastLogs.first['status'] as int;
    final nextStatus = lastStatus + 1;

    if (nextStatus > 4) {
      return AttendanceLogResult(
        success: false,
        message: '⚠ Already completed 4 logs for today.',
      );
    }

    final statusText = switch (nextStatus) {
      1 => 'AM Time In',
      2 => 'AM Time Out',
      3 => 'PM Time In',
      4 => 'PM Time Out',
      _ => 'Unknown',
    };

    final timeNow = _timeNowStr();
    final now = DateTime.now().toIso8601String();
    AttendanceRecord record;

    if (nextStatus == 1 || nextStatus == 3) {
      final id = _uuid.v4();
      final map = {
        'id': id,
        'idnumber': idNumber,
        'name': studentName,
        'time_in': timeNow,
        'time_out': null,
        'created_date': today,
        'status': nextStatus,
        'created_at': now,
      };
      await _client.from('attendances').insert(map);
      record = AttendanceRecord.fromMap(map);
    } else {
      final lastRecord = AttendanceRecord.fromMap(lastLogs.first);
      await _client.from('attendances').update({
        'status': nextStatus,
        'time_out': timeNow,
      }).eq('id', lastRecord.id);
      record = AttendanceRecord(
        id: lastRecord.id,
        idNumber: lastRecord.idNumber,
        name: lastRecord.name,
        timeIn: lastRecord.timeIn,
        timeOut: timeNow,
        createdDate: today,
        status: nextStatus,
        createdAt: lastRecord.createdAt,
      );
    }

    return AttendanceLogResult(
      success: true,
      message: '✅ $studentName — $statusText recorded.',
      record: record,
    );
  }

  @override
  Future<List<AttendanceRecord>> getByDate(String date) async {
    final rows = await _client
        .from('attendances')
        .select()
        .eq('created_date', date)
        .order('created_at');
    return (rows as List).map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getByStudent(String idNumber) async {
    final rows = await _client
        .from('attendances')
        .select()
        .eq('idnumber', idNumber)
        .order('created_date', ascending: false);
    return (rows as List).map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AttendanceRecord?> getTodayLastLog(String idNumber) async {
    final rows = await _client
        .from('attendances')
        .select()
        .eq('idnumber', idNumber)
        .eq('created_date', _todayStr())
        .order('id', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : AttendanceRecord.fromMap(list.first);
  }

  @override
  Future<List<AttendanceRecord>> getByDateRange(String from, String to) async {
    final rows = await _client
        .from('attendances')
        .select()
        .gte('created_date', from)
        .lte('created_date', to)
        .order('created_date', ascending: false);
    return (rows as List).map((e) => AttendanceRecord.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('attendances').delete().eq('id', id);
  }

  @override
  Future<Map<String, int>> getTodaySummary() async {
    final today = _todayStr();
    final rows = await _client
        .from('attendances')
        .select('idnumber, status')
        .eq('created_date', today);
    final list = rows as List;

    final idNums = <String>{};
    final amIds = <String>{};
    final pmIds = <String>{};
    for (final r in list) {
      final id = r['idnumber'] as String;
      idNums.add(id);
      final status = r['status'] as int;
      if (status == 1 || status == 2) amIds.add(id);
      if (status == 3 || status == 4) pmIds.add(id);
    }

    final totalRows = await _client
        .from('students')
        .select('id')
        .eq('is_deleted', false);
    final total = (totalRows as List).length;

    return {
      'present': idNums.length,
      'absent': (total - idNums.length).clamp(0, total),
      'am': amIds.length,
      'pm': pmIds.length,
      'total': total,
    };
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _timeNowStr() {
    final d = DateTime.now();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }
}
