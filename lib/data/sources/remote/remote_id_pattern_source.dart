import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/id_pattern.dart';
import '../abstract/id_pattern_source.dart';

class RemoteIdPatternSource implements IdPatternSource {
  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  @override
  Future<List<IdPattern>> getAll() async {
    final rows = await _client.from('id_patterns').select().order('created_at', ascending: false);
    return (rows as List).map((e) => IdPattern.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<IdPattern>> getActive() async {
    final rows = await _client.from('id_patterns').select().eq('status', 'active');
    return (rows as List).map((e) => IdPattern.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> create(IdPattern pattern) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('id_patterns').insert({
      ...pattern.toMap(),
      'id': pattern.id.isEmpty ? _uuid.v4() : pattern.id,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> toggleStatus(String id) async {
    final rows = await _client.from('id_patterns').select().eq('id', id);
    final list = rows as List;
    if (list.isEmpty) return;
    final current = list.first['status'] as String;
    final next = current == 'active' ? 'inactive' : 'active';
    await _client.from('id_patterns').update({
      'status': next,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('id_patterns').delete().eq('id', id);
  }

  @override
  Future<void> activateAll() async {
    await _client.from('id_patterns').update({
      'status': 'active',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deactivateAll() async {
    await _client.from('id_patterns').update({
      'status': 'inactive',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
