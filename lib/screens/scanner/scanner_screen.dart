import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _idController = TextEditingController();
  final _focusNode = FocusNode();
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _idController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);

    // Auto-reset after 3 seconds
    ref.listen(scannerProvider, (prev, next) {
      if (next.status == ScanStatus.success || next.status == ScanStatus.error) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) ref.read(scannerProvider.notifier).reset();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Log'),
        actions: [
          if (!isLoggedIn)
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded, size: 18, color: AppTheme.primary),
              label: const Text('Login', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Live clock
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF6366F1)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    _clockStr(_now),
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, letterSpacing: -2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatDateFromDt(_now),
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4-state indicator
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Daily Log Flow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatusStep(label: 'AM In', step: 1, color: AppTheme.success),
                        _StepArrow(),
                        _StatusStep(label: 'AM Out', step: 2, color: AppTheme.warning),
                        _StepArrow(),
                        _StatusStep(label: 'PM In', step: 3, color: AppTheme.success),
                        _StepArrow(),
                        _StatusStep(label: 'PM Out', step: 4, color: AppTheme.danger),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Each ID scan auto-advances to the next step',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ID Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter or Scan Student ID',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _idController,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: 'e.g. 21-10001-1',
                              prefixIcon: Icon(Icons.badge_rounded),
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: scanState.status == ScanStatus.loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: scanState.status == ScanStatus.loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Result banner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: switch (scanState.status) {
                ScanStatus.success => _ResultBanner(
                    message: scanState.message ?? '',
                    color: AppTheme.success,
                    icon: Icons.check_circle_rounded,
                    record: scanState.record,
                  ),
                ScanStatus.error => _ResultBanner(
                    message: scanState.message ?? '',
                    color: AppTheme.danger,
                    icon: Icons.error_rounded,
                  ),
                _ => const SizedBox.shrink(),
              },
            ),

            const SizedBox(height: 24),

            // Today's recent logs
            const _TodayLogs(),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final id = _idController.text.trim();
    if (id.isEmpty) return;
    ref.read(scannerProvider.notifier).log(id);
    _idController.clear();
    _focusNode.requestFocus();
  }

  String _clockStr(DateTime d) {
    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:$m:$s $period';
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final int step;
  final Color color;
  const _StatusStep({required this.label, required this.step, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text('$step', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12))),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textSecondary);
}

class _ResultBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final dynamic record;

  const _ResultBanner({required this.message, required this.color, required this.icon, this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                if (record != null)
                  Text(
                    'Time: ${AppUtils.formatTime(record.timeIn ?? record.timeOut)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLogs extends ConsumerWidget {
  const _TodayLogs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = AppUtils.todayStr();
    final logsAsync = ref.watch(attendanceByDateProvider(today));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text("Today's Logs", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
            TextButton(onPressed: () => context.go('/attendance'), child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 8),
        logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.danger)),
          data: (logs) => logs.isEmpty
              ? const Center(child: Text('No logs yet today', style: TextStyle(color: AppTheme.textSecondary)))
              : Column(
                  children: logs.take(10).map((log) {
                    final color = _statusColor(log.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 30,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(log.idNumber, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(AppUtils.statusLabel(log.status),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppUtils.formatTime(log.timeIn ?? log.timeOut),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1: return AppTheme.success;
      case 2: return AppTheme.warning;
      case 3: return AppTheme.success;
      case 4: return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }
}
