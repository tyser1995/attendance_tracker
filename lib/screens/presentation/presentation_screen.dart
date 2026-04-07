import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand palette (matches PPTX export) ──────────────────────────────────────
const _kNavy     = Color(0xFF0D1B3E);
const _kCard     = Color(0xFF1E2D5E);
const _kCardAlt  = Color(0xFF14234E);
const _kBlue     = Color(0xFF1A73E8);
const _kCyan     = Color(0xFF00C2FF);
const _kMuted    = Color(0xFFA0B4D8);
const _kGreen    = Color(0xFF34D399);
const _kOrange   = Color(0xFFFBBF24);
const _kRed      = Color(0xFFF87171);
const _kWhite    = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  int _current = 0;
  bool _drawerOpen = false;

  late final List<_Slide> _slides;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
  }

  void _go(int delta) {
    final next = (_current + delta).clamp(0, _slides.length - 1);
    if (next != _current) setState(() => _current = next);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (e) {
        if (e is KeyDownEvent) {
          if (e.logicalKey == LogicalKeyboardKey.arrowRight ||
              e.logicalKey == LogicalKeyboardKey.arrowDown ||
              e.logicalKey == LogicalKeyboardKey.space) {
            _go(1);
          } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft ||
              e.logicalKey == LogicalKeyboardKey.arrowUp) {
            _go(-1);
          }
        }
      },
      child: Scaffold(
        backgroundColor: _kNavy,
        body: Stack(
          children: [
            // ── Main slide area ──────────────────────────────────────────────
            Column(
              children: [
                _TopBar(
                  current: _current,
                  total: _slides.length,
                  onMenu: () => setState(() => _drawerOpen = !_drawerOpen),
                  onHome: () => context.go('/login'),
                ),
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity != null) {
                        if (d.primaryVelocity! < -300) _go(1);
                        if (d.primaryVelocity! > 300) _go(-1);
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _SlideView(
                        key: ValueKey(_current),
                        slide: _slides[_current],
                      ),
                    ),
                  ),
                ),
                _BottomBar(current: _current, total: _slides.length, onPrev: () => _go(-1), onNext: () => _go(1)),
              ],
            ),

            // ── Slide drawer overlay ─────────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              top: 0, bottom: 0,
              left: _drawerOpen ? 0 : -240,
              width: 240,
              child: _SlideDrawer(
                slides: _slides,
                current: _current,
                onSelect: (i) => setState(() {
                  _current = i;
                  _drawerOpen = false;
                }),
                onClose: () => setState(() => _drawerOpen = false),
              ),
            ),
            if (_drawerOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _drawerOpen = false),
                  child: Container(color: Colors.black45),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Slide definitions
  // ══════════════════════════════════════════════════════════════════════════
  List<_Slide> _buildSlides() => [
    // ── 01 Cover ────────────────────────────────────────────────────────────
    _Slide(
      title: 'Cover',
      content: (context) => _CoverSlide(),
    ),

    // ── 02 Agenda ───────────────────────────────────────────────────────────
    _Slide(
      title: 'Agenda',
      content: (context) => _TwoColGrid(
        heading: 'Agenda',
        subtitle: "What we'll cover today",
        items: const [
          _GridItem('01', 'System Overview', 'Architecture, tech stack & capabilities'),
          _GridItem('02', 'Authentication Flows', '5 login methods — password, card, QR, barcode, face'),
          _GridItem('03', 'Time Log / Scanner', 'Core attendance capture flow'),
          _GridItem('04', 'Attendance & Reports', 'Viewing logs, charts & exports'),
          _GridItem('05', 'Student & Course Mgmt', 'Managing student records and courses'),
          _GridItem('06', 'User & Settings', 'Role-based access & system config'),
          _GridItem('07', 'Data & Backup', 'Local vs cloud, scheduled backups'),
          _GridItem('08', 'Role Access Matrix', 'Who can do what'),
        ],
      ),
    ),

    // ── 03 System Overview ───────────────────────────────────────────────────
    _Slide(
      title: 'System Overview',
      content: (context) => _SystemOverviewSlide(),
    ),

    // ── 04 Auth Flows ────────────────────────────────────────────────────────
    _Slide(
      title: 'Authentication Flows',
      content: (context) => _AuthFlowsSlide(),
    ),

    // ── 05 Time Log ──────────────────────────────────────────────────────────
    _Slide(
      title: 'Time Log / Scanner',
      content: (context) => _TimeLogSlide(),
    ),

    // ── 06 Attendance & Reports ───────────────────────────────────────────────
    _Slide(
      title: 'Attendance & Reports',
      content: (context) => _AttendanceReportsSlide(),
    ),

    // ── 07 Student/Course/Pattern ─────────────────────────────────────────────
    _Slide(
      title: 'Student, Course & Patterns',
      content: (context) => _ManagementSlide(),
    ),

    // ── 08 User Mgmt & Settings ──────────────────────────────────────────────
    _Slide(
      title: 'User Management & Settings',
      content: (context) => _UserSettingsSlide(),
    ),

    // ── 09 Data & Backup ─────────────────────────────────────────────────────
    _Slide(
      title: 'Data Management & Backup',
      content: (context) => _DataBackupSlide(),
    ),

    // ── 10 Role Matrix ───────────────────────────────────────────────────────
    _Slide(
      title: 'Role Access Matrix',
      content: (context) => _RoleMatrixSlide(),
    ),

    // ── 11 Key Benefits ──────────────────────────────────────────────────────
    _Slide(
      title: 'Key Benefits',
      content: (context) => _BenefitsSlide(),
    ),
  ];
}

