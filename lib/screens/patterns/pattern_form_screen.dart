import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../models/id_pattern.dart';
import '../../providers/id_pattern_provider.dart';

class PatternFormScreen extends ConsumerStatefulWidget {
  const PatternFormScreen({super.key});

  @override
  ConsumerState<PatternFormScreen> createState() => _PatternFormScreenState();
}

class _PatternFormScreenState extends ConsumerState<PatternFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patternCtrl = TextEditingController();
  String _preview = '';

  @override
  void dispose() {
    _patternCtrl.dispose();
    super.dispose();
  }

  void _onPatternChanged(String v) {
    setState(() {
      _preview = v.isNotEmpty ? IdPattern.buildRegex(v) : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(idPatternNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add ID Pattern')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pattern Rules', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('# = digit (0-9)', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
                          Text('Any other character = literal', style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
                          SizedBox(height: 6),
                          Text('Examples:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textSecondary)),
                          Text('  ##-#####-# → 21-10001-1', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary)),
                          Text('  ####-####  → 2024-0001', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _patternCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pattern *',
                        hintText: 'e.g. ##-#####-#',
                        prefixIcon: Icon(Icons.pattern_rounded),
                      ),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      onChanged: _onPatternChanged,
                    ),
                    if (_preview.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('Regex: ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            Expanded(
                              child: Text(_preview,
                                  style: const TextStyle(color: Color(0xFF4ADE80), fontFamily: 'monospace', fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (formState.hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${formState.error}', style: const TextStyle(color: AppTheme.danger)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: formState.isLoading ? null : _submit,
                child: formState.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Pattern'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final pattern = _patternCtrl.text.trim();
    const uuid = Uuid();
    final idPattern = IdPattern(
      id: uuid.v4(),
      pattern: pattern,
      regex: IdPattern.buildRegex(pattern),
      status: 'active',
    );
    final ok = await ref.read(idPatternNotifierProvider.notifier).create(idPattern);
    if (ok && mounted) context.go('/patterns');
  }
}
