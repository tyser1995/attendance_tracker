// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> requestPersistentStorage() async {
  try {
    final storage = html.window.navigator.storage;
    if (storage == null) return false;
    return await storage.persist();
  } catch (_) {
    return false;
  }
}
