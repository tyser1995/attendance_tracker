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

    excel.delete('Sheet1');

    final sheet = excel['Attendance'];
    _exRow(sheet, 0, ['Date', 'Student ID', 'Student Name', 'Status', 'Time In', 'Time Out']);
    for (int i = 0; i < logs.length; i++) {
      final l = logs[i];
      _exRow(sheet, i + 1, [l.createdDate, l.idNumber, l.name, l.statusLabel, l.timeIn ?? '', l.timeOut ?? '']);
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

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => _pdfHeader(from, to),
        footer: (ctx) => _pdfFooter(ctx),
        build: (ctx) => [_pdfRecordsTable(logs)],
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

  static pw.Widget _pdfRecordsTable(List<AttendanceRecord> logs) {
    if (logs.isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Attendance Records', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F1F5F9')),
              children: [
                _pdfCell('Date', bold: true),
                _pdfCell('Student ID', bold: true),
                _pdfCell('Student Name', bold: true),
                _pdfCell('Status', bold: true),
                _pdfCell('Time In', bold: true),
                _pdfCell('Time Out', bold: true),
              ],
            ),
            ...logs.asMap().entries.map((entry) {
              final i = entry.key;
              final l = entry.value;
              return pw.TableRow(
                decoration: i.isEven ? null : pw.BoxDecoration(color: PdfColor.fromHex('F8FAFC')),
                children: [
                  _pdfCell(l.createdDate),
                  _pdfCell(l.idNumber),
                  _pdfCell(l.name),
                  _pdfCell(l.statusLabel),
                  _pdfCell(l.timeIn ?? ''),
                  _pdfCell(l.timeOut ?? ''),
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
