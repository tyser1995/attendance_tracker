import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../../../models/id_pattern.dart';
import '../../local/sembast_helper.dart';
import '../abstract/id_pattern_source.dart';

class LocalIdPatternSource implements IdPatternSource {
  final _helper = SembastHelper.instance;
  static const _uuid = Uuid();

  Future<Database> get _db async => _helper.database;

  @override
  Future<List<IdPattern>> getAll() async {
    final db = await _db;
    final records = await idPatternsStore.find(db);
    return records.map((r) => IdPattern.fromMap({...r.value, 'id': r.key})).toList();
  }

  @override
  Future<List<IdPattern>> getActive() async {
    final db = await _db;
    final records = await idPatternsStore.find(db,
        finder: Finder(filter: Filter.equals('status', 'active')));
    return records.map((r) => IdPattern.fromMap({...r.value, 'id': r.key})).toList();
  }

  @override
  Future<void> create(IdPattern pattern) async {
    final db = await _db;
    final existing = await idPatternsStore.findFirst(db,
        finder: Finder(filter: Filter.equals('pattern', pattern.pattern.trim())));
    if (existing != null) {
      throw Exception('Pattern "${pattern.pattern}" already exists.');
    }
    final id = pattern.id.isEmpty ? _uuid.v4() : pattern.id;
    final map = pattern.toMap();
    map.remove('id');
    await idPatternsStore.record(id).put(db, map);
  }

  @override
  Future<void> toggleStatus(String id) async {
    final db = await _db;
    final val = await idPatternsStore.record(id).get(db);
    if (val == null) return;
    final current = val['status'] as String;
    final next = current == 'active' ? 'inactive' : 'active';
    await idPatternsStore.record(id).update(db, {'status': next});
  }

  @override
  Future<void> delete(String id) async {
    final db = await _db;
    await idPatternsStore.record(id).delete(db);
  }

  @override
  Future<void> activateAll() async {
    final db = await _db;
    final records = await idPatternsStore.find(db);
    for (final r in records) {
      await idPatternsStore.record(r.key).update(db, {'status': 'active'});
    }
  }

  @override
  Future<void> deactivateAll() async {
    final db = await _db;
    final records = await idPatternsStore.find(db);
    for (final r in records) {
      await idPatternsStore.record(r.key).update(db, {'status': 'inactive'});
    }
  }
}
