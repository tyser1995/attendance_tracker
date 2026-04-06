import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';
import '../core/auth_utils.dart';
import '../data/local/sembast_helper.dart';
import '../models/app_user.dart';

final usersListProvider = FutureProvider<List<AppUser>>((ref) async {
  ref.watch(_usersRefreshProvider);
  final db = await SembastHelper.instance.database;
  final records = await usersStore.find(db,
      finder: Finder(sortOrders: [SortOrder('username')]));
  return records
      .map((r) => AppUser.fromMap({...r.value, 'id': r.key}))
      .toList();
});

final _usersRefreshProvider = StateProvider<int>((ref) => 0);

class UserManagerNotifier extends Notifier<void> {
  static const _uuid = Uuid();

  @override
  void build() {}

  Future<String?> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Username is required.';
    if (password.isEmpty) return 'Password is required.';

    final db = await SembastHelper.instance.database;
    final existing = await usersStore.findFirst(db,
        finder: Finder(filter: Filter.equals('username', trimmed)));
    if (existing != null) return 'Username already exists.';

    await usersStore.record(_uuid.v4()).put(db, {
      'username': trimmed,
      'password_hash': hashPassword(password),
      'role': role,
    });
    ref.read(_usersRefreshProvider.notifier).state++;
    return null;
  }

  Future<String?> updateUser({
    required String id,
    required String username,
    String? newPassword,
    required String role,
  }) async {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Username is required.';

    final db = await SembastHelper.instance.database;
    final existing = await usersStore.findFirst(db,
        finder: Finder(filter: Filter.and([
          Filter.equals('username', trimmed),
          Filter.notEquals('__key__', id),
        ])));
    if (existing != null) return 'Username already exists.';

    final update = <String, Object?>{'username': trimmed, 'role': role};
    if (newPassword != null && newPassword.isNotEmpty) {
      update['password_hash'] = hashPassword(newPassword);
    }
    await usersStore.record(id).update(db, update);
    ref.read(_usersRefreshProvider.notifier).state++;
    return null;
  }

  Future<String?> setCardId(String userId, String cardId) async {
    final trimmed = cardId.trim();
    final db = await SembastHelper.instance.database;
    if (trimmed.isNotEmpty) {
      final existing = await usersStore.findFirst(db,
          finder: Finder(filter: Filter.and([
            Filter.equals('card_id', trimmed),
            Filter.notEquals('__key__', userId),
          ])));
      if (existing != null) return 'Card ID already assigned to another user.';
    }
    await usersStore
        .record(userId)
        .update(db, {'card_id': trimmed.isEmpty ? null : trimmed});
    ref.read(_usersRefreshProvider.notifier).state++;
    return null;
  }

  Future<String?> setFaceDescriptor(
      String userId, List<double>? descriptor) async {
    final db = await SembastHelper.instance.database;
    await usersStore.record(userId).update(db, {
      'face_descriptor': descriptor == null ? null : jsonEncode(descriptor),
    });
    ref.read(_usersRefreshProvider.notifier).state++;
    return null;
  }

  Future<String?> deleteUser(String id, String currentUserId) async {
    if (id == currentUserId) return 'You cannot delete your own account.';

    final db = await SembastHelper.instance.database;
    final record = await usersStore.record(id).get(db);
    if (record == null) return 'User not found.';

    // Prevent deleting the last super_admin
    if (record['role'] == 'super_admin') {
      final count = await usersStore.count(db,
          filter: Filter.equals('role', 'super_admin'));
      if (count <= 1) return 'Cannot delete the last super admin account.';
    }

    await usersStore.record(id).delete(db);
    ref.read(_usersRefreshProvider.notifier).state++;
    return null;
  }
}

final userManagerProvider =
    NotifierProvider<UserManagerNotifier, void>(UserManagerNotifier.new);
