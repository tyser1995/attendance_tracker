import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import 'download.dart';

class ReportExporter {
  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _slug(DateTime from, DateTime to) =>
      'attendance_${_fmt(from)}_${_fmt(to)}';

  // ─── CSV ────────────────────────────────────────────────────────────────────
  static void exportCsv(
    List<AttendanceRecord> logs,
    List<Student> students,
    DateTime from,
    DateTime to,
  ) {
    final buf = StringBuffer();
    buf.writeln('Date Range:,${_fmt(from)} to ${_fmt(to)}');
    buf.writeln('Generated:,${DateTime.now().toIso8601String()}');
    buf.writeln();

    // Section 1: summary
    final uniqueStudents = {for (final l in logs) l.idNumber}.length;
    final byDate = <String, Set<String>>{};
    for (final l in logs) { byDate.putIfAbsent(l.createdDate, () => {}).add(l.idNumber); }
    buf.writeln('Summary');
    buf.writeln('Total Logs,Unique Students,Total Days');
    buf.writeln('${logs.length},$uniqueStudents,${byDate.length}');
    buf.writeln();

    // Section 2: all records
    buf.writeln('Attendance Records');
    buf.writeln('Date,Student ID,Student Name,Status,Time In,Time Out');
    for (final l in logs) {
      buf.writeln(
        '${l.createdDate},${l.idNumber},"${l.name}",${l.statusLabel},${l.timeIn ?? ''},${l.timeOut ?? ''}',
      );
    }

    final bytes = Uint8List.fromList(buf.toString().codeUnits);
    downloadBytes(bytes, '${_slug(from, to)}.csv', 'text/csv');
  }

  // ─── EXCEL ──────────────────────────────────────────────────────────────────
  static void exportExcel(
    List<AttendanceRecord> logs,
    List<Student> students,
    DateTime from,
    DateTime to,
  ) {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    // ── Sheet 1: Summary ──
    final summary = excel['Summary'];
    _exRow(summary, 0, ['Attendance Report', '${_fmt(from)}  →  ${_fmt(to)}']);
    _exRow(summary, 2, ['Metric', 'Value']);
    final uniqueStudents = {for (final l in logs) l.idNumber}.length;
    final byDate = <String, Set<String>>{};
    for (final l in logs) { byDate.putIfAbsent(l.createdDate, () => {}).add(l.idNumber); }
    _exRow(summary, 3, ['Total Logs', logs.length]);
    _exRow(summary, 4, ['Unique Students', uniqueStudents]);
    _exRow(summary, 5, ['Total Days', byDate.length]);

    // ── Sheet 2: Daily Breakdown ──
    final daily = excel['Daily'];
    _exRow(daily, 0, ['Date', 'Day', 'Students Present']);
    final keys = byDate.keys.toList()..sort();
    for (int i = 0; i < keys.length; i++) {
      final d = DateTime.tryParse(keys[i]);
      final dayName = d != null ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1] : '';
      _exRow(daily, i + 1, [keys[i], dayName, byDate[keys[i]]!.length]);
    }

    // ── Sheet 3: Student Summary ──
    final studentSheet = excel['Students'];
    _exRow(studentSheet, 0, ['#', 'Student Name', 'ID Number', 'Total Logs']);
    final studentDays = <String, int>{};
    for (final l in logs) { studentDays[l.idNumber] = (studentDays[l.idNumber] ?? 0) + 1; }
    final sorted = studentDays.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (int i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final stu = students.cast<Student?>().firstWhere((s) => s?.idNumber == e.key, orElse: () => null);
      _exRow(studentSheet, i + 1, [i + 1, stu?.fullName ?? e.key, e.key, e.value]);
    }

