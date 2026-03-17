import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/db_config_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    final useRemote = ref.watch(useRemoteDbProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(AppUtils.formatDateFromDt(DateTime.now()),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(useRemote ? Icons.cloud_rounded : Icons.storage_rounded,
                  size: 14, color: useRemote ? AppTheme.info : AppTheme.success),
              label: Text(useRemote ? 'Supabase' : 'SQLite',
                  style: const TextStyle(fontSize: 11)),
              backgroundColor: (useRemote ? AppTheme.info : AppTheme.success).withValues(alpha: 0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(attendanceRefreshProvider.notifier).state++,
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (summary) => _Body(summary: summary),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final Map<String, int> summary;
  const _Body({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final present = summary['present'] ?? 0;
    final absent = summary['absent'] ?? 0;
    final am = summary['am'] ?? 0;
    final pm = summary['pm'] ?? 0;
    final total = summary['total'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero scanner button
        GestureDetector(
          onTap: () => context.go('/scanner'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time Log', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('Tap to record attendance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const _SectionTitle('Today\'s Summary'),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(label: 'Present', value: '$present', color: AppTheme.success, icon: Icons.check_circle_rounded, onTap: () => context.go('/attendance')),
            const SizedBox(width: 10),
            _StatCard(label: 'Absent', value: '$absent', color: AppTheme.danger, icon: Icons.cancel_rounded, onTap: () => context.go('/attendance')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(label: 'AM Session', value: '$am', color: AppTheme.warning, icon: Icons.wb_sunny_rounded),
            const SizedBox(width: 10),
            _StatCard(label: 'PM Session', value: '$pm', color: AppTheme.info, icon: Icons.wb_twilight_rounded),
          ],
        ),
        const SizedBox(height: 20),

        // Pie chart
        if (total > 0) ...[
          const _SectionTitle('Attendance Rate'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: PieChart(PieChartData(
                      sections: [
                        PieChartSectionData(value: present.toDouble(), color: AppTheme.success, title: '${present > 0 ? (present / total * 100).round() : 0}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        PieChartSectionData(value: absent.toDouble(), color: AppTheme.danger, title: '${absent > 0 ? (absent / total * 100).round() : 0}%', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                    )),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(color: AppTheme.success, label: 'Present ($present)'),
                      const SizedBox(height: 8),
                      _Legend(color: AppTheme.danger, label: 'Absent ($absent)'),
                      const SizedBox(height: 12),
                      Text('Total: $total students', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Quick links
        const _SectionTitle('Quick Access'),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuickLink(icon: Icons.people_rounded, label: 'Students', onTap: () => context.go('/students')),
            const SizedBox(width: 10),
            _QuickLink(icon: Icons.school_rounded, label: 'Courses', onTap: () => context.go('/courses')),
            const SizedBox(width: 10),
            _QuickLink(icon: Icons.pattern_rounded, label: 'ID Patterns', onTap: () => context.go('/patterns')),
            const SizedBox(width: 10),
            _QuickLink(icon: Icons.bar_chart_rounded, label: 'Reports', onTap: () => context.go('/reports')),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
                    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: AppTheme.primary),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ],
  );
}
