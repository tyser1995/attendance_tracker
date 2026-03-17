import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import '../core/auth_utils.dart';
import '../data/local/sembast_helper.dart';
import '../models/app_user.dart';

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  Future<String?> login(String username, String password) async {
    final db = await SembastHelper.instance.database;
    final hash = hashPassword(password);
    final record = await usersStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('username', username.trim().toLowerCase()),
          Filter.equals('password_hash', hash),
        ])));
    if (record == null) return 'Invalid username or password.';
    state = AppUser.fromMap({...record.value, 'id': record.key});
    return null; // null = success
  }

  void logout() => state = null;
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(authProvider) != null);
final isAdminProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isAdmin ?? false);
final isSuperAdminProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isSuperAdmin ?? false);
