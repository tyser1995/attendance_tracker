import '../../../models/student.dart';

abstract class StudentSource {
  Future<List<Student>> getAll();
  Future<Student?> getById(String id);
  Future<Student?> getByIdNumber(String idNumber);
  Future<void> create(Student student);
  Future<void> update(Student student);
  Future<void> softDelete(String id);
  Future<List<Student>> search(String query);
}
