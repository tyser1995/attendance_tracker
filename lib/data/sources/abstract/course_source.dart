import '../../../models/course.dart';

abstract class CourseSource {
  Future<List<Course>> getAll();
  Future<Course?> getById(String id);
  Future<void> create(Course course);
  Future<void> update(Course course);
  Future<void> delete(String id);
}
