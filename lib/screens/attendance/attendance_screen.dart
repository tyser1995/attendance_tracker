import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/attendance_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = AppUtils.toDateStr(selectedDate);
    final logsAsync = ref.watch(attendanceByDateProvider(dateStr));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () => ref.read(selectedDateProvider.notifier).state = DateTime.now(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(attendanceRefreshProvider.notifier).state++,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: selectedDate,
              selectedDayPredicate: (d) => isSameDay(d, selectedDate),
              calendarFormat: CalendarFormat.week,
              onDaySelected: (sel, _) =>
                  ref.read(selectedDateProvider.notifier).state = sel,
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                todayTextStyle: const TextStyle(color: AppTheme.primary),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
          ),
          const Divider(height: 1),

          // Summary strip
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: logsAsync.when(
              loading: () => const SizedBox(height: 32),
              error: (_, _) => const SizedBox.shrink(),
              data: (logs) {
                final ids = <String>{};
                int am = 0, pm = 0;
                for (final l in logs) {
                  ids.add(l.idNumber);
                  if (l.status == 1 || l.status == 2) am++;
                  if (l.status == 3 || l.status == 4) pm++;
                }
                return Row(
                  children: [
                    _Strip('Students', '${ids.length}', AppTheme.primary),
                    _Strip('AM Logs', '$am', AppTheme.warning),
                    _Strip('PM Logs', '$pm', AppTheme.info),
                    _Strip('Total Logs', '${logs.length}', AppTheme.success),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (logs) => logs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note_rounded, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text('No records for this date', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _LogTile(log: logs[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Strip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      );
}

class _LogTile extends StatelessWidget {
  final dynamic log;
  const _LogTile({required this.log});

  Color _color(int s) {
    switch (s) {
      case 1: return AppTheme.success;
      case 2: return AppTheme.warning;
      case 3: return AppTheme.success;
      case 4: return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(log.status as int);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(AppUtils.statusLabel(log.status as int),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.name as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(log.idNumber as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (log.timeIn != null)
                Text(AppUtils.formatTime(log.timeIn), style: const TextStyle(fontSize: 12)),
              if (log.timeOut != null)
                Text(AppUtils.formatTime(log.timeOut), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
