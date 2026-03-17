import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sources/abstract/id_pattern_source.dart';
import '../data/sources/local/local_id_pattern_source.dart';
import '../data/sources/remote/remote_id_pattern_source.dart';
import '../models/id_pattern.dart';
import 'db_config_provider.dart';

final idPatternSourceProvider = Provider<IdPatternSource>((ref) {
  final useRemote = ref.watch(useRemoteDbProvider);
  return useRemote ? RemoteIdPatternSource() : LocalIdPatternSource();
});

final patternRefreshProvider = StateProvider<int>((ref) => 0);

final allPatternsProvider = FutureProvider<List<IdPattern>>((ref) async {
  ref.watch(patternRefreshProvider);
  return ref.read(idPatternSourceProvider).getAll();
});

class IdPatternNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> create(IdPattern pattern) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(idPatternSourceProvider).create(pattern);
      ref.read(patternRefreshProvider.notifier).state++;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }

  Future<void> toggle(String id) async {
    await ref.read(idPatternSourceProvider).toggleStatus(id);
    ref.read(patternRefreshProvider.notifier).state++;
  }

  Future<void> delete(String id) async {
    await ref.read(idPatternSourceProvider).delete(id);
    ref.read(patternRefreshProvider.notifier).state++;
  }

  Future<void> activateAll() async {
    await ref.read(idPatternSourceProvider).activateAll();
    ref.read(patternRefreshProvider.notifier).state++;
  }

  Future<void> deactivateAll() async {
    await ref.read(idPatternSourceProvider).deactivateAll();
    ref.read(patternRefreshProvider.notifier).state++;
  }
}

final idPatternNotifierProvider =
    NotifierProvider<IdPatternNotifier, AsyncValue<void>>(IdPatternNotifier.new);
