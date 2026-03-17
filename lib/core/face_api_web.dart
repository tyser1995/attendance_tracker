import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:uuid/uuid.dart';

// ── JS interop declarations ───────────────────────────────────────────────────

/// Typed wrapper around window._faceApi (defined in web/index.html).
extension type _FaceApi._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> loadModels();
  // detect/startCamera/stopCamera all take the video element's DOM id.
  external JSPromise<JSAny?> detect(JSString videoId);
  external JSPromise<JSAny?> startCamera(JSString videoId);
  external void stopCamera(JSString videoId);
}

@JS('_faceApi')
external JSObject? get _faceApiRaw;

_FaceApi? get _faceApi {
  final raw = _faceApiRaw;
  if (raw == null) return null;
  return _FaceApi._(raw);
}

// ── Model loading ─────────────────────────────────────────────────────────────

bool _modelsLoaded = false;

Future<void> loadFaceApiModels() async {
  if (_modelsLoaded) return;
  final api = _faceApi;
  if (api == null) throw Exception('_faceApi bridge not found in window');
  await api.loadModels().toDart;
  _modelsLoaded = true;
}

Future<bool> isFaceApiReady() async => _modelsLoaded;

// ── Camera view registration ──────────────────────────────────────────────────

/// Creates a <video> element with a unique DOM id, registers an HtmlElementView
/// factory, and returns the viewType and the element id (as Object).
/// The id is passed to startCamera/stopCamera/detect so the JS bridge can
/// look up the element via document.getElementById.
({String viewType, Object video}) createFaceCameraView() {
  final id = 'face-cam-${const Uuid().v4()}';
  final video = html.VideoElement()
    ..id = id
    ..autoplay = true
    ..setAttribute('playsinline', '')
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.objectFit = 'cover'
    ..style.transform = 'scaleX(-1)';

  ui_web.platformViewRegistry.registerViewFactory(id, (_) => video);
  // Return the id string as the "video" handle — the JS bridge uses it to
  // look up the element via document.getElementById(id).
  return (viewType: id, video: id);
}

// ── Camera start / stop ───────────────────────────────────────────────────────

Future<void> startCamera(Object videoId) async {
  final api = _faceApi;
  if (api == null) return;
  await api.startCamera((videoId as String).toJS).toDart;
}

void stopCamera(Object videoId) {
  _faceApi?.stopCamera((videoId as String).toJS);
}

// ── Face detection ────────────────────────────────────────────────────────────

/// Returns the 128-float face descriptor or null if no face detected.
/// The JS bridge returns the descriptor as a JSON string to avoid cross-boundary
/// JS Array → Dart List conversion complexity.
Future<List<double>?> detectFaceDescriptor(Object videoId) async {
  if (!_modelsLoaded) return null;
  final api = _faceApi;
  if (api == null) return null;

  final result = await api.detect((videoId as String).toJS).toDart;
  if (result == null) return null;

  // JS bridge returns JSON.stringify(Array.from(descriptor)) — decode to List.
  final jsonStr = (result as JSString).toDart;
  final list = jsonDecode(jsonStr) as List<dynamic>;
  return list.map((e) => (e as num).toDouble()).toList();
}

// ── Distance ──────────────────────────────────────────────────────────────────

/// Euclidean distance between two 128-float face descriptors.
/// Values < 0.6 indicate the same person (face-api.js convention).
double euclideanFaceDistance(List<double> a, List<double> b) {
  if (a.length != b.length) return 1.0;
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    sum += d * d;
  }
  return math.sqrt(sum);
}
