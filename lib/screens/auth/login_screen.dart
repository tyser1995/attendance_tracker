import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/face_api.dart';
import '../../core/theme.dart';
import '../../providers/auth_methods_provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Tab controller ──────────────────────────────────────────────────────────
  late TabController _tabCtrl;
  List<_Tab> _tabs = [const _Tab('Password', Icons.lock_rounded)];

  // ── Password tab ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // ── Card (RFID / Barcode keyboard) tab ───────────────────────────────────
  final _cardCtrl = TextEditingController();
  final _cardFocus = FocusNode();

  // ── Face tab ──────────────────────────────────────────────────────────────
  Object? _faceVideo; // html.VideoElement on web — kept as Object for compile safety
  String? _faceViewType;
  bool _faceReady = false;
  bool _faceLoading = false;

  // ── Shared ────────────────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 1, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    if (kIsWeb) _initFaceCamera();
    // Apply initial config after first frame (ref not yet available in initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cfg = ref.read(authMethodsProvider).valueOrNull;
      if (cfg != null) _rebuildTabs(cfg);
    });
  }

  void _initFaceCamera() {
    if (!kIsWeb) return;
    final pair = createFaceCameraView();
    _faceViewType = pair.viewType;
    _faceVideo = pair.video;
    loadFaceApiModels().then((_) {
      if (mounted) setState(() => _faceReady = true);
    }).catchError((_) {});
  }

  void _rebuildTabs(AuthMethodsConfig cfg) {
    final tabs = [const _Tab('Password', Icons.lock_rounded)];
    if (cfg.rfid) tabs.add(const _Tab('RFID', Icons.credit_card_rounded));
    if (cfg.hasScan) tabs.add(const _Tab('Scan', Icons.qr_code_scanner_rounded));
    if (cfg.face && kIsWeb) tabs.add(const _Tab('Face', Icons.face_rounded));

    final labels = tabs.map((t) => t.label).toList();
    final currentLabels = _tabs.map((t) => t.label).toList();
    if (labels.join() == currentLabels.join()) return; // no change

    setState(() {
      _tabs = tabs;
      _tabCtrl.dispose();
      _tabCtrl = TabController(length: tabs.length, vsync: this);
      _tabCtrl.addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) return;
    final tab = _tabs[_tabCtrl.index];
    if (tab.label == 'RFID') {
      Future.microtask(() => _cardFocus.requestFocus());
    }
    if (tab.label == 'Face' && kIsWeb && _faceVideo != null) {
      // Defer until after HtmlElementView is in the DOM (JS retries anyway).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) startCamera(_faceVideo!);
      });
    } else if (kIsWeb && _faceVideo != null) {
      stopCamera(_faceVideo!);
    }
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _cardCtrl.dispose();
    _cardFocus.dispose();
    if (kIsWeb && _faceVideo != null) {
      stopCamera(_faceVideo!);
    }
    super.dispose();
  }

  // ── Login helpers ──────────────────────────────────────────────────────────

  void _handleResult(String? error) {
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
    } else {
      context.go('/scanner');
    }
  }

  Future<void> _loginPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(authProvider.notifier)
        .login(_userCtrl.text, _passCtrl.text);
    _handleResult(err);
  }

  Future<void> _loginCard(String value) async {
    if (value.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err =
        await ref.read(authProvider.notifier).loginByCard(value);
    _cardCtrl.clear();
    _handleResult(err);
  }

  Future<void> _loginQr(String value, bool isQr) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final String? err;
    if (isQr) {
      err = await ref.read(authProvider.notifier).loginByQrToken(value);
    } else {
      err = await ref.read(authProvider.notifier).loginByCard(value);
    }
    _handleResult(err);
  }

  Future<void> _loginFace() async {
    if (!kIsWeb || _faceVideo == null) return;
    setState(() {
      _faceLoading = true;
      _error = null;
    });
    final descriptor =
        await detectFaceDescriptor(_faceVideo!);
    if (!mounted) return;
    if (descriptor == null) {
      setState(() {
        _faceLoading = false;
        _error = 'No face detected. Look directly at the camera.';
      });
      return;
    }
    setState(() => _loading = true);
    final err =
        await ref.read(authProvider.notifier).loginByFace(descriptor);
    if (mounted) setState(() => _faceLoading = false);
    _handleResult(err);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for auth-method changes and rebuild tabs safely after the frame.
    ref.listen<AsyncValue<AuthMethodsConfig>>(authMethodsProvider, (_, next) {
      next.whenData((cfg) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _rebuildTabs(cfg);
        });
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.access_time_filled_rounded,
                      color: Colors.white, size: 38),
                ),
                const SizedBox(height: 20),
                const Text('Attendance Tracker',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                const Text('Sign in to continue',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 28),

                // Tab bar (only shown when multiple methods enabled)
                if (_tabs.length > 1) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: TabBar(
                      controller: _tabCtrl,
                      isScrollable: _tabs.length > 3,
                      tabs: _tabs
                          .map((t) => Tab(
                                icon: Icon(t.icon, size: 18),
                                text: t.label,
                              ))
                          .toList(),
                      labelStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      unselectedLabelStyle:
                          const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Error banner
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_rounded,
                          size: 16, color: AppTheme.danger),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppTheme.danger, fontSize: 13))),
                    ]),
                  ),
                ],

                // Tab content
                if (_tabs.length == 1)
                  _buildPasswordCard()
                else
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children:
                          _tabs.map((t) => _buildTab(t.label)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label) {
    return switch (label) {
      'Password' => _buildPasswordCard(),
      'RFID' => _buildRfidTab(),
      'Scan' => _buildScanTab(),
      'Face' => _buildFaceTab(),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Password tab ───────────────────────────────────────────────────────────

  Widget _buildPasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Required' : null,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v?.isEmpty == true ? 'Required' : null,
                onFieldSubmitted: (_) => _loginPassword(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginPassword,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── RFID tab ───────────────────────────────────────────────────────────────

  Widget _buildRfidTab() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_rounded,
                size: 52, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Ready for Card Swipe',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            const Text(
              'Tap your RFID card on the reader or swipe your barcode.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            // Hidden but focusable text field captures HID keyboard input
            SizedBox(
              height: 48,
              child: TextField(
                controller: _cardCtrl,
                focusNode: _cardFocus,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'Card number will appear here...',
                  prefixIcon: Icon(Icons.sensors_rounded),
                ),
                onSubmitted: _loginCard,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Login'),
                  onPressed: () => _loginCard(_cardCtrl.text),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Scan tab (QR + Barcode camera) ─────────────────────────────────────────

  Widget _buildScanTab() {
    final cfg = ref.watch(authMethodsProvider).valueOrNull;
    final formats = <BarcodeFormat>[];
    if (cfg?.qrCode == true) formats.add(BarcodeFormat.qrCode);
    if (cfg?.barcode == true) {
      formats.addAll([
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ]);
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  MobileScanner(
                    controller: MobileScannerController(
                      formats: formats.isEmpty ? BarcodeFormat.values : formats,
                    ),
                    onDetect: (capture) {
                      final b = capture.barcodes.firstOrNull;
                      if (b?.rawValue == null) return;
                      _loginQr(b!.rawValue!,
                          b.format == BarcodeFormat.qrCode);
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Point camera at QR code or barcode',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Face tab ───────────────────────────────────────────────────────────────

  Widget _buildFaceTab() {
    if (!kIsWeb) {
      return const Card(
        child: Center(
            child: Text('Face recognition is only available on web.')),
      );
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: _faceViewType == null
                  ? const Center(child: CircularProgressIndicator())
                  : HtmlElementView(viewType: _faceViewType!),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _faceReady
                            ? 'Look at the camera, then tap Detect.'
                            : 'Loading face recognition models...',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: _faceLoading || _loading
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.face_rounded, size: 16),
                  label: const Text('Detect'),
                  onPressed: (_faceReady && !_faceLoading && !_loading)
                      ? _loginFace
                      : null,
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  const _Tab(this.label, this.icon);
}
