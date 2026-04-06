import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kRfid = 'auth_method_rfid';
const _kBarcode = 'auth_method_barcode';
const _kQrCode = 'auth_method_qrcode';
const _kFace = 'auth_method_face';

class AuthMethodsConfig {
  final bool rfid;
  final bool barcode;
  final bool qrCode;
  final bool face;

  const AuthMethodsConfig({
    this.rfid = false,
    this.barcode = false,
    this.qrCode = false,
    this.face = false,
  });

  /// True if the camera-based scan tab should be shown (QR or Barcode enabled).
  bool get hasScan => qrCode || barcode;
}

class AuthMethodsNotifier extends AsyncNotifier<AuthMethodsConfig> {
  @override
  Future<AuthMethodsConfig> build() async => _load();

  Future<AuthMethodsConfig> _load() async {
    final p = await SharedPreferences.getInstance();
    return AuthMethodsConfig(
      rfid: p.getBool(_kRfid) ?? false,
      barcode: p.getBool(_kBarcode) ?? false,
      qrCode: p.getBool(_kQrCode) ?? false,
      face: p.getBool(_kFace) ?? false,
    );
  }

  Future<void> setRfid(bool v) => _set(_kRfid, v);
  Future<void> setBarcode(bool v) => _set(_kBarcode, v);
  Future<void> setQrCode(bool v) => _set(_kQrCode, v);
  Future<void> setFace(bool v) => _set(_kFace, v);

  Future<void> _set(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
    state = AsyncValue.data(await _load());
  }
}

final authMethodsProvider =
    AsyncNotifierProvider<AuthMethodsNotifier, AuthMethodsConfig>(
        AuthMethodsNotifier.new);
