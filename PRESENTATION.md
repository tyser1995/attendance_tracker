# Presentation Guide

The Attendance Tracker includes a built-in slide deck accessible at `/presentation` — no login required.

---

## Web Presentation (In-App Route)

The Flutter app exposes `/presentation` as a **fully public route** — no login required.

### Step 1 — Run the App

```bash
# Development
flutter run -d chrome

# Or serve the production build
flutter build web --release
python -m http.server 8080 --directory build/web
```

### Step 2 — Open the Presentation

```
http://localhost:8080/presentation
```

Share this URL with anyone on the same network:

```
http://<your-local-ip>:8080/presentation
```

Find your local IP: open Command Prompt → `ipconfig` → **IPv4 Address**.

### Navigation Controls

| Input | Action |
|---|---|
| `→` Arrow key | Next slide |
| `←` Arrow key | Previous slide |
| `Space` | Next slide |
| Swipe right | Previous slide (mobile) |
| Swipe left | Next slide (mobile) |
| ☰ Menu (top-left) | Open slide list — click any slide to jump |
| **Go to App** (top-right) | Redirects to `/login` |

### How the Route Works

The route is registered in `lib/config/router.dart` as a **public path** — the auth redirect guard skips it:

```dart
// lib/config/router.dart
const _publicPaths = ['/login', '/presentation'];

// In the redirect callback:
if (_publicPaths.contains(path)) return null;  // allow without auth
```

The slide screen lives at:

```
lib/screens/presentation/presentation_screen.dart
```

### Customizing Slides

Each slide is a Flutter widget defined inside `_buildSlides()` in `presentation_screen.dart`.

**To edit slide content** — find the matching class and update the text:

```
_CoverSlide           → Slide 01 — Cover
_TwoColGrid           → Slide 02 — Agenda
_SystemOverviewSlide  → Slide 03 — System Overview
_AuthFlowsSlide       → Slide 04 — Authentication Flows
_TimeLogSlide         → Slide 05 — Time Log / Scanner
_AttendanceReportsSlide → Slide 06 — Attendance & Reports
_ManagementSlide      → Slide 07 — Student, Course & Patterns
_UserSettingsSlide    → Slide 08 — User Management & Settings
_DataBackupSlide      → Slide 09 — Data & Backup
_RoleMatrixSlide      → Slide 10 — Role Access Matrix
_BenefitsSlide        → Slide 11 — Key Benefits
```

**To add a new slide** — append a `_Slide` entry to `_buildSlides()`:

```dart
_Slide(
  title: 'My New Slide',
  content: (context) => _MyNewSlideWidget(),
),
```

**To change the brand colors** — edit the constants at the top of the file:

```dart
const _kNavy  = Color(0xFF0D1B3E);  // background
const _kCyan  = Color(0xFF00C2FF);  // accent / highlights
const _kBlue  = Color(0xFF1A73E8);  // primary action color
const _kCard  = Color(0xFF1E2D5E);  // card background
const _kMuted = Color(0xFFA0B4D8);  // secondary text
```

---

## File Reference

```
attendance_tracker/
├── lib/
│   └── screens/
│       └── presentation/
│           └── presentation_screen.dart   ← Flutter web slide deck
├── lib/config/router.dart                 ← /presentation public route
└── PRESENTATION.md                        ← This guide
```
