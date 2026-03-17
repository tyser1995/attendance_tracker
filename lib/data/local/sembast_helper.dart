import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../../core/auth_utils.dart';
import 'sembast_factory.dart';

// Store refs
final studentsStore = stringMapStoreFactory.store('students');
final coursesStore = stringMapStoreFactory.store('courses');
final attendancesStore = stringMapStoreFactory.store('attendances');
final idPatternsStore = stringMapStoreFactory.store('id_patterns');
final usersStore = stringMapStoreFactory.store('users');

class SembastHelper {
  static final SembastHelper instance = SembastHelper._();
  static Database? _db;

  SembastHelper._();

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final factory = getSembastFactory();
    String path;
    try {
      final dir = await getApplicationDocumentsDirectory();
      path = join(dir.path, 'attendance_v2.db');
    } catch (_) {
      path = 'attendance_v2.db'; // web fallback
    }
    return factory.openDatabase(path);
  }

  Future<void> seedIfEmpty() async {
    final db = await database;
    final userCount = await usersStore.count(db);
    if (userCount > 0) return;

    const uuid = Uuid();
    await usersStore.record(uuid.v4()).put(db, {
      'username': 'superadmin', 'password_hash': hashPassword('superadmin123'), 'role': 'super_admin',
    });
    await usersStore.record(uuid.v4()).put(db, {
      'username': 'admin', 'password_hash': hashPassword('admin123'), 'role': 'admin',
    });
    await usersStore.record(uuid.v4()).put(db, {
      'username': 'staff', 'password_hash': hashPassword('staff123'), 'role': 'staff',
    });
  }
}
