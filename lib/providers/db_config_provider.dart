import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Keys stored in SharedPreferences
const _kUseRemote = 'use_remote_db';
const _kSupabaseUrl = 'supabase_url';
const _kSupabaseKey = 'supabase_anon_key';
const _kInitialPage = 'initial_page'; // 'login' | 'scanner'

class DbConfig {
  final bool useRemote;
  final String supabaseUrl;
  final String supabaseKey;
  final bool supabaseInitialized;
  final String initialPage;

  const DbConfig({
    this.useRemote = false,
    this.supabaseUrl = '',
    this.supabaseKey = '',
    this.supabaseInitialized = false,
    this.initialPage = 'login',
  });

  bool get canUseRemote =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty && supabaseInitialized;
}

class DbConfigNotifier extends AsyncNotifier<DbConfig> {
  @override
  Future<DbConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_kSupabaseUrl) ?? '';
    final key = prefs.getString(_kSupabaseKey) ?? '';
    final useRemote = prefs.getBool(_kUseRemote) ?? false;
    final initialPage = prefs.getString(_kInitialPage) ?? 'login';

    bool initialized = false;
    if (url.isNotEmpty && key.isNotEmpty) {
      initialized = await _tryInitSupabase(url, key);
    }

    return DbConfig(
      useRemote: useRemote && initialized,
      supabaseUrl: url,
      supabaseKey: key,
      supabaseInitialized: initialized,
      initialPage: initialPage,
    );
  }

  Future<bool> _tryInitSupabase(String url, String key) async {
    try {
      // Check if already initialized
      try {
        Supabase.instance.client;
        return true;
      } catch (_) {}
      await Supabase.initialize(url: url, anonKey: key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setUseRemote(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseRemote, value);
    state = await AsyncValue.guard(() async {
      final current = state.valueOrNull ?? const DbConfig();
      if (value && !current.canUseRemote) {
        throw Exception('Supabase is not configured. Please enter URL and key first.');
      }
      return current.canUseRemote
          ? DbConfig(
              useRemote: value,
              supabaseUrl: current.supabaseUrl,
              supabaseKey: current.supabaseKey,
              supabaseInitialized: current.supabaseInitialized,
            )
          : DbConfig(useRemote: false);
    });
  }

  Future<void> setInitialPage(String page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kInitialPage, page);
    final current = state.valueOrNull ?? const DbConfig();
    state = AsyncValue.data(DbConfig(
      useRemote: current.useRemote,
      supabaseUrl: current.supabaseUrl,
      supabaseKey: current.supabaseKey,
      supabaseInitialized: current.supabaseInitialized,
      initialPage: page,
    ));
  }

  Future<void> saveSupabaseConfig(String url, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSupabaseUrl, url);
    await prefs.setString(_kSupabaseKey, key);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final initialized = await _tryInitSupabase(url, key);
      return DbConfig(
        useRemote: initialized && (prefs.getBool(_kUseRemote) ?? false),
        supabaseUrl: url,
        supabaseKey: key,
        supabaseInitialized: initialized,
      );
    });
  }
}

final dbConfigProvider =
    AsyncNotifierProvider<DbConfigNotifier, DbConfig>(DbConfigNotifier.new);

/// Simple boolean: are we using remote?
final useRemoteDbProvider = Provider<bool>((ref) {
  return ref.watch(dbConfigProvider).valueOrNull?.useRemote ?? false;
});

/// 'login' or 'scanner'
final initialPageProvider = Provider<String>((ref) {
  return ref.watch(dbConfigProvider).valueOrNull?.initialPage ?? 'login';
});
