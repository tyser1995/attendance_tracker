# Attendance Tracker v2

> Successor to [tyser1995/attendance-tracking](https://github.com/tyser1995/attendance-tracking)

A Flutter web app for tracking student attendance in educational institutions. Supports dual-session (AM/PM) time logging via ID entry or barcode scan, role-based access control, and a choice between local (offline) and Supabase (cloud) storage.

---

## Features

| Feature | Description |
|---|---|
| **Time Log** | Scan or type a student ID to log attendance. Auto-advances through AM In → AM Out → PM In → PM Out each day. |
| **Attendance Log** | Browse all attendance records, filter by date. |
| **Dashboard** | Live today summary — present/absent counts, AM/PM totals, attendance rate chart. |
| **Students** | Add, edit, soft-delete student profiles. Duplicate ID number is rejected. |
| **Courses** | Manage course catalogue (code, name, year level). Duplicate course code is rejected. |
| **ID Patterns** | Define allowed ID formats using mask syntax (e.g. `##-#####-#`). Scanned IDs are validated before logging. |
| **Reports** | Date-range reports with bar chart, per-student log counts, export to CSV / Excel / PDF. |
| **User Management** | Super admin can create, edit, and delete user accounts. |
| **Settings** | Configure initial page, switch DB source, manage Supabase credentials. |

---

## Role-Based Access

| Screen | Super Admin | Admin | Staff |
|---|:---:|:---:|:---:|
| Time Log (`/scanner`) | ✓ | ✓ | ✓ |
| Attendance Log (`/attendance`) | ✓ | ✓ | ✓ |
| Students (`/students`) | ✓ | ✓ | — |
| Courses (`/courses`) | ✓ | ✓ | — |
| ID Patterns (`/patterns`) | ✓ | ✓ | — |
| Reports (`/reports`) | ✓ | ✓ | — |
| User Management (`/users`) | ✓ | — | — |
| Settings (`/settings`) | ✓ | — | — |

---

## Default Accounts

Seeded automatically on first launch (empty database only):

| Username | Password | Role |
|---|---|---|
| `superadmin` | `superadmin123` | Super Admin |
| `admin` | `admin123` | Admin |
| `staff` | `staff123` | Staff |

> **Change default passwords** after first login via **User Management**.

---

## Tech Stack

| Layer | Library / Tool |
|---|---|
| Framework | Flutter 3 · Dart SDK ^3.10 |
| State management | flutter_riverpod 2 |
| Navigation | go_router 14 |
| Local database | sembast 3 + sembast_web (IndexedDB on web) |
| Cloud database | supabase_flutter 2 |
| Charts | fl_chart |
| Calendar picker | table_calendar |
| Export | pdf · printing · excel |
| Environment | flutter_dotenv |
| UI | google_fonts · Material 3 |

---

## Project Structure

```
attendance_tracker/
├── lib/
│   ├── main.dart                   # Bootstrap — DB init, Supabase init
│   ├── app.dart                    # MaterialApp + router wiring
│   ├── config/router.dart          # GoRouter routes + auth/role guard
│   ├── core/                       # Theme, utils, report exporter, download helpers
│   ├── models/                     # AttendanceRecord, Student, Course, IdPattern, AppUser
│   ├── providers/                  # Riverpod providers
│   ├── data/
│   │   ├── local/                  # Sembast helper + platform factory (io/web/stub)
│   │   └── sources/
│   │       ├── abstract/           # Source interfaces
│   │       ├── local/              # Sembast implementations
│   │       └── remote/             # Supabase implementations
│   └── screens/
│       ├── auth/                   # Login
│       ├── scanner/                # Time Log (initial page)
│       ├── attendance/
│       ├── dashboard/
│       ├── students/
│       ├── courses/
│       ├── patterns/
│       ├── reports/
│       ├── users/                  # User management (super admin only)
│       └── settings/
├── scripts/
│   ├── start_server.bat            # Starts local web server (Python or Node)
│   ├── install_autostart.bat       # Registers server in Windows Task Scheduler
│   └── uninstall_autostart.bat     # Removes auto-start
└── web/                            # Flutter web entry point
```

---

## For Developers — Getting Started

> Flutter is only required on the **build machine**. Other computers that just need to run the app do not need Flutter installed — see [Deploying to Other Computers](#deploying-to-other-computers-no-flutter-required) below.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.10)
- Supabase project — optional, app works fully offline

### 1. Clone

```bash
git clone https://github.com/tyser1995/attendance_tracker.git
cd attendance_tracker
flutter pub get
```

### 2. Environment file (optional)

Create `.env` in the project root to pre-fill Supabase credentials:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Leave blank to run in local-only mode. Credentials can also be set at runtime in **Settings**.

### 3. Run in development

```bash
# Browser (localhost only)
flutter run -d chrome

# Expose to local network (other devices on same Wi-Fi)
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

### 4. Build for production

```bash
flutter build web --release
```

Output goes to `build\web\` — plain HTML/JS/CSS, no Flutter runtime needed to serve it.

---

## Installing on Windows (Auto-start on Boot)

Runs the app automatically whenever Windows starts. **Flutter is not required on this machine** — only the built `build\web\` folder and a file server.

### Requirements

Install one of the following on the Windows machine:

| Option | Download | Notes |
|---|---|---|
| **Python 3** _(recommended)_ | [python.org/downloads](https://python.org/downloads) | Check **"Add Python to PATH"** during install |
| **Node.js** | [nodejs.org](https://nodejs.org) | LTS version recommended |

### Steps

```bat
REM 1. Build on your dev machine (requires Flutter)
flutter build web --release

REM 2. Copy build\web\ and the scripts\ folder to the target Windows machine

REM 3. Test the server manually — opens http://localhost:8080
scripts\start_server.bat

REM 4. Register auto-start (right-click → Run as administrator)
scripts\install_autostart.bat
```

After step 4, the server launches automatically on every Windows login.

```bat
REM Start immediately without rebooting
schtasks /run /tn "AttendanceTrackerServer"

REM Remove auto-start
scripts\uninstall_autostart.bat
```

### Access URLs

| From | URL |
|---|---|
| This computer | `http://localhost:8080` |
| Other devices on same Wi-Fi / LAN | `http://<host-local-ip>:8080` |

Find your local IP: open Command Prompt → `ipconfig` → **IPv4 Address** under your active network adapter (e.g. `192.168.1.10`).

### Reset to clean state

To wipe all data and keep only the default user accounts:

1. Open Chrome → `http://localhost:8080`
2. `F12` → **Application** tab → **Storage** → **Clear site data**
3. Refresh — only the 3 default accounts are re-seeded

---

## Deploying to Other Computers (No Flutter Required)

Once built, the app is just static files. Any computer on your network can run it with a tiny file server — **no Flutter, no Dart, no source code needed**.

### What to copy to the other PC

```
build\web\              ← the entire built folder
scripts\start_server.bat
scripts\install_autostart.bat   ← optional, for auto-start
```

### Option A — Python (recommended)

1. Install [Python 3](https://python.org/downloads) — check **"Add Python to PATH"**
2. Double-click `start_server.bat`
3. Open `http://localhost:8080`

### Option B — Node.js

1. Install [Node.js](https://nodejs.org)
2. Double-click `start_server.bat`
3. Open `http://localhost:8080`

The `start_server.bat` script automatically detects Python or Node.js and uses whichever is available.

### Option C — Zero install (Caddy portable server)

No Python or Node.js needed at all.

1. Download `caddy_windows_amd64.exe` from [github.com/caddyserver/caddy/releases](https://github.com/caddyserver/caddy/releases)
2. Rename it to `caddy.exe` and place it inside `build\web\`
3. Create `build\web\run.bat` with this content:
   ```bat
   @echo off
   start "" "http://localhost:8080"
   caddy file-server --root . --listen :8080
   ```
4. Double-click `run.bat`

> **Note:** Each browser/device stores data in its own local IndexedDB. To share data across multiple computers, switch to Supabase in **Settings → Database**.

---

## Supabase Setup (optional)

Run the following SQL in your Supabase SQL Editor to create the required tables:

```sql
create table if not exists courses (
  id text primary key,
  course_code text not null unique,
  course_name text not null,
  year_level text not null default ''
);

create table if not exists students (
  id text primary key,
  idnumber text not null unique,
  fn text not null,
  ln text not null,
  mn text,
  dob text,
  sex text,
  course_id text references courses(id),
  is_deleted integer not null default 0
);

create table if not exists attendances (
  id text primary key,
  idnumber text not null,
  name text not null default '',
  time_in text,
  time_out text,
  created_date text not null,
  status integer not null default 1,  -- 1=AM In, 2=AM Out, 3=PM In, 4=PM Out
  created_at text,
  updated_at text
);

create table if not exists id_patterns (
  id text primary key,
  pattern text not null unique,
  regex text not null,
  status text not null default 'active'
);

create table if not exists users (
  id text primary key,
  username text not null unique,
  password_hash text not null,
  role text not null default 'staff'  -- 'super_admin' | 'admin' | 'staff'
);

create index if not exists idx_students_idnumber on students(idnumber);
create index if not exists idx_attendances_date on attendances(created_date);
create index if not exists idx_attendances_idnumber on attendances(idnumber);
```

Switch to Supabase at runtime: **Settings → Database → toggle to Supabase**.

---

## Attendance Status Reference

| Status | Label |
|---|---|
| 1 | AM Time In |
| 2 | AM Time Out |
| 3 | PM Time In |
| 4 | PM Time Out |

Each student ID scan auto-advances to the next status for the current day. Maximum 4 logs per student per day.

---

## Initial Page Setting

In **Settings → Initial Page** (super admin only), choose between:

- **Login Page** _(default)_ — users must sign in before accessing anything
- **Scanner** — app opens directly on the Time Log screen; a **Login** button appears in the top bar for staff who need to manage data

---

## License

MIT
