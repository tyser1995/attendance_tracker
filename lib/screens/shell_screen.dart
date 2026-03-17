import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/backup_scheduler.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/db_config_provider.dart';

Color _roleColor(String role) {
  switch (role) {
    case 'super_admin': return AppTheme.danger;
    case 'admin': return AppTheme.primary;
    default: return AppTheme.success;
  }
}

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _allDestinations = [
    _NavItem('/scanner', Icons.fingerprint_rounded, Icons.fingerprint_rounded, 'Time Log', false, false),
    _NavItem('/attendance', Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Attendance', false, false),
    _NavItem('/students', Icons.people_rounded, Icons.people_outline_rounded, 'Students', true, false),
    _NavItem('/reports', Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Reports', true, false),
    _NavItem('/courses', Icons.school_rounded, Icons.school_outlined, 'Courses', true, false),
    _NavItem('/patterns', Icons.pattern_rounded, Icons.pattern_outlined, 'ID Patterns', true, false),
    _NavItem('/users', Icons.manage_accounts_rounded, Icons.manage_accounts_outlined, 'Users', false, true),
    _NavItem('/settings', Icons.settings_rounded, Icons.settings_outlined, 'Settings', false, true),
  ];

  List<_NavItem> _visibleDestinations(bool isAdmin, bool isSuperAdmin) {
    if (isSuperAdmin) return _allDestinations.toList();
    if (isAdmin) return _allDestinations.where((d) => !d.superAdminOnly).toList();
    return _allDestinations.where((d) => !d.adminOnly && !d.superAdminOnly).toList();
  }

  int _selectedIndex(String location, List<_NavItem> destinations) {
    for (int i = destinations.length - 1; i >= 0; i--) {
      if (location.startsWith(destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isAdmin = ref.watch(isAdminProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final user = ref.watch(authProvider);
    final destinations = _visibleDestinations(isAdmin, isSuperAdmin);
    final selectedIndex = _selectedIndex(location, destinations);
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final useRemote = ref.watch(dbConfigProvider).valueOrNull?.useRemote ?? false;

    // Keep the scheduler alive and show snackbar on backup events.
    ref.watch(backupScheduleProvider);
    ref.listen(backupEventProvider, (_, message) {
      if (message == null) return;
      final isError = message.contains('failed');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_rounded : Icons.check_circle_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        duration: const Duration(seconds: 5),
      ));
    });

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              destinations: destinations,
              selectedIndex: selectedIndex,
              useRemote: useRemote,
              user: user?.username ?? '',
              role: user?.role ?? '',
              onTap: (i) => context.go(destinations[i].path),
              onLogout: () => _logout(context, ref),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom bar shows first 5 visible destinations
    const bottomCount = 5;
    final bottomDestinations = destinations.take(bottomCount).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(location, destinations)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex.clamp(0, bottomDestinations.length - 1),
          onDestinationSelected: (i) => context.go(bottomDestinations[i].path),
          destinations: bottomDestinations.map((d) => NavigationDestination(
            icon: Icon(d.inactiveIcon),
            selectedIcon: Icon(d.icon),
            label: d.label,
          )).toList(),
        ),
      ),
    );
  }

  String _titleFor(String location, List<_NavItem> destinations) {
    for (int i = destinations.length - 1; i >= 0; i--) {
      if (location.startsWith(destinations[i].path)) return destinations[i].label;
    }
    return 'Attendance Tracker';
  }

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData inactiveIcon;
  final String label;
  final bool adminOnly;
  final bool superAdminOnly;
  const _NavItem(this.path, this.icon, this.inactiveIcon, this.label, this.adminOnly, this.superAdminOnly);
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> destinations;
  final int selectedIndex;
  final bool useRemote;
  final String user;
  final String role;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  const _SideNav({
    required this.destinations,
    required this.selectedIndex,
    required this.useRemote,
    required this.user,
    required this.role,
    required this.onTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                      Text('Tracker v2', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (useRemote ? AppTheme.info : AppTheme.success).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(useRemote ? Icons.cloud_rounded : Icons.storage_rounded,
                            size: 12, color: useRemote ? AppTheme.info : AppTheme.success),
                        const SizedBox(width: 4),
                        Text(useRemote ? 'Supabase' : 'Local DB',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: useRemote ? AppTheme.info : AppTheme.success)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: destinations.length,
              itemBuilder: (_, i) {
                final d = destinations[i];
                final selected = selectedIndex == i;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(selected ? d.icon : d.inactiveIcon,
                        color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 20),
                    title: Text(d.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppTheme.primary : AppTheme.textSecondary,
                        )),
                    onTap: () => onTap(i),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          // User info + logout
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(user.isNotEmpty ? user[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(role.replaceAll('_', ' '),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: _roleColor(role))),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textSecondary),
                  tooltip: 'Logout',
                  onPressed: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
