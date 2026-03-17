import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<({String name, String content})?> pickTextFile(
    {String accept = '.csv,.json'}) async {
  final completer = Completer<({String name, String content})?>();
  final input = html.FileUploadInputElement()..accept = accept;

  StreamSubscription? focusSub;

  void complete(({String name, String content})? result) {
    if (!completer.isCompleted) {
      completer.complete(result);
      focusSub?.cancel();
    }
  }

  input.onChange.listen((_) async {
    final file = input.files?.first;
    if (file == null) {
      complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    final content = reader.result as String?;
    complete(content != null ? (name: file.name, content: content) : null);
  });

  // Resolve null when user cancels the file dialog (window regains focus)
  focusSub = html.window.onFocus.listen((_) {
    Future.delayed(const Duration(milliseconds: 500), () => complete(null));
  });

  input.click();
  return completer.future;
}
