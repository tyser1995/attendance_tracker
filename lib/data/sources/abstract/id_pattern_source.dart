import '../../../models/id_pattern.dart';

abstract class IdPatternSource {
  Future<List<IdPattern>> getAll();
  Future<List<IdPattern>> getActive();
  Future<void> create(IdPattern pattern);
  Future<void> toggleStatus(String id);
  Future<void> delete(String id);
  Future<void> activateAll();
  Future<void> deactivateAll();
}
