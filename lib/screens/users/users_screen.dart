import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);
    final currentUser = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add User',
            onPressed: () => _showUserDialog(context, ref, currentUser),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.danger))),
        data: (users) => users.isEmpty
            ? const Center(child: Text('No users found.', style: TextStyle(color: AppTheme.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserTile(
                  user: users[i],
                  isSelf: users[i].id == currentUser?.id,
                  onEdit: () => _showUserDialog(context, ref, currentUser, existing: users[i]),
                  onDelete: () => _confirmDelete(context, ref, users[i], currentUser?.id ?? ''),
                ),
              ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, AppUser? currentUser, {AppUser? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _UserDialog(existing: existing, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppUser user, String currentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.username}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref.read(userManagerProvider.notifier).deleteUser(user.id, currentId);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err), backgroundColor: AppTheme.danger),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserTile({required this.user, required this.isSelf, required this.onEdit, required this.onDelete});

  Color get _color {
    switch (user.role) {
      case 'super_admin': return AppTheme.danger;
      case 'admin': return AppTheme.primary;
      default: return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.15),
          child: Text(
            user.username[0].toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w700, color: _color),
          ),
        ),
        title: Row(
          children: [
            Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('you', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ),
            ],
          ],
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            user.role.replaceAll('_', ' '),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
          ),
        ),
        isThreeLine: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_rounded, size: 18), onPressed: onEdit, tooltip: 'Edit'),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
              onPressed: isSelf ? null : onDelete,
              tooltip: isSelf ? 'Cannot delete own account' : 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final AppUser? existing;
  final WidgetRef ref;
  const _UserDialog({this.existing, required this.ref});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  final _passwordCtrl = TextEditingController();
  late String _role;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.existing?.username ?? '');
    _role = widget.existing?.role ?? 'staff';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final notifier = widget.ref.read(userManagerProvider.notifier);
    String? err;

    if (_isEdit) {
      err = await notifier.updateUser(
        id: widget.existing!.id,
        username: _usernameCtrl.text,
        newPassword: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
        role: _role,
      );
    } else {
      err = await notifier.createUser(
        username: _usernameCtrl.text,
        password: _passwordCtrl.text,
        role: _role,
      );
    }

    if (!mounted) return;
    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'Add User'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                ),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_rounded)),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEdit ? 'New Password (leave blank to keep)' : 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_rounded)),
                items: const [
                  DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'staff'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
