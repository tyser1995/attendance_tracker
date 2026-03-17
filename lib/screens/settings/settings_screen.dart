import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/db_config_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _obscureKey = true;
  bool _testingConnection = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(dbConfigProvider);
    final initialPage = ref.watch(dbConfigProvider).valueOrNull?.initialPage ?? 'login';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          // Pre-fill fields if empty
          if (_urlCtrl.text.isEmpty && config.supabaseUrl.isNotEmpty) {
            _urlCtrl.text = config.supabaseUrl;
          }
          if (_keyCtrl.text.isEmpty && config.supabaseKey.isNotEmpty) {
            _keyCtrl.text = config.supabaseKey;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Initial Page section
              _SectionHeader(label: 'Initial Page', icon: Icons.home_rounded),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Choose what page opens when the app is launched.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    _PageOption(
                      icon: Icons.login_rounded,
                      title: 'Login Page',
                      subtitle: 'Users must sign in before accessing anything.',
                      selected: initialPage == 'login',
                      onTap: () => ref.read(dbConfigProvider.notifier).setInitialPage('login'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _PageOption(
                      icon: Icons.fingerprint_rounded,
                      title: 'Scanner (Time Log)',
                      subtitle: 'Scanner opens immediately. A login link is shown for staff management.',
                      selected: initialPage == 'scanner',
                      onTap: () => ref.read(dbConfigProvider.notifier).setInitialPage('scanner'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Database section
              _SectionHeader(label: 'Database', icon: Icons.storage_rounded),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (config.useRemote ? AppTheme.success : AppTheme.primary)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              config.useRemote ? Icons.cloud_rounded : Icons.storage_rounded,
                              color: config.useRemote ? AppTheme.success : AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.useRemote ? 'Supabase (Remote)' : 'SQLite (Local)',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                Text(
                                  config.useRemote
                                      ? 'Data stored in Supabase cloud'
                                      : 'Data stored on this device',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: config.useRemote,
                            activeThumbColor: AppTheme.success,
                            onChanged: (v) => _toggleDb(v),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              config.useRemote
                                  ? 'All reads/writes go to Supabase. Requires valid credentials below.'
                                  : 'All reads/writes go to local SQLite database. No internet required.',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Supabase credentials
              _SectionHeader(label: 'Supabase Credentials', icon: Icons.vpn_key_rounded),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Required when using Supabase as the database source.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _urlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Project URL',
                          hintText: 'https://xxxx.supabase.co',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() => _testResult = null),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _keyCtrl,
                        obscureText: _obscureKey,
                        decoration: InputDecoration(
                          labelText: 'Anon/Public Key',
                          hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                          prefixIcon: const Icon(Icons.key_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                            onPressed: () => setState(() => _obscureKey = !_obscureKey),
                          ),
                        ),
                        onChanged: (_) => setState(() => _testResult = null),
                      ),
                      const SizedBox(height: 16),

                      if (_testResult != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_testSuccess ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (_testSuccess ? AppTheme.success : AppTheme.danger).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                                size: 16,
                                color: _testSuccess ? AppTheme.success : AppTheme.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _testResult!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _testSuccess ? AppTheme.success : AppTheme.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: _testingConnection
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.wifi_tethering_rounded, size: 16),
                              label: Text(_testingConnection ? 'Testing...' : 'Test Connection'),
                              onPressed: _testingConnection ? null : _testConnection,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save_rounded, size: 16),
                              label: const Text('Save'),
                              onPressed: _saveCredentials,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SQL schema helper
              _SectionHeader(label: 'Supabase Schema', icon: Icons.terminal_rounded),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  'Run this SQL in your Supabase SQL editor to create the required tables.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: const Icon(Icons.code_rounded, size: 20),
                    title: const Text('View SQL Schema', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _sqlSchema,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App info
              _SectionHeader(label: 'About', icon: Icons.info_rounded),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(label: 'App', value: 'Attendance Tracker v2'),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Built with', value: 'Flutter + Riverpod'),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Database',
                        value: config.useRemote
                            ? (config.supabaseUrl.isNotEmpty ? 'Supabase (${Uri.tryParse(config.supabaseUrl)?.host ?? config.supabaseUrl})' : 'Supabase (no URL set)')
                            : 'SQLite (local)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleDb(bool useRemote) async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (useRemote && (url.isEmpty || key.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter Supabase URL and key before switching to remote.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    if (useRemote) {
      await ref.read(dbConfigProvider.notifier).saveSupabaseConfig(url, key);
    }
    await ref.read(dbConfigProvider.notifier).setUseRemote(useRemote);
  }

  Future<void> _saveCredentials() async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both URL and key are required'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    await ref.read(dbConfigProvider.notifier).saveSupabaseConfig(url, key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credentials saved'), backgroundColor: AppTheme.success),
      );
      setState(() => _testResult = null);
    }
  }

  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim();
    final key = _keyCtrl.text.trim();
    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _testResult = 'Enter URL and key first.';
        _testSuccess = false;
      });
      return;
    }
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });
    try {
      final parsed = Uri.parse(url);
      if (parsed.host.isEmpty) throw Exception('Invalid URL');
      // We just validate URL/key format — real test needs Supabase SDK init
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _testSuccess = true;
        _testResult = 'Format looks valid. Save credentials and switch to Supabase to test live connection.';
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = 'Error: $e';
      });
    } finally {
      setState(() => _testingConnection = false);
    }
  }
}

class _PageOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PageOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (selected ? AppTheme.primary : AppTheme.textSecondary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: selected ? AppTheme.primary : AppTheme.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                      color: selected ? AppTheme.primary : AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      );
}

const _sqlSchema = '''
-- Run in Supabase SQL Editor

create table if not exists courses (
  id text primary key,
  course_code text not null unique,
  course_name text not null,
  year_level text not null default ''
);

create table if not exists students (
  id text primary key,
  id_number text not null unique,
  first_name text not null,
  last_name text not null,
  middle_name text not null default '',
  date_of_birth text not null default '',
  sex text not null default '',
  course_id text references courses(id),
  is_deleted integer not null default 0
);

create table if not exists attendances (
  id text primary key,
  id_number text not null,
  name text not null default '',
  time_in text,
  time_out text,
  created_date text not null,
  status integer not null default 1
);

create table if not exists id_patterns (
  id text primary key,
  pattern text not null unique,
  regex text not null,
  status text not null default 'active'
);

-- Indexes
create index if not exists idx_students_idnumber on students(id_number);
create index if not exists idx_attendances_date on attendances(created_date);
create index if not exists idx_attendances_idnumber on attendances(id_number);
''';
