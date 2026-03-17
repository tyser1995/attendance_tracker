import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';

class StudentDetailScreen extends ConsumerWidget {
  final String id;
  const StudentDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(id));

    return studentAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (student) {
        if (student == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Student not found')));
        }
        final colorIdx = student.idNumber.hashCode.abs() % AppTheme.avatarColors.length;
        final logsAsync = ref.watch(attendanceByStudentProvider(student.idNumber));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Details'),
            actions: [
              IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () => context.go('/students/$id/edit')),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [
                    Icon(Icons.person_off_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Remove Student', style: TextStyle(color: Colors.red)),
                  ])),
                ],
                onSelected: (v) {
                  if (v == 'delete') _confirmDelete(context, ref);
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              // Profile card
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.avatarColors[colorIdx],
                      child: Text(student.initials,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    Text(student.fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(student.idNumber,
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    if (student.courseName != null) ...[
                      const SizedBox(height: 6),
                      Text('${student.courseCode} – ${student.courseName}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 12),
                            _InfoRow(icon: Icons.badge_rounded, label: 'ID Number', value: student.idNumber),
                            if (student.dateOfBirth != null)
                              _InfoRow(icon: Icons.cake_rounded, label: 'Date of Birth', value: AppUtils.formatDate(student.dateOfBirth!)),
                            _InfoRow(icon: Icons.person_rounded, label: 'Sex', value: student.sex == 'M' ? 'Male' : 'Female'),
                            if (student.courseName != null)
                              _InfoRow(icon: Icons.school_rounded, label: 'Course', value: '${student.courseCode} – ${student.courseName}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Attendance History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    logsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                      data: (logs) {
                        if (logs.isEmpty) {
                          return const Center(child: Text('No attendance records', style: TextStyle(color: AppTheme.textSecondary)));
                        }
                        // Group by date
                        final Map<String, List<dynamic>> byDate = {};
                        for (final l in logs) {
                          byDate.putIfAbsent(l.createdDate, () => []).add(l);
                        }
                        return Column(
                          children: byDate.entries.take(14).map((e) {
                            final date = e.key;
                            final dayLogs = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppUtils.formatDate(date),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: dayLogs.map((l) {
                                      final color = _logColor(l.status as int);
                                      return Chip(
                                        backgroundColor: color.withValues(alpha: 0.1),
                                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                                        label: Text(
                                          '${AppUtils.statusLabel(l.status as int)} ${AppUtils.formatTime(l.timeIn ?? l.timeOut)}',
                                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _logColor(int s) {
    switch (s) {
      case 1: return AppTheme.success;
      case 2: return AppTheme.warning;
      case 3: return AppTheme.success;
      case 4: return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text('This will soft-delete the student. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(studentNotifierProvider.notifier).softDelete(id);
              if (context.mounted) context.go('/students');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
