import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import '../core/auth_utils.dart';
import '../data/local/sembast_helper.dart';
import '../models/app_user.dart';

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  // ── Password login ──────────────────────────────────────────────────────────

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

  // ── RFID / Barcode login ────────────────────────────────────────────────────
  // Both RFID (keyboard HID) and barcode (camera) share the card_id field.

  Future<String?> loginByCard(String cardId) async {
    final trimmed = cardId.trim();
    if (trimmed.isEmpty) return 'Card ID is empty.';
    final db = await SembastHelper.instance.database;
    final record = await usersStore.findFirst(db,
        finder: Finder(filter: Filter.equals('card_id', trimmed)));
    if (record == null) return 'Card not recognised. Assign this card to a user first.';
    state = AppUser.fromMap({...record.value, 'id': record.key});
    return null;
  }

  // ── QR Code login ───────────────────────────────────────────────────────────
  // The QR code encodes the user's Sembast record key (UUID).

  Future<String?> loginByQrToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return 'Invalid QR code.';
    final db = await SembastHelper.instance.database;
    final record = await usersStore.record(trimmed).get(db);
    if (record == null) return 'QR code not recognised.';
    state = AppUser.fromMap({...record, 'id': trimmed});
    return null;
  }

  // ── Face Recognition login ──────────────────────────────────────────────────

  Future<String?> loginByFace(List<double> descriptor) async {
    final db = await SembastHelper.instance.database;
    final records = await usersStore.find(db);

    String? bestId;
    Map<String, Object?>? bestRecord;
    var bestDist = double.infinity;

    for (final r in records) {
      final stored = r.value['face_descriptor'] as String?;
      if (stored == null) continue;
      final storedList =
          (jsonDecode(stored) as List).map((e) => (e as num).toDouble()).toList();
      final dist = _euclidean(descriptor, storedList);
      if (dist < bestDist) {
        bestDist = dist;
        bestId = r.key;
        bestRecord = r.value;
      }
    }

    if (bestId == null || bestDist >= 0.6) {
      return 'Face not recognised. Please try again or use password login.';
    }
    state = AppUser.fromMap({...bestRecord!, 'id': bestId});
    return null;
  }

  void logout() => state = null;
}

double _euclidean(List<double> a, List<double> b) {
  if (a.length != b.length) return 1.0;
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    sum += d * d;
  }
  return math.sqrt(sum);
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

final isLoggedInProvider = Provider<bool>((ref) => ref.watch(authProvider) != null);
final isAdminProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isAdmin ?? false);
final isSuperAdminProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isSuperAdmin ?? false);
