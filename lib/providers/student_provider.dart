import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_config.dart';
import '../data/sources/abstract/student_source.dart';
import '../data/sources/local/local_student_source.dart';
import '../data/sources/remote/remote_student_source.dart';
import '../models/student.dart';
import 'db_config_provider.dart';

final studentSourceProvider = Provider<StudentSource>((ref) {
  final useRemote = ref.watch(useRemoteDbProvider);
  return useRemote ? RemoteStudentSource() : LocalStudentSource();
});

final studentRefreshProvider = StateProvider<int>((ref) => 0);
final studentSearchQueryProvider = StateProvider<String>((ref) => '');

final allStudentsProvider = FutureProvider<List<Student>>((ref) async {
  ref.watch(studentRefreshProvider);
  final query = ref.watch(studentSearchQueryProvider);
  final src = ref.read(studentSourceProvider);
  if (query.isEmpty) return src.getAll();
  return src.search(query);
});

final studentByIdProvider =
    FutureProvider.family<Student?, String>((ref, id) async {
  ref.watch(studentRefreshProvider);
  return ref.read(studentSourceProvider).getById(id);
});

class StudentNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String?> trialLimitError() async {
    if (!AppConfig.isTrial) return null;
    final src = ref.read(studentSourceProvider);
    final all = await src.getAll();
    if (all.length >= AppConfig.trialStudentLimit) {
      return 'Trial limit reached: maximum ${AppConfig.trialStudentLimit} students allowed.';
    }
    return null;
  }

  Future<bool> save(Student student, {bool isEdit = false}) async {
    state = const AsyncValue.loading();
    try {
      final src = ref.read(studentSourceProvider);
      if (!isEdit) {
        final limitError = await trialLimitError();
        if (limitError != null) {
          state = AsyncValue.error(limitError, StackTrace.current);
          return false;
        }
      }
      if (isEdit) {
        await src.update(student);
      } else {
        await src.create(student);
      }
      ref.read(studentRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> softDelete(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(studentSourceProvider).softDelete(id);
      ref.read(studentRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final studentNotifierProvider =
    NotifierProvider<StudentNotifier, AsyncValue<void>>(StudentNotifier.new);
