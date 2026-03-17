import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../models/student.dart';
import '../abstract/student_source.dart';

class RemoteStudentSource implements StudentSource {
  SupabaseClient get _client => Supabase.instance.client;
  static const _uuid = Uuid();

  static const _select = '*, courses(course_name, course_code)';

  @override
  Future<List<Student>> getAll() async {
    final rows = await _client
        .from('students')
        .select(_select)
        .eq('is_deleted', false)
        .order('ln');
    return (rows as List).map((r) => Student.fromMap(_flatten(r))).toList();
  }

  @override
  Future<Student?> getById(String id) async {
    final rows = await _client
        .from('students')
        .select(_select)
        .eq('id', id)
        .eq('is_deleted', false);
    final list = rows as List;
    return list.isEmpty ? null : Student.fromMap(_flatten(list.first));
  }

  @override
  Future<Student?> getByIdNumber(String idNumber) async {
    final rows = await _client
        .from('students')
        .select(_select)
        .eq('idnumber', idNumber)
        .eq('is_deleted', false);
    final list = rows as List;
    return list.isEmpty ? null : Student.fromMap(_flatten(list.first));
  }

  @override
  Future<void> create(Student student) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('students').insert({
      ...student.toMap(),
      'id': student.id.isEmpty ? _uuid.v4() : student.id,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> update(Student student) async {
    await _client.from('students').update({
      ...student.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', student.id);
  }

  @override
  Future<void> softDelete(String id) async {
    await _client.from('students').update({
      'is_deleted': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<List<Student>> search(String query) async {
    final q = '%$query%';
    final rows = await _client
        .from('students')
        .select(_select)
        .eq('is_deleted', false)
        .or('idnumber.ilike.$q,fn.ilike.$q,ln.ilike.$q');
    return (rows as List).map((r) => Student.fromMap(_flatten(r))).toList();
  }

  // Flatten nested courses object from Supabase join
  Map<String, dynamic> _flatten(Map<String, dynamic> row) {
    final result = Map<String, dynamic>.from(row);
    final courseData = result.remove('courses');
    if (courseData is Map) {
      result['course_name'] = courseData['course_name'];
      result['course_code'] = courseData['course_code'];
    }
    return result;
  }
}
