import 'dart:convert';
import 'dart:typed_data';

import '../data/local/sembast_helper.dart';
import 'download.dart';
import 'file_picker.dart';
import 'package:sembast/sembast.dart';

class BackupResult {
  final bool success;
  final String message;
  const BackupResult({required this.success, required this.message});
}

class BackupManager {
  // ── Full JSON Backup Export ─────────────────────────────────────────────────

  static Future<void> exportBackup() async {
    final db = await SembastHelper.instance.database;

    final students = await studentsStore.find(db);
    final courses = await coursesStore.find(db);
    final attendances = await attendancesStore.find(db);
    final idPatterns = await idPatternsStore.find(db);

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'students': {for (final r in students) r.key: r.value},
      'courses': {for (final r in courses) r.key: r.value},
      'attendances': {for (final r in attendances) r.key: r.value},
      'id_patterns': {for (final r in idPatterns) r.key: r.value},
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final date = DateTime.now().toIso8601String().substring(0, 10);
    downloadBytes(bytes, 'attendance_backup_$date.json', 'application/json');
  }

  // ── Full JSON Backup Import ─────────────────────────────────────────────────

  static Future<BackupResult> importBackup() async {
    final file = await pickTextFile(accept: '.json');
    if (file == null) {
      return const BackupResult(success: false, message: 'No file selected.');
    }

    try {
      final data = jsonDecode(file.content) as Map<String, dynamic>;
      final db = await SembastHelper.instance.database;
      int count = 0;

      final students = data['students'] as Map<String, dynamic>? ?? {};
      for (final entry in students.entries) {
        await studentsStore
            .record(entry.key)
            .put(db, Map<String, Object?>.from(entry.value as Map));
        count++;
      }

      final courses = data['courses'] as Map<String, dynamic>? ?? {};
      for (final entry in courses.entries) {
        await coursesStore
            .record(entry.key)
            .put(db, Map<String, Object?>.from(entry.value as Map));
        count++;
      }

      final attendances = data['attendances'] as Map<String, dynamic>? ?? {};
      for (final entry in attendances.entries) {
        await attendancesStore
            .record(entry.key)
            .put(db, Map<String, Object?>.from(entry.value as Map));
        count++;
      }

      final idPatterns = data['id_patterns'] as Map<String, dynamic>? ?? {};
      for (final entry in idPatterns.entries) {
        await idPatternsStore
            .record(entry.key)
            .put(db, Map<String, Object?>.from(entry.value as Map));
        count++;
      }

      return BackupResult(
          success: true, message: 'Restored $count records successfully.');
    } catch (e) {
      return BackupResult(success: false, message: 'Import failed: $e');
    }
  }

  // ── CSV Attendance Import ───────────────────────────────────────────────────
  // Compatible with the CSV format produced by ReportExporter.exportCsv()

  static Future<BackupResult> importCsv() async {
    final file = await pickTextFile(accept: '.csv');
    if (file == null) {
      return const BackupResult(success: false, message: 'No file selected.');
    }

    try {
      final db = await SembastHelper.instance.database;
      final lines = const LineSplitter().convert(file.content);

      // Locate "Attendance Records" section header
      int dataStart = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trim() == 'Attendance Records') {
          dataStart = i + 2; // skip column header row
          break;
        }
      }

      if (dataStart == -1 || dataStart >= lines.length) {
        return const BackupResult(
            success: false,
            message:
                'Invalid CSV format: could not find "Attendance Records" section.');
      }

      int imported = 0;
      int skipped = 0;

      for (int i = dataStart; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = _parseCsvLine(line);
        if (cols.length < 4) continue;

        // Columns: Date, Student ID, Student Name, Status, Time In, Time Out
        final date = cols[0];
        final idNumber = cols[1];
        final name = cols[2];
        final statusLabel = cols[3];
        final timeIn =
            cols.length > 4 && cols[4].isNotEmpty ? cols[4] : null;
        final timeOut =
            cols.length > 5 && cols[5].isNotEmpty ? cols[5] : null;

        final status = _statusFromLabel(statusLabel);
        if (status == 0) continue;

        // Skip duplicates
        final existing = await attendancesStore.findFirst(db,
            finder: Finder(
                filter: Filter.and([
              Filter.equals('idnumber', idNumber),
              Filter.equals('created_date', date),
              Filter.equals('status', status),
            ])));
        if (existing != null) {
          skipped++;
          continue;
        }

        final recordId = '${idNumber}_${date}_$status';
        final now = DateTime.now().toIso8601String();
        await attendancesStore.record(recordId).put(db, {
          'idnumber': idNumber,
          'name': name,
          'time_in': timeIn,
          'time_out': timeOut,
          'created_date': date,
          'status': status,
          'created_at': now,
          'updated_at': now,
        });
        imported++;
      }

      final msg = skipped > 0
          ? 'Imported $imported records. Skipped $skipped duplicates.'
          : 'Imported $imported attendance records.';
      return BackupResult(success: true, message: msg);
    } catch (e) {
      return BackupResult(success: false, message: 'CSV import failed: $e');
    }
  }

  static int _statusFromLabel(String label) {
    switch (label.trim()) {
      case 'AM Time In':
        return 1;
      case 'AM Time Out':
        return 2;
      case 'PM Time In':
        return 3;
      case 'PM Time Out':
        return 4;
      default:
        return 0;
    }
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if (c == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    result.add(current.toString());
    return result;
  }
}
