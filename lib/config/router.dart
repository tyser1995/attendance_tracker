import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/db_config_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/scanner/scanner_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/students/students_screen.dart';
import '../screens/students/student_form_screen.dart';
import '../screens/students/student_detail_screen.dart';
import '../screens/courses/courses_screen.dart';
import '../screens/courses/course_form_screen.dart';
import '../screens/patterns/patterns_screen.dart';
import '../screens/patterns/pattern_form_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/users/users_screen.dart';

// Paths by minimum required role
const _adminPaths = ['/students', '/courses', '/patterns', '/reports'];
const _superAdminPaths = ['/settings', '/users'];

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  final initialPage = ref.watch(initialPageProvider);
  final scannerAsHome = initialPage == 'scanner';

  return GoRouter(
    initialLocation: '/scanner',
    redirect: (context, state) {
      final loggedIn = auth != null;
      final path = state.matchedLocation;
      final isLoginPage = path == '/login';
      final isScannerPage = path == '/scanner';

      if (!loggedIn) {
        if (isLoginPage) return null;
        // Allow unauthenticated scanner access when scanner is the home page
        if (isScannerPage && scannerAsHome) return null;
        return scannerAsHome ? '/scanner' : '/login';
      }

      // Logged in — bounce off login page
      if (isLoginPage) return '/scanner';

      // Super-admin-only paths
      if (_superAdminPaths.any((p) => path.startsWith(p))) {
        if (!auth.isSuperAdmin) return '/scanner';
      }

      // Admin-only paths (admin + super_admin)
      if (_adminPaths.any((p) => path.startsWith(p))) {
        if (!auth.isAdmin) return '/scanner';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/scanner', builder: (c, s) => const ScannerScreen()),
          GoRoute(path: '/attendance', builder: (c, s) => const AttendanceScreen()),
          GoRoute(
            path: '/students',
            builder: (c, s) => const StudentsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const StudentFormScreen()),
              GoRoute(
                path: ':id',
                builder: (c, s) => StudentDetailScreen(id: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) => StudentFormScreen(studentId: s.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/courses',
            builder: (c, s) => const CoursesScreen(),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const CourseFormScreen()),
              GoRoute(
                path: ':id/edit',
                builder: (c, s) => CourseFormScreen(courseId: s.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/patterns',
            builder: (c, s) => const PatternsScreen(),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const PatternFormScreen()),
            ],
          ),
          GoRoute(path: '/reports', builder: (c, s) => const ReportsScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
          GoRoute(path: '/users', builder: (c, s) => const UsersScreen()),
        ],
      ),
    ],
  );
});
