import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/course.dart';
import '../abstract/course_source.dart';

class RemoteCourseSource implements CourseSource {
  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  @override
  Future<List<Course>> getAll() async {
    final rows = await _client.from('courses').select().order('course_name');
    return (rows as List).map((r) => Course.fromMap(r)).toList();
  }

  @override
  Future<Course?> getById(String id) async {
    final rows = await _client.from('courses').select().eq('id', id);
    final list = rows as List;
    return list.isEmpty ? null : Course.fromMap(list.first);
  }

  @override
  Future<void> create(Course course) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('courses').insert({
      ...course.toMap(),
      'id': course.id.isEmpty ? _uuid.v4() : course.id,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> update(Course course) async {
    await _client.from('courses').update({
      ...course.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', course.id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }
}
