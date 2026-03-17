import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/report_exporter.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/attendance_record.dart';
import '../../models/student.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';

final _fromDateProvider = StateProvider<DateTime>((ref) =>
    DateTime.now().subtract(const Duration(days: 6)));
final _toDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = ref.watch(_fromDateProvider);
    final to = ref.watch(_toDateProvider);
    final fromStr = AppUtils.toDateStr(from);
    final toStr = AppUtils.toDateStr(to);

    final logsAsync = ref.watch(
      FutureProvider((ref) {
        ref.watch(attendanceRefreshProvider);
        return ref.read(attendanceSourceProvider).getByDateRange(fromStr, toStr);
      }).future,
    );

    final studentsAsync = ref.watch(allStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(attendanceRefreshProvider.notifier).state++,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range picker
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateBtn(
                      label: 'From',
                      date: from,
                      onChanged: (d) => ref.read(_fromDateProvider.notifier).state = d,
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
                  Expanded(
                    child: _DateBtn(
                      label: 'To',
                      date: to,
                      onChanged: (d) => ref.read(_toDateProvider.notifier).state = d,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          switch (logsAsync) {
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
            AsyncError(:final error) => Text('Error: $error'),
            AsyncData(:final value) => _ReportBody(
                logs: value,
                students: studentsAsync.valueOrNull ?? [],
                from: from,
                to: to,
              ),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _ReportBody extends StatefulWidget {
  final List<AttendanceRecord> logs;
  final List<Student> students;
  final DateTime from;
  final DateTime to;

  const _ReportBody({
    required this.logs,
    required this.students,
    required this.from,
    required this.to,
  });

  @override
  State<_ReportBody> createState() => _ReportBodyState();
}

class _ReportBodyState extends State<_ReportBody> {
  bool _exporting = false;

  Future<void> _export(String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      switch (format) {
        case 'csv':
          ReportExporter.exportCsv(widget.logs, widget.students, widget.from, widget.to);
        case 'xlsx':
          ReportExporter.exportExcel(widget.logs, widget.students, widget.from, widget.to);
        case 'pdf':
          await ReportExporter.exportPdf(context, widget.logs, widget.students, widget.from, widget.to);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    final students = widget.students;

    // Group by date → distinct students
    final Map<String, Set<String>> byDate = {};
    for (final l in logs) {
      byDate.putIfAbsent(l.createdDate, () => {}).add(l.idNumber);
    }

    // Per-student totals
    final Map<String, int> studentDays = {};
    for (final l in logs) {
      final key = l.idNumber;
      studentDays[key] = (studentDays[key] ?? 0) + 1;
    }

    final totalLogs = logs.length;
    final uniqueStudents = {for (final l in logs) l.idNumber}.length;
    final totalDays = byDate.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Export buttons
        if (logs.isNotEmpty) ...[
          Row(
            children: [
              const Text('Export', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 10),
              if (_exporting)
                const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else ...[
                _ExportBtn(label: 'CSV', icon: Icons.table_rows_rounded, color: AppTheme.success, onTap: () => _export('csv')),
                const SizedBox(width: 8),
                _ExportBtn(label: 'Excel', icon: Icons.grid_on_rounded, color: const Color(0xFF217346), onTap: () => _export('xlsx')),
                const SizedBox(width: 8),
                _ExportBtn(label: 'PDF', icon: Icons.picture_as_pdf_rounded, color: AppTheme.danger, onTap: () => _export('pdf')),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Summary
        Row(
          children: [
            _SummTile('Total Logs', '$totalLogs', AppTheme.primary),
            const SizedBox(width: 10),
            _SummTile('Students', '$uniqueStudents', AppTheme.success),
            const SizedBox(width: 10),
            _SummTile('Days', '$totalDays', AppTheme.warning),
          ],
        ),
        const SizedBox(height: 16),

        // Daily bar chart
        if (byDate.isNotEmpty) ...[
          const Text('Daily Attendance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 180,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (students.length + 1).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (g, gi, rod, ri) => BarTooltipItem('${rod.toY.round()}', const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final keys = byDate.keys.toList()..sort();
                        final idx = v.toInt();
                        if (idx < 0 || idx >= keys.length) return const SizedBox();
                        final d = DateTime.tryParse(keys[idx]);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(d != null ? AppUtils.dayOfWeek(d) : '', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        );
                      },
                    )),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: () {
                    final keys = byDate.keys.toList()..sort();
                    return keys.asMap().entries.map((e) => BarChartGroupData(
                      x: e.key,
                      barRods: [BarChartRodData(
                        toY: byDate[e.value]!.length.toDouble(),
                        color: AppTheme.primary,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )],
                    )).toList();
                  }(),
                )),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Per-student table
        const Text('Student Attendance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
                    Expanded(child: Text('ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
                    Expanded(child: Text('Logs', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary))),
                  ],
                ),
              ),
              if (studentDays.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No data for selected range', style: TextStyle(color: AppTheme.textSecondary)),
                )
              else
                ...studentDays.entries.map((e) {
                  final student = students.cast<dynamic>().where((s) => s.idNumber == e.key).firstOrNull;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(student?.fullName ?? e.key, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                        Expanded(child: Text(e.key, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                        Expanded(child: Text('${e.value}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary))),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
}

class _ExportBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ExportBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label, style: TextStyle(fontSize: 12, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const _DateBtn({required this.label, required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
      child: Text('$label: ${AppUtils.formatDateFromDt(date)}', style: const TextStyle(fontSize: 12)),
    );
  }
}
