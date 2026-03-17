import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../../../models/attendance_record.dart';
import '../../../models/id_pattern.dart';
import '../../../models/student.dart';
import '../../local/sembast_helper.dart';
import '../abstract/attendance_source.dart';

class LocalAttendanceSource implements AttendanceSource {
  final _helper = SembastHelper.instance;
  static const _uuid = Uuid();

  Future<Database> get _db async => _helper.database;

  @override
  Future<AttendanceLogResult> log(String idNumber) async {
    final db = await _db;

    // 1. Validate active patterns
    final patternRecs = await idPatternsStore.find(db,
        finder: Finder(filter: Filter.equals('status', 'active')));
    if (patternRecs.isNotEmpty) {
      final patterns = patternRecs
          .map((r) => IdPattern.fromMap({...r.value, 'id': r.key}))
          .toList();
      if (!patterns.any((p) => p.validate(idNumber))) {
        return AttendanceLogResult(
          success: false,
          message: "❌ ID '$idNumber' does not match any allowed pattern.",
        );
      }
    }

    // 2. Verify student
    final studentRec = await studentsStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('idnumber', idNumber),
          Filter.equals('is_deleted', 0),
        ])));
    if (studentRec == null) {
      return AttendanceLogResult(
        success: false,
        message: "❌ No student found with ID '$idNumber'.",
      );
    }
    final student = Student.fromMap({...studentRec.value, 'id': studentRec.key});
    final today = _todayStr();

    // 3. Get last log today
    final todayRecs = await attendancesStore.find(db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('idnumber', idNumber),
            Filter.equals('created_date', today),
          ]),
          sortOrders: [SortOrder('updated_at', false)],
          limit: 1,
        ));

    final lastStatus = todayRecs.isEmpty ? 0 : todayRecs.first.value['status'] as int;
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
      final map = <String, Object?>{
        'id': id, 'idnumber': idNumber, 'name': student.fullName,
        'time_in': timeNow, 'time_out': null,
        'created_date': today, 'status': nextStatus, 'created_at': now, 'updated_at': now,
      };
      await attendancesStore.record(id).put(db, map);
      record = AttendanceRecord.fromMap(map);
    } else {
      final lastRec = todayRecs.first;
      final updated = <String, Object?>{'status': nextStatus, 'time_out': timeNow, 'updated_at': now};
      await attendancesStore.record(lastRec.key).update(db, updated);
      final merged = {...lastRec.value, ...updated, 'id': lastRec.key};
      record = AttendanceRecord.fromMap(merged);
    }

    return AttendanceLogResult(
      success: true,
      message: '✅ ${student.fullName} — $statusText recorded.',
      record: record,
    );
  }

  @override
  Future<List<AttendanceRecord>> getByDate(String date) async {
    final db = await _db;
    final records = await attendancesStore.find(db,
        finder: Finder(
          filter: Filter.equals('created_date', date),
          sortOrders: [SortOrder('updated_at', false)],
        ));
    return records
        .map((r) => AttendanceRecord.fromMap({...r.value, 'id': r.key}))
        .toList();
  }

  @override
  Future<List<AttendanceRecord>> getByStudent(String idNumber) async {
    final db = await _db;
    final records = await attendancesStore.find(db,
        finder: Finder(
          filter: Filter.equals('idnumber', idNumber),
          sortOrders: [SortOrder('created_date', false), SortOrder('updated_at', false)],
        ));
    return records
        .map((r) => AttendanceRecord.fromMap({...r.value, 'id': r.key}))
        .toList();
  }

  @override
  Future<AttendanceRecord?> getTodayLastLog(String idNumber) async {
    final db = await _db;
    final record = await attendancesStore.findFirst(db,
        finder: Finder(
          filter: Filter.and([
            Filter.equals('idnumber', idNumber),
            Filter.equals('created_date', _todayStr()),
          ]),
          sortOrders: [SortOrder('updated_at', false)],
        ));
    if (record == null) return null;
    return AttendanceRecord.fromMap({...record.value, 'id': record.key});
  }

  @override
  Future<List<AttendanceRecord>> getByDateRange(String from, String to) async {
    final db = await _db;
    final records = await attendancesStore.find(db,
        finder: Finder(
          filter: Filter.and([
            Filter.greaterThanOrEquals('created_date', from),
            Filter.lessThanOrEquals('created_date', to),
          ]),
          sortOrders: [SortOrder('created_date', false), SortOrder('updated_at', false)],
        ));
    return records
        .map((r) => AttendanceRecord.fromMap({...r.value, 'id': r.key}))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await attendancesStore.record(id).delete(db);
  }

  @override
  Future<Map<String, int>> getTodaySummary() async {
    final db = await _db;
    final today = _todayStr();
    final records = await attendancesStore.find(db,
        finder: Finder(filter: Filter.equals('created_date', today)));

    final idNums = <String>{};
    final amIds = <String>{};
    final pmIds = <String>{};
    for (final r in records) {
      final id = r.value['idnumber'] as String;
      idNums.add(id);
      final status = r.value['status'] as int;
      if (status == 1 || status == 2) amIds.add(id);
      if (status == 3 || status == 4) pmIds.add(id);
    }

    final total = await studentsStore.count(db,
        filter: Filter.equals('is_deleted', 0));

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
