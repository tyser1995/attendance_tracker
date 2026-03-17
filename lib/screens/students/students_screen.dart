import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/student_provider.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(allStudentsProvider);
    final query = ref.watch(studentSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => context.go('/students/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, ID, or course...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => ref.read(studentSearchQueryProvider.notifier).state = v,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: studentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (students) {
                if (students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        Text(query.isEmpty ? 'No students yet' : 'No results for "$query"',
                            style: const TextStyle(color: AppTheme.textSecondary)),
                        if (query.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Add Student'),
                            onPressed: () => context.go('/students/new'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = students[i];
                    final colorIdx = s.idNumber.hashCode.abs() % AppTheme.avatarColors.length;
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.go('/students/${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.avatarColors[colorIdx],
                                child: Text(s.initials,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(s.idNumber,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 6),
                                        if (s.courseCode != null)
                                          Text(s.courseCode!,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                    if (s.courseName != null)
                                      Text(s.courseName!,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