    // ── Sheet 4: Full Detail ──
    final detail = excel['Detail'];
    _exRow(detail, 0, ['Date', 'Student ID', 'Student Name', 'Status', 'Time In', 'Time Out']);
    for (int i = 0; i < logs.length; i++) {
      final l = logs[i];
      _exRow(detail, i + 1, [l.createdDate, l.idNumber, l.name, l.statusLabel, l.timeIn ?? '', l.timeOut ?? '']);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    downloadBytes(Uint8List.fromList(bytes), '${_slug(from, to)}.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  static void _exRow(Sheet sheet, int row, List<dynamic> values) {
    for (int col = 0; col < values.length; col++) {
      final v = values[col];
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      if (v is int) {
        cell.value = IntCellValue(v);
      } else {
        cell.value = TextCellValue(v.toString());
      }
    }
  }

  // ─── PDF ────────────────────────────────────────────────────────────────────
  static Future<void> exportPdf(
    BuildContext context,
    List<AttendanceRecord> logs,
    List<Student> students,
    DateTime from,
    DateTime to,
  ) async {
    final doc = pw.Document();
    final byDate = <String, Set<String>>{};
    for (final l in logs) { byDate.putIfAbsent(l.createdDate, () => {}).add(l.idNumber); }
    final uniqueStudents = {for (final l in logs) l.idNumber}.length;

    final studentDays = <String, int>{};
    for (final l in logs) { studentDays[l.idNumber] = (studentDays[l.idNumber] ?? 0) + 1; }
    final sorted = studentDays.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final dateKeys = byDate.keys.toList()..sort();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => _pdfHeader(from, to),
        footer: (ctx) => _pdfFooter(ctx),
        build: (ctx) => [
          _pdfSummary(logs.length, uniqueStudents, byDate.length),
          pw.SizedBox(height: 20),
          _pdfDailyTable(dateKeys, byDate),
          pw.SizedBox(height: 20),
          _pdfStudentTable(sorted, students),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${_slug(from, to)}.pdf',
    );
  }

  static pw.Widget _pdfHeader(DateTime from, DateTime to) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Attendance Report',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('6366F1'))),
              pw.Text('${_fmt(from)}  –  ${_fmt(to)}',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ],
          ),
          pw.Divider(color: PdfColor.fromHex('6366F1'), thickness: 1.5),
          pw.SizedBox(height: 4),
        ],
      );

  static pw.Widget _pdfFooter(pw.Context ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated ${DateTime.now().toIso8601String().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ],
      );

  static pw.Widget _pdfSummary(int totalLogs, int students, int days) {
    return pw.Row(
      children: [
        _pdfSummCard('Total Logs', '$totalLogs', PdfColor.fromHex('6366F1')),
        pw.SizedBox(width: 12),
        _pdfSummCard('Students', '$students', PdfColor.fromHex('22C55E')),
        pw.SizedBox(width: 12),
        _pdfSummCard('Days', '$days', PdfColor.fromHex('F59E0B')),
      ],
    );
  }

  static pw.Widget _pdfSummCard(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor(color.red, color.green, color.blue, 0.08),
            border: pw.Border.all(color: PdfColor(color.red, color.green, color.blue, 0.3)),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
              pw.SizedBox(height: 4),
              pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

  static pw.Widget _pdfDailyTable(List<String> dateKeys, Map<String, Set<String>> byDate) {
    if (dateKeys.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Daily Attendance', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
              children: [
                _pdfCell('Date', bold: true),
                _pdfCell('Day', bold: true),
                _pdfCell('Present', bold: true),
              ],
            ),
            ...dateKeys.map((k) {
              final d = DateTime.tryParse(k);
              final dayName = d != null ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1] : '';
              return pw.TableRow(children: [
                _pdfCell(k),
                _pdfCell(dayName),
                _pdfCell('${byDate[k]!.length}'),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfStudentTable(
    List<MapEntry<String, int>> sorted,
    List<Student> students,
  ) {
    if (sorted.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Student Attendance Summary', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FixedColumnWidth(42),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
              children: [
                _pdfCell('#', bold: true),
                _pdfCell('Name', bold: true),
                _pdfCell('ID Number', bold: true),
                _pdfCell('Logs', bold: true),
              ],
            ),
            ...sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final stu = students.cast<Student?>().firstWhere((s) => s?.idNumber == e.key, orElse: () => null);
              return pw.TableRow(
                decoration: i.isEven ? null : pw.BoxDecoration(color: PdfColor.fromHex('F8FAFC')),
                children: [
                  _pdfCell('${i + 1}'),
                  _pdfCell(stu?.fullName ?? e.key),
                  _pdfCell(e.key),
                  _pdfCell('${e.value}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      );
}
