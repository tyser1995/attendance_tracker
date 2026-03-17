import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/abstract/course_source.dart';
import '../data/sources/local/local_course_source.dart';
import '../data/sources/remote/remote_course_source.dart';
import '../models/course.dart';
import 'db_config_provider.dart';

final courseSourceProvider = Provider<CourseSource>((ref) {
  final useRemote = ref.watch(useRemoteDbProvider);
  return useRemote ? RemoteCourseSource() : LocalCourseSource();
});

final courseRefreshProvider = StateProvider<int>((ref) => 0);

final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  ref.watch(courseRefreshProvider);
  return ref.read(courseSourceProvider).getAll();
});

final courseByIdProvider = FutureProvider.family<Course?, String>((ref, id) async {
  ref.watch(courseRefreshProvider);
  return ref.read(courseSourceProvider).getById(id);
});

class CourseNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> save(Course course, {bool isEdit = false}) async {
    state = const AsyncValue.loading();
    try {
      final src = ref.read(courseSourceProvider);
      if (isEdit) {
        await src.update(course);
      } else {
        await src.create(course);
      }
      ref.read(courseRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(courseSourceProvider).delete(id);
      ref.read(courseRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final courseNotifierProvider =
    NotifierProvider<CourseNotifier, AsyncValue<void>>(CourseNotifier.new);