// ════════════════════════════════════════════════════════════════════════════
// Chrome widgets
// ════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final int current, total;
  final VoidCallback onMenu, onHome;
  const _TopBar({required this.current, required this.total, required this.onMenu, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF0A1530),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: _kCyan, size: 20),
            onPressed: onMenu,
            tooltip: 'Slide list',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.view_carousel_rounded, color: _kCyan, size: 18),
          const SizedBox(width: 8),
          Text(
            'Attendance Tracker — Client Presentation',
            style: GoogleFonts.inter(color: _kMuted, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            '${current + 1} / $total',
            style: GoogleFonts.inter(color: _kCyan, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: onHome,
            icon: const Icon(Icons.login_rounded, size: 16, color: _kMuted),
            label: Text('Go to App', style: GoogleFonts.inter(color: _kMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int current, total;
  final VoidCallback onPrev, onNext;
  const _BottomBar({required this.current, required this.total, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFF0A1530),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 1 ? current / (total - 1) : 1.0,
                backgroundColor: _kCard,
                color: _kCyan,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 24),
          _NavBtn(icon: Icons.arrow_back_ios_rounded, onTap: current > 0 ? onPrev : null),
          const SizedBox(width: 8),
          _NavBtn(icon: Icons.arrow_forward_ios_rounded, onTap: current < total - 1 ? onNext : null),
          const SizedBox(width: 8),
          Text(
            '← → or swipe',
            style: GoogleFonts.inter(color: _kMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 16),
    color: onTap != null ? _kCyan : _kCard,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
  );
}

class _SlideDrawer extends StatelessWidget {
  final List<_Slide> slides;
  final int current;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  const _SlideDrawer({required this.slides, required this.current, required this.onSelect, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF091226),
      child: Column(
        children: [
          Container(
            height: 48,
            color: const Color(0xFF0A1530),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('Slides', style: GoogleFonts.inter(color: _kCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: _kMuted, size: 18), onPressed: onClose, visualDensity: VisualDensity.compact),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: slides.length,
              itemBuilder: (_, i) {
                final active = i == current;
                return InkWell(
                  onTap: () => onSelect(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? _kBlue.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: active ? _kCyan : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22, height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? _kCyan : _kCard,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: active ? _kNavy : _kMuted)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(slides[i].title, style: GoogleFonts.inter(fontSize: 12, color: active ? _kWhite : _kMuted, fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({super.key, required this.slide});

  @override
  Widget build(BuildContext context) => slide.content(context);
}

// ════════════════════════════════════════════════════════════════════════════
// Shared layout helpers
// ════════════════════════════════════════════════════════════════════════════

class _SlidePadding extends StatelessWidget {
  final Widget child;
  const _SlidePadding({required this.child});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
    child: child,
  );
}

Text _heading(String t, {double size = 30, Color color = _kWhite, TextAlign align = TextAlign.left}) =>
    Text(t, textAlign: align, style: GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w800, color: color));

Text _sub(String t, {double size = 13, Color color = _kMuted, TextAlign align = TextAlign.left}) =>
    Text(t, textAlign: align, style: GoogleFonts.inter(fontSize: size, color: color, fontStyle: FontStyle.italic));

Text _label(String t, {double size = 11, Color color = _kCyan}) =>
    Text(t.toUpperCase(), style: GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.1));

Widget _divider() => Container(height: 3, width: 56, margin: const EdgeInsets.only(top: 8, bottom: 18), decoration: BoxDecoration(color: _kCyan, borderRadius: BorderRadius.circular(2)));

Widget _card({required Widget child, Color bg = _kCard, EdgeInsets? padding, double radius = 12, Color? border}) =>
    Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: child,
    );

// ════════════════════════════════════════════════════════════════════════════
// Slide 01 — Cover
// ════════════════════════════════════════════════════════════════════════════
class _CoverSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      child: Row(
        children: [
          // Left
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 56, height: 4, decoration: BoxDecoration(color: _kCyan, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text('ATTENDANCE\nTRACKER', style: GoogleFonts.inter(fontSize: 52, fontWeight: FontWeight.w900, color: _kWhite, height: 1.1)),
                  const SizedBox(height: 18),
                  Text('Smart Campus Attendance System', style: GoogleFonts.inter(fontSize: 18, color: _kCyan, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  Text('Multi-modal login  ·  Real-time logging  ·  Analytics & Export',
                      style: GoogleFonts.inter(fontSize: 13, color: _kMuted)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(8)),
                    child: Text('CLIENT PRESENTATION  |  2026', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kWhite, letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          ),
          // Right accent panel
          Container(
            width: 360,
            decoration: const BoxDecoration(color: _kCard),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(color: _kBlue, shape: BoxShape.circle, border: Border.all(color: _kCyan, width: 3)),
                  child: const Center(child: Text('📋', style: TextStyle(fontSize: 60))),
                ),
                const SizedBox(height: 24),
                Text('Attendance\nTracker', textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: _kWhite)),
                const SizedBox(height: 8),
                Text('v1.0  ·  Flutter Web', style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 02 — Agenda (Two-col grid)
// ════════════════════════════════════════════════════════════════════════════
class _GridItem {
  final String num, title, desc;
  const _GridItem(this.num, this.title, this.desc);
}

class _TwoColGrid extends StatelessWidget {
  final String heading, subtitle;
  final List<_GridItem> items;
  const _TwoColGrid({required this.heading, required this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(heading),
        const SizedBox(height: 4),
        _sub(subtitle),
        _divider(),
        Expanded(
          child: LayoutBuilder(builder: (_, bc) {
            final cols = bc.maxWidth > 600 ? 2 : 1;
            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 4.5,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return _card(
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(item.num, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _kCyan)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kWhite)),
                            Text(item.desc, style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 03 — System Overview
// ════════════════════════════════════════════════════════════════════════════
class _SystemOverviewSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stack = [
      ('⚡ Framework',  'Flutter 3 + Dart',       'Runs in browser — no installation needed'),
      ('🗄 Local DB',   'Sembast / IndexedDB',     'Offline-first, persistent browser storage'),
      ('☁ Cloud DB',   'Supabase PostgreSQL',      'Optional cloud sync — toggle in Settings'),
      ('🔒 Auth',       'bcrypt + multi-modal',     'Password, card, QR, barcode, face'),
      ('📊 Charts',     'fl_chart',                 'Bar & pie charts in reports/dashboard'),
      ('📤 Export',     'CSV · Excel · PDF',        'Flexible report downloads'),
    ];

    const layers = [
      ('Browser / Flutter Web Client',    _kBlue),
      ('Riverpod State Management',        _kCard),
      ('Abstract Data Source Interface',   _kCard),
      ('Local: Sembast/IndexedDB  ·  Remote: Supabase', Color(0xFF1A3A6E)),
      ('GoRouter (Role-guarded nav)',       _kCard),
      ('face-api.js (JS bridge)',           Color(0xFF2A1A5E)),
    ];

    return _SlidePadding(child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — stack
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading('System Overview'),
              _sub('Cross-platform web app · offline-first · cloud-ready'),
              _divider(),
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stack.length,
                  separatorBuilder: (context2, idx) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final (lbl, val, note) = stack[i];
                    return _card(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(lbl),
                              const SizedBox(height: 2),
                              Text(val, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kWhite)),
                              Text(note, style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                            ],
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right — arch diagram
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              _label('Architecture'),
              const SizedBox(height: 10),
              ...layers.map((l) {
                final (name, color) = l;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                  child: Text(name, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: _kWhite, fontWeight: FontWeight.w500)),
                );
              }),
              Center(child: _sub('↕  toggleable at runtime')),
            ],
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 04 — Auth Flows
// ════════════════════════════════════════════════════════════════════════════
class _AuthFlowsSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const methods = [
      ('🔑', 'Password',         _kBlue,                   ['Username + password form', 'bcrypt hash verification', 'Always available (cannot disable)']),
      ('💳', 'RFID / Card',      Color(0xFF7C3AED),        ['HID keyboard emulator', 'Swipe fires Enter keystroke', 'Lookup by card_id in DB']),
      ('📱', 'QR Code',          Color(0xFF069579),        ['Camera scan via mobile_scanner', 'Encodes user UUID', 'Instant match — no typing']),
      ('⬛', 'Barcode',          Color(0xFFD97706),        ['Same camera as QR', 'Code128, EAN-13, Code39…', 'Maps to card_id field']),
      ('👤', 'Face Recognition', Color(0xFFDC2626),        ['face-api.js (web-only)', '128-float descriptor match', 'Euclidean distance < 0.6']),
    ];

    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Authentication Flows'),
        _sub('5 configurable login methods — each independently toggleable by Super Admin'),
        _divider(),
        Expanded(
          child: Row(
            children: methods.map((m) {
              final (icon, name, color, steps) = m;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(top: BorderSide(color: color, width: 4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        Text(name, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kWhite)),
                        const SizedBox(height: 8),
                        Divider(color: color, thickness: 1),
                        const SizedBox(height: 6),
                        ...steps.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $s', style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFF0A285E), borderRadius: BorderRadius.circular(8)),
          child: Text(
            '⚙  Super Admin can enable/disable RFID, QR, Barcode, and Face tabs — Password is always present.',
            style: GoogleFonts.inter(fontSize: 11, color: _kCyan, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 05 — Time Log / Scanner
// ════════════════════════════════════════════════════════════════════════════
class _TimeLogSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Scan / Type ID',     'RFID, manual entry\nor camera scan',      _kBlue),
      ('2', 'Validate Pattern',   'ID checked against\nactive regex patterns', Color(0xFF7C3AED)),
      ('3', 'Lookup Student',     'Must exist & not\nsoft-deleted in DB',      Color(0xFF069579)),
      ('4', 'Check Daily Count',  'Max 4 logs\nper student per day',           _kOrange),
      ('5', 'Determine Status',   'AM In→Out\nPM In→Out auto-advances',        Color(0xFFDC2626)),
      ('6', 'Write Record',       'Timestamp HH:mm:ss\nto attendances table',  Color(0xFF06708A)),
    ];

    const states = [
      ('AM  IN',  _kGreen),
      ('AM  OUT', _kOrange),
      ('PM  IN',  _kBlue),
      ('PM  OUT', _kRed),
    ];

    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Time Log — Core Scanner Flow'),
        _sub('Real-time attendance capture with 4-state session tracking'),
        _divider(),
        // Flow steps
        Expanded(
          flex: 4,
          child: Row(
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final (num, title, desc, color) = e.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(top: BorderSide(color: color, width: 3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(num, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                              const SizedBox(height: 6),
                              Text(title, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _kWhite)),
                              const SizedBox(height: 4),
                              Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 9.5, color: _kMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Icon(Icons.arrow_forward_ios_rounded, color: _kCyan, size: 12),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _label('4-State Session Tracking — per student, per day'),
        const SizedBox(height: 10),
        // States
        Expanded(
          flex: 3,
          child: Row(
            children: states.asMap().entries.map((e) {
              final i = e.key;
              final (label, color) = e.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Text(label, textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: _kWhite)),
                        ),
                      ),
                    ),
                    if (i < states.length - 1)
                      Text('→', style: GoogleFonts.inter(fontSize: 20, color: _kCyan, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Quick facts
        Wrap(
          spacing: 12, runSpacing: 6,
          children: const [
            '🕐  Live clock updates every second',
            '📋  Last 10 scans shown in history panel',
            '✅  3-second success/error message',
            '🔁  Field auto-clears after each scan',
          ].map((f) => Text(f, style: TextStyle(fontSize: 10, color: _kMuted))).toList(),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 06 — Attendance & Reports
// ════════════════════════════════════════════════════════════════════════════
class _AttendanceReportsSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Attendance Log & Reports'),
        _sub('View, analyze, and export attendance data'),
        _divider(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left — Attendance Log
              Expanded(
                child: _card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('📅  Attendance Log  ·  /attendance'),
                      const SizedBox(height: 12),
                      ...[
                        ('Date picker', 'Calendar — select any date'),
                        ('Table columns', 'ID · Name · AM In · AM Out · PM In · PM Out'),
                        ('Sort order', 'Newest updated first'),
                        ('Access level', 'All roles — Staff, Admin, Super Admin'),
                        ('Data source', 'attendances table filtered by created_date'),
                      ].map((r) {
                        final (k, v) = r;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 110, child: Text(k, style: GoogleFonts.inter(fontSize: 11, color: _kCyan, fontWeight: FontWeight.w600))),
                              Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 11, color: _kMuted))),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Right — Reports
              Expanded(
                child: _card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('📊  Reports  ·  /reports  ·  Admin+'),
                      const SizedBox(height: 12),
                      ...[
                        ('📅', 'Date Range Picker', 'Select From / To dates (defaults today)'),
                        ('📈', 'Bar Chart', 'Day-by-day attendance counts'),
                        ('👥', 'Per-Student Table', 'Paginated 10 rows/page · ID, Name, # logs'),
                        ('⬇', 'CSV Export', 'Date, Student ID, Name, Status, Time In/Out'),
                        ('📗', 'Excel Export', '.xlsx — same columns as CSV'),
                        ('📄', 'PDF Export', 'Formatted report with chart + full table'),
                      ].map((r) {
                        final (icon, title, desc) = r;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: GoogleFonts.inter(fontSize: 11, color: _kWhite, fontWeight: FontWeight.w700)),
                                  Text(desc, style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                                ],
                              )),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 07 — Management
// ════════════════════════════════════════════════════════════════════════════
class _ManagementSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const panels = [
      (
        '🎓', 'Students', '/students', _kBlue,
        [
          ('List View',    'Search by name or ID number'),
          ('Soft Delete',  'Marks is_deleted=1, data retained'),
          ('Add Student',  'ID No., Names, DOB, Sex, Course'),
          ('Edit Student', 'Update any field, re-validates ID'),
          ('ID unique',    'Duplicate check on save'),
          ('Course link',  'Dropdown from courses table'),
        ]
      ),
      (
        '📚', 'Courses', '/courses', _kGreen,
        [
          ('course_code',  'Unique identifier (e.g. BSCS)'),
          ('course_name',  'Full descriptive name'),
          ('year_level',   'e.g. 1st Year, 2nd Year'),
          ('Add / Edit',   'Standard form with validation'),
          ('Delete',       'Removes course record only'),
          ('Student link', 'Students retain course reference'),
        ]
      ),
      (
        '🔢', 'ID Patterns', '/patterns', _kOrange,
        [
          ('Mask input',   '##-E###-## type format'),
          ('Auto-regex',   r'Compiled to ^\d{2}-E\d{3}-\d{2}$'),
          ('Active/Off',   'Toggle per pattern'),
          ('Scanner gate', 'Rejects IDs not matching active patterns'),
          ('Multiple',     'Define many patterns simultaneously'),
          ('No patterns',  'Disables format validation entirely'),
        ]
      ),
    ];

    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Student, Course & ID Pattern Management'),
        _sub('Admin-level data management features'),
        _divider(),
        Expanded(
          child: Row(
            children: panels.map((p) {
              final (icon, title, route, color, items) = p;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(top: BorderSide(color: color, width: 4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
                        const SizedBox(height: 6),
                        Center(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _kWhite))),
                        Center(child: Text(route, style: GoogleFonts.inter(fontSize: 10, color: _kMuted, fontStyle: FontStyle.italic))),
                        Divider(color: color, thickness: 1, height: 16),
                        ...items.map((item) {
                          final (k, v) = item;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(k, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                Text(v, style: GoogleFonts.inter(fontSize: 10, color: _kMuted)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 08 — User Management & Settings
// ════════════════════════════════════════════════════════════════════════════
class _UserSettingsSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const userRows = [
      ('Add User',         'Username · Password · Role (staff / admin / super_admin)'),
      ('Edit User',        'Update username, role, optional new password'),
      ('Delete User',      'Blocked: self-delete & last super_admin delete'),
      ('QR Credentials',   'User UUID encoded as QR — for QR login'),
      ('Card ID',          'Assign RFID/barcode card (unique per user)'),
      ('Face Enroll',      'Live camera → 128-float descriptor stored as JSON'),
    ];
    const settingRows = [
      ('🏠 Initial Page',       'Login screen  or  Scanner (direct open)'),
      ('🔐 Auth Methods',       'Toggle RFID / QR / Barcode / Face tabs'),
      ('🗄 Database',           'Switch Local (Sembast) ↔ Remote (Supabase)'),
      ('💾 Manual Backup',      'Export full JSON snapshot of all data'),
      ('📥 Restore / Import',   'Import JSON backup or CSV attendance file'),
      ('⏰ Scheduled Backup',   'Set clock times — auto-download while tab open'),
    ];

    Widget infoTable(List<(String, String)> rows) => Column(
      children: rows.asMap().entries.map((e) {
        final i = e.key;
        final (k, v) = e.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: i % 2 == 0 ? _kCardAlt : _kCard,
            borderRadius: BorderRadius.circular(6),
          ),
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(width: 120, child: Text(k, style: GoogleFonts.inter(fontSize: 11, color: _kCyan, fontWeight: FontWeight.w600))),
              Expanded(child: Text(v, style: GoogleFonts.inter(fontSize: 10, color: _kMuted))),
            ],
          ),
        );
      }).toList(),
    );

    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('User Management & Settings'),
        _sub('Super Admin — full control over users and configuration'),
        _divider(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('👥  User Management  ·  /users'),
                    const SizedBox(height: 10),
                    infoTable(userRows),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('⚙  Settings  ·  /settings'),
                    const SizedBox(height: 10),
                    infoTable(settingRows),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 09 — Data & Backup
// ════════════════════════════════════════════════════════════════════════════
class _DataBackupSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Data Management & Backup'),
        _sub('Dual-database architecture with automatic backup scheduling'),
        _divider(),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              // Local
              Expanded(
                child: _card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('🖥  Local — Sembast/IndexedDB'),
                      const SizedBox(height: 12),
                      ...[
                        'Works completely offline — no internet needed',
                        'Data stored in browser\'s IndexedDB',
                        'Persistent storage requested on startup',
                        'Instant read/write — no network latency',
                        'Default mode on first launch',
                      ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded, color: _kGreen, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: GoogleFonts.inter(fontSize: 11, color: _kMuted))),
                        ]),
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Cloud
              Expanded(
                child: _card(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('☁  Cloud — Supabase PostgreSQL'),
                      const SizedBox(height: 12),
                      ...[
                        'Real PostgreSQL database in the cloud',
                        'Configure URL + Anon Key in Settings',
                        'Test Connection button before switching',
                        'Toggle between local & cloud at any time',
                        'Same abstract interface — zero code change',
                      ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          const Icon(Icons.check_circle_rounded, color: _kBlue, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: GoogleFonts.inter(fontSize: 11, color: _kMuted))),
                        ]),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(8)),
          child: Text('⚙  Settings → Database → Toggle  «Use Remote»  to switch at runtime',
              textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kWhite)),
        ),
        const SizedBox(height: 14),
        _label('Backup & Restore'),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 5,
            children: const [
              ('📤 Manual Export',      'Full JSON snapshot — students, courses, attendance, patterns'),
              ('📥 Restore from JSON',  'Re-import backup file, skips duplicates (safe merge)'),
              ('📄 CSV Import',         'Re-import attendance-only CSV from Reports export'),
              ('⏰ Scheduled Backup',   'Set clock times (e.g. 12:00, 18:00) · checks every 30 s'),
            ].map((r) {
              final (k, v) = r;
              return _card(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  SizedBox(width: 130, child: Text(k, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kOrange))),
                  Expanded(child: Text(v, style: TextStyle(fontSize: 10, color: _kMuted))),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 10 — Role Matrix
// ════════════════════════════════════════════════════════════════════════════
class _RoleMatrixSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      ('Time Log / Scanner',            true,  true,  true),
      ('Attendance Log View',           true,  true,  true),
      ('Dashboard',                     true,  true,  true),
      ('Student Management',            false, true,  true),
      ('Course Management',             false, true,  true),
      ('ID Pattern Configuration',      false, true,  true),
      ('Reports + Export',              false, true,  true),
      ('User Management',               false, false, true),
      ('Settings / Auth Methods',       false, false, true),
      ('Database Toggle (Local/Cloud)', false, false, true),
      ('Scheduled Auto-Backup',         false, false, true),
      ('Backup & Restore',              false, false, true),
    ];

    const roles = ['Staff', 'Admin', 'Super Admin'];
    const roleColors = [_kGreen, _kBlue, Color(0xFF7C3AED)];

    return _SlidePadding(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Role-Based Access Control'),
        _sub('Three permission tiers — enforced by GoRouter navigation guards'),
        _divider(),
        // Header
        Row(
          children: [
            const Expanded(flex: 5, child: SizedBox()),
            ...List.generate(3, (i) => Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: roleColors[i], borderRadius: BorderRadius.circular(6)),
                child: Text(roles[i], textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kWhite)),
              ),
            )),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            itemBuilder: (_, i) {
              final (feat, staff, admin, sup) = features[i];
              final bg = i % 2 == 0 ? _kCardAlt : _kCard;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    Expanded(flex: 5, child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(feat, style: GoogleFonts.inter(fontSize: 11, color: _kWhite)),
                    )),
                    ...[staff, admin, sup].map((v) => Expanded(
                      flex: 2,
                      child: Center(child: Text(v ? '✓' : '—',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: v ? _kGreen : _kCard))),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _badge('✓  Full Access', _kGreen, _kNavy),
          const SizedBox(width: 8),
          _badge('—  No Access', _kMuted, _kNavy),
          const SizedBox(width: 8),
          _badge('Enforced by GoRouter redirect guards', _kCard, _kMuted),
        ]),
      ],
    ));
  }

  Widget _badge(String t, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
    child: Text(t, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// Slide 11 — Key Benefits
// ════════════════════════════════════════════════════════════════════════════
class _BenefitsSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const benefits = [
      ('🌐', 'Zero Installation',    'Runs entirely in the browser.\nNo software to install on client machines.'),
      ('📶', 'Offline-First',        'Local database works without internet.\nSwitch to cloud when ready.'),
      ('🔐', 'Multi-Modal Auth',     '5 login methods — use what fits your setup.\nToggle on/off from Settings.'),
      ('⚡', 'Instant Scan Logging', 'Sub-second attendance capture.\nAuto-advances AM/PM session state.'),
      ('📊', 'Built-in Analytics',   'Date-range charts + per-student tables.\nExport to CSV, Excel, or PDF.'),
      ('🛡', 'Role-Based Security',  'Staff, Admin, Super Admin tiers.\nGoRouter enforces at navigation level.'),
      ('💾', 'Smart Backup',         'Manual + scheduled auto-backup to JSON.\nRestore from any backup file.'),
      ('📡', 'Cloud-Ready',          'One toggle to switch to Supabase cloud DB.\nSame interface, zero code change.'),
      ('👤', 'Face Enroll Login',    'Optional face recognition via face-api.js.\nWeb-only, no extra hardware needed.'),
    ];

    return _SlidePadding(child: Column(
      children: [
        Text('Why Attendance Tracker?', textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: _kWhite)),
        const SizedBox(height: 4),
        Text('Built for real campus environments — flexible, resilient, and easy to deploy.',
            textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: _kMuted, fontStyle: FontStyle.italic)),
        _divider(),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.8,
            children: benefits.map((b) {
              final (icon, title, desc) = b;
              return _card(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kWhite)),
                        const SizedBox(height: 2),
                        Text(desc, style: GoogleFonts.inter(fontSize: 9.5, color: _kMuted)),
                      ],
                    )),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(8)),
          child: Text('Ready to deploy — contact us to schedule a live demo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _kWhite)),
        ),
      ],
    ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Data model
// ════════════════════════════════════════════════════════════════════════════
class _Slide {
  final String title;
  final Widget Function(BuildContext) content;
  const _Slide({required this.title, required this.content});
}
