import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/id_pattern_provider.dart';

class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(allPatternsProvider);
    final notifier = ref.read(idPatternNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Patterns'),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'activate_all', child: Text('Activate All')),
              PopupMenuItem(value: 'deactivate_all', child: Text('Deactivate All')),
            ],
            onSelected: (v) async {
              if (v == 'activate_all') await notifier.activateAll();
              if (v == 'deactivate_all') await notifier.deactivateAll();
            },
          ),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => context.go('/patterns/new')),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.warning.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.warning),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Active patterns validate student IDs during time logging. Use # for digit placeholders.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: patternsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (patterns) => patterns.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pattern_outlined, size: 48, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text('No ID patterns. Add one to enable ID validation.',
                              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: patterns.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = patterns[i];
                        final isActive = p.isActive;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(p.pattern,
                                      style: const TextStyle(
                                          color: Color(0xFF4ADE80), fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700, fontSize: 16)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Regex: ${p.regex}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isActive ? AppTheme.success : AppTheme.textSecondary).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w600,
                                                color: isActive ? AppTheme.success : AppTheme.textSecondary)),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isActive,
                                  activeThumbColor: AppTheme.success,
                                  onChanged: (_) => notifier.toggle(p.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                                  onPressed: () => _confirmDelete(context, ref, p.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pattern'),
        content: const Text('Remove this ID pattern?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(idPatternNotifierProvider.notifier).delete(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
