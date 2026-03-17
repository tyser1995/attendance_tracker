import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../../../models/student.dart';
import '../../local/sembast_helper.dart';
import '../abstract/student_source.dart';

class LocalStudentSource implements StudentSource {
  final _helper = SembastHelper.instance;
  static const _uuid = Uuid();

  Future<Database> get _db async => _helper.database;

  Future<Map<String, String>> _courseNameMap(Database db) async {
    final records = await coursesStore.find(db);
    return {
      for (final r in records)
        r.key: '${r.value['course_name'] ?? ''}|${r.value['course_code'] ?? ''}'
    };
  }

  Student _toStudent(RecordSnapshot<String, Map<String, Object?>> r,
      Map<String, String> courseMap) {
    final parts = courseMap[r.value['course_id']]?.split('|') ?? ['', ''];
    return Student.fromMap({
      ...r.value,
      'id': r.key,
      'course_name': parts[0],
      'course_code': parts[1],
    });
  }

  @override
  Future<List<Student>> getAll() async {
    final db = await _db;
    final courseMap = await _courseNameMap(db);
    final records = await studentsStore.find(db,
        finder: Finder(
          filter: Filter.equals('is_deleted', 0),
          sortOrders: [SortOrder('ln'), SortOrder('fn')],
        ));
    return records.map((r) => _toStudent(r, courseMap)).toList();
  }

  @override
  Future<Student?> getById(String id) async {
    final db = await _db;
    final val = await studentsStore.record(id).get(db);
    if (val == null) return null;
    final courseMap = await _courseNameMap(db);
    final parts = courseMap[val['course_id']]?.split('|') ?? ['', ''];
    return Student.fromMap({...val, 'id': id, 'course_name': parts[0], 'course_code': parts[1]});
  }

  @override
  Future<Student?> getByIdNumber(String idNumber) async {
    final db = await _db;
    final courseMap = await _courseNameMap(db);
    final record = await studentsStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('idnumber', idNumber),
          Filter.equals('is_deleted', 0),
        ])));
    if (record == null) return null;
    return _toStudent(record, courseMap);
  }

  @override
  Future<void> create(Student student) async {
    final db = await _db;
    final idNum = student.idNumber.trim();
    final existing = await studentsStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('idnumber', idNum),
          Filter.equals('is_deleted', 0),
        ])));
    if (existing != null) {
      throw Exception('Student ID "$idNum" is already registered.');
    }
    final id = student.id.isEmpty ? _uuid.v4() : student.id;
    final map = student.toMap();
    map.remove('id');
    map.remove('course_name');
    map.remove('course_code');
    await studentsStore.record(id).put(db, map);
  }

  @override
  Future<void> update(Student student) async {
    final db = await _db;
    final idNum = student.idNumber.trim();
    final existing = await studentsStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('idnumber', idNum),
          Filter.equals('is_deleted', 0),
        ])));
    if (existing != null && existing.key != student.id) {
      throw Exception('Student ID "$idNum" is already registered.');
    }
    final map = student.toMap();
    map.remove('id');
    map.remove('course_name');
    map.remove('course_code');
    await studentsStore.record(student.id).put(db, map);
  }

  @override
  Future<void> softDelete(String id) async {
    final db = await _db;
    await studentsStore.record(id).update(db, {'is_deleted': 1});
  }

  @override
  Future<List<Student>> search(String query) async {
    final db = await _db;
    final courseMap = await _courseNameMap(db);
    final q = query.toLowerCase();
    final records = await studentsStore.find(db,
        finder: Finder(
          filter: Filter.equals('is_deleted', 0),
          sortOrders: [SortOrder('ln'), SortOrder('fn')],
        ));
    return records
        .where((r) {
          final fn = (r.value['fn'] as String? ?? '').toLowerCase();
          final ln = (r.value['ln'] as String? ?? '').toLowerCase();
          final mn = (r.value['mn'] as String? ?? '').toLowerCase();
          final id = (r.value['idnumber'] as String? ?? '').toLowerCase();
          return fn.contains(q) || ln.contains(q) || mn.contains(q) || id.contains(q);
        })
        .map((r) => _toStudent(r, courseMap))
        .toList();
  }
}
