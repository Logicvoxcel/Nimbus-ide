import 'dart:io';

import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../services/language_map.dart';

/// A single open file. Unlike the earlier web version, there is no virtual
/// in-memory storage layer here -- `file` is a real file on disk (either
/// inside the app's own project folder, or inside a folder the user opened
/// from device storage), so saving is just a normal file write.
class CodeFile {
  CodeFile({
    required this.file,
    required this.displayName,
    required String initialContent,
    this.fromExternalFolder = false,
  }) : controller = CodeController(
          text: initialContent,
          language: languageFor(displayName).mode,
        );

  File file;
  String displayName;
  final bool fromExternalFolder;
  final CodeController controller;

  /// The file's absolute path doubles as its stable identity everywhere
  /// (tab lists, the file explorer, saved "last open tabs" preferences) --
  /// no separate id scheme needed.
  String get path => file.path;

  LanguageInfo get lang => languageFor(displayName);

  Future<void> save() => file.writeAsString(controller.text);

  /// Wires the editor controller up to a save callback, keyed by this
  /// file's current path at the time each change fires (so a rename
  /// mid-session still saves to the right place).
  void listenForChanges(void Function(String path) onChanged) {
    controller.addListener(() => onChanged(path));
  }

  void dispose() {
    controller.dispose();
  }
}
