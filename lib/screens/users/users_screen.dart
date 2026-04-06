import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/face_api.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../providers/auth_methods_provider.dart';
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
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.danger))),
        data: (users) => users.isEmpty
            ? const Center(
                child: Text('No users found.',
                    style: TextStyle(color: AppTheme.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _UserTile(
                  user: users[i],
                  isSelf: users[i].id == currentUser?.id,
                  onEdit: () =>
                      _showUserDialog(context, ref, currentUser,
                          existing: users[i]),
                  onCredentials: () =>
                      _showCredentials(context, ref, users[i]),
                  onDelete: () => _confirmDelete(
                      context, ref, users[i], currentUser?.id ?? ''),
                ),
              ),
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref,
      AppUser? currentUser,
      {AppUser? existing}) {
    showDialog(
      context: context,
      builder: (ctx) => _UserDialog(existing: existing, ref: ref),
    );
  }

  void _showCredentials(
      BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialsDialog(user: user, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppUser user,
      String currentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.username}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(userManagerProvider.notifier)
                  .deleteUser(user.id, currentId);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(err),
                      backgroundColor: AppTheme.danger),
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

// ── User Tile ──────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onCredentials;
  final VoidCallback onDelete;

  const _UserTile({
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onCredentials,
    required this.onDelete,
  });

  Color get _color {
    switch (user.role) {
      case 'super_admin':
        return AppTheme.danger;
      case 'admin':
        return AppTheme.primary;
      default:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.15),
          child: Text(
            user.username[0].toUpperCase(),
            style:
                TextStyle(fontWeight: FontWeight.w700, color: _color),
          ),
        ),
        title: Row(
          children: [
            Text(user.username,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('you',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary)),
              ),
            ],
            // Credential indicator chips
            const SizedBox(width: 6),
            if (user.hasCardEnrolled)
              _chip(Icons.credit_card_rounded, AppTheme.primary),
            if (user.hasFaceEnrolled)
              _chip(Icons.face_rounded, AppTheme.success),
          ],
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            user.role.replaceAll('_', ' '),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _color),
          ),
        ),
        isThreeLine: false,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.key_rounded, size: 18),
                tooltip: 'Credentials',
                onPressed: onCredentials),
            IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18),
                onPressed: onEdit,
                tooltip: 'Edit'),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  size: 18, color: AppTheme.danger),
              onPressed: isSelf ? null : onDelete,
              tooltip: isSelf ? 'Cannot delete own account' : 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Icon(icon, size: 14, color: color),
      );
}

// ── Credentials Dialog ─────────────────────────────────────────────────────────

class _CredentialsDialog extends ConsumerStatefulWidget {
  final AppUser user;
  final WidgetRef ref;

  const _CredentialsDialog({required this.user, required this.ref});

  @override
  ConsumerState<_CredentialsDialog> createState() =>
      _CredentialsDialogState();
}

