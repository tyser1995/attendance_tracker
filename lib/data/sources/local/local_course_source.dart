import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../../../models/course.dart';
import '../../local/sembast_helper.dart';
import '../abstract/course_source.dart';

class LocalCourseSource implements CourseSource {
  final _helper = SembastHelper.instance;
  static const _uuid = Uuid();

  Future<Database> get _db async => _helper.database;

  @override
  Future<List<Course>> getAll() async {
    final db = await _db;
    final records = await coursesStore.find(db,
        finder: Finder(sortOrders: [SortOrder('course_name')]));
    return records.map((r) => Course.fromMap({...r.value, 'id': r.key})).toList();
  }

  @override
  Future<Course?> getById(String id) async {
    final db = await _db;
    final val = await coursesStore.record(id).get(db);
    if (val == null) return null;
    return Course.fromMap({...val, 'id': id});
  }

  @override
  Future<void> create(Course course) async {
    final db = await _db;
    final code = course.courseCode.trim().toUpperCase();
    final existing = await coursesStore.findFirst(db,
        finder: Finder(filter: Filter.equals('course_code', code)));
    if (existing != null) {
      throw Exception('Course code "$code" already exists.');
    }
    final id = course.id.isEmpty ? _uuid.v4() : course.id;
    final map = course.toMap();
    map.remove('id');
    await coursesStore.record(id).put(db, map);
  }

  @override
  Future<void> update(Course course) async {
    final db = await _db;
    final code = course.courseCode.trim().toUpperCase();
    final existing = await coursesStore.findFirst(db,
        finder: Finder(filter: Filter.equals('course_code', code)));
    if (existing != null && existing.key != course.id) {
      throw Exception('Course code "$code" already exists.');
    }
    final map = course.toMap();
    map.remove('id');
    await coursesStore.record(course.id).put(db, map);
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await coursesStore.record(id).delete(db);
  }
}