class _CredentialsDialogState
    extends ConsumerState<_CredentialsDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _cardCtrl = TextEditingController();
  bool _cardBusy = false;
  String? _cardMsg;
  bool _cardSuccess = false;

  // Face enrollment
  Object? _faceVideo;
  String? _faceViewType;
  bool _faceModelsReady = false;
  bool _faceBusy = false;
  String? _faceMsg;
  bool _faceSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _cardCtrl.text = widget.user.cardId ?? '';
    if (kIsWeb) _initFaceCamera();
  }

  void _initFaceCamera() {
    final pair = createFaceCameraView();
    _faceViewType = pair.viewType;
    _faceVideo = pair.video;
    loadFaceApiModels().then((_) {
      if (mounted) setState(() => _faceModelsReady = true);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _cardCtrl.dispose();
    if (kIsWeb && _faceVideo != null) {
      stopCamera(_faceVideo!);
    }
    super.dispose();
  }

  Future<void> _saveCardId() async {
    setState(() {
      _cardBusy = true;
      _cardMsg = null;
    });
    final err = await ref
        .read(userManagerProvider.notifier)
        .setCardId(widget.user.id, _cardCtrl.text);
    if (mounted) {
      setState(() {
        _cardBusy = false;
        _cardSuccess = err == null;
        _cardMsg =
            err ?? 'Card ID saved for ${widget.user.username}.';
      });
    }
  }

  Future<void> _enrollFace() async {
    if (!kIsWeb || _faceVideo == null) return;
    setState(() {
      _faceBusy = true;
      _faceMsg = null;
    });

    await startCamera(_faceVideo!);
    await Future.delayed(const Duration(milliseconds: 800));
    final descriptor = await detectFaceDescriptor(_faceVideo!);

    if (!mounted) return;
    if (descriptor == null) {
      setState(() {
        _faceBusy = false;
        _faceSuccess = false;
        _faceMsg = 'No face detected. Look directly at the camera.';
      });
      return;
    }

    final err = await ref
        .read(userManagerProvider.notifier)
        .setFaceDescriptor(widget.user.id, descriptor);
    if (mounted) {
      setState(() {
        _faceBusy = false;
        _faceSuccess = err == null;
        _faceMsg = err ??
            'Face enrolled for ${widget.user.username}. (${descriptor.length} features captured)';
      });
    }
  }

  Future<void> _clearFace() async {
    await ref
        .read(userManagerProvider.notifier)
        .setFaceDescriptor(widget.user.id, null);
    if (mounted) {
      setState(() {
        _faceSuccess = true;
        _faceMsg = 'Face data cleared.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final methods =
        ref.watch(authMethodsProvider).valueOrNull ?? const AuthMethodsConfig();

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.key_rounded, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text('Credentials — ${widget.user.username}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_rounded, size: 16), text: 'QR Code'),
                Tab(icon: Icon(Icons.credit_card_rounded, size: 16), text: 'Card ID'),
                Tab(icon: Icon(Icons.face_rounded, size: 16), text: 'Face'),
              ],
              labelStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildQrTab(),
                  _buildCardTab(methods),
                  _buildFaceTab(methods),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }

  // ── QR tab ─────────────────────────────────────────────────────────────────

  Widget _buildQrTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrImageView(
          data: widget.user.id,
          size: 180,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 12),
        Text(
          'Scan this QR code at the login screen.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Enable QR Code in Settings → Authentication Methods.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── Card ID tab ─────────────────────────────────────────────────────────────

  Widget _buildCardTab(AuthMethodsConfig methods) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Assign an RFID card or barcode to this user. '
            'Swipe the card or type the ID below.',
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cardCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Card / RFID ID',
              prefixIcon: Icon(Icons.credit_card_rounded),
              hintText: 'Swipe RFID or type barcode…',
            ),
          ),
          const SizedBox(height: 12),
          if (_cardMsg != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_cardSuccess
                        ? AppTheme.success
                        : AppTheme.danger)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: (_cardSuccess
                            ? AppTheme.success
                            : AppTheme.danger)
                        .withValues(alpha: 0.3)),
              ),
              child: Text(_cardMsg!,
                  style: TextStyle(
                      fontSize: 12,
                      color: _cardSuccess
                          ? AppTheme.success
                          : AppTheme.danger)),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.clear_rounded, size: 14),
                label: const Text('Clear'),
                onPressed: _cardBusy
                    ? null
                    : () {
                        _cardCtrl.clear();
                        _saveCardId();
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: _cardBusy
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 14),
                label: const Text('Save'),
                onPressed: _cardBusy ? null : _saveCardId,
              ),
            ),
          ]),
          if (!methods.rfid && !methods.barcode) ...[
            const SizedBox(height: 8),
            const Text(
              'Enable RFID or Barcode in Settings → Authentication Methods to use this.',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Face tab ───────────────────────────────────────────────────────────────

  Widget _buildFaceTab(AuthMethodsConfig methods) {
    if (!kIsWeb) {
      return const Center(
          child: Text('Face recognition is web-only.',
              style: TextStyle(color: AppTheme.textSecondary)));
    }

    final enrolled = widget.user.hasFaceEnrolled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _faceViewType == null
              ? const Center(child: CircularProgressIndicator())
              : HtmlElementView(viewType: _faceViewType!),
        ),
        const SizedBox(height: 8),
        if (_faceMsg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              _faceMsg!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: _faceSuccess
                      ? AppTheme.success
                      : AppTheme.danger),
            ),
          ),
        Row(children: [
          if (enrolled)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text('Clear Face'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger),
                onPressed: _faceBusy ? null : _clearFace,
              ),
            ),
          if (enrolled) const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: _faceBusy
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.face_retouching_natural_rounded,
                      size: 14),
              label: Text(enrolled ? 'Re-enroll' : 'Enroll Face'),
              onPressed:
                  (_faceModelsReady && !_faceBusy) ? _enrollFace : null,
            ),
          ),
        ]),
        if (!methods.face) ...[
          const SizedBox(height: 6),
          const Text(
            'Enable Face Recognition in Settings → Authentication Methods.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }
}

// ── User Add/Edit Dialog ──────────────────────────────────────────────────────

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
    _usernameCtrl =
        TextEditingController(text: widget.existing?.username ?? '');
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
    setState(() {
      _loading = true;
      _error = null;
    });

    final notifier = widget.ref.read(userManagerProvider.notifier);
    String? err;

    if (_isEdit) {
      err = await notifier.updateUser(
        id: widget.existing!.id,
        username: _usernameCtrl.text,
        newPassword:
            _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
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
      setState(() {
        _loading = false;
        _error = err;
      });
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
                    border: Border.all(
                        color:
                            AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.danger, fontSize: 13)),
                ),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_rounded)),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEdit
                      ? 'New Password (leave blank to keep)'
                      : 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_rounded)),
                items: const [
                  DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super Admin')),
                  DropdownMenuItem(
                      value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'staff', child: Text('Staff')),
                ],
                onChanged: (v) =>
                    setState(() => _role = v ?? 'staff'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
