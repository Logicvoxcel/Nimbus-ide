import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/code_file.dart';
import 'auto_indent.dart';
import 'language_map.dart';

/// Owns the project's files, tabs, and a few user preferences. Everything
/// here is a real file on disk -- either inside the app's own private
/// project folder, or inside a folder the user picked from device storage.
class ProjectService extends ChangeNotifier {
  static const _skipDirs = {
    'node_modules', '.git', 'dist', 'build', '.next', 'target',
    'venv', '.venv', '__pycache__', '.idea', '.gradle',
  };
  static const _maxFiles = 300;
  static const _maxFileBytes = 2 * 1000 * 1000;

  final Map<String, CodeFile> files = {}; // absolute path -> CodeFile
  final List<String> openTabs = [];
  String? activeId;

  bool isExternalFolder = false;
  String? _externalRootPath;
  String projectLabel = 'My Project';

  bool isDark = true;
  double fontSize = 14;

  Directory? _root;
  Timer? _saveTimer;

  List<CodeFile> get orderedFiles => files.values.toList();
  CodeFile? get activeFile => activeId != null ? files[activeId] : null;

  void disposeAll() {
    for (final f in files.values) {
      f.dispose();
    }
  }

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _root = Directory('${docs.path}/nimbus_project');
    if (!await _root!.exists()) await _root!.create(recursive: true);

    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? true;
    fontSize = prefs.getDouble('fontSize') ?? 14;
    final savedExternal = prefs.getBool('isExternalFolder') ?? false;
    final savedRoot = prefs.getString('externalRootPath') ?? '';

    if (savedExternal && savedRoot.isNotEmpty && Directory(savedRoot).existsSync()) {
      isExternalFolder = true;
      _externalRootPath = savedRoot;
      projectLabel = prefs.getString('projectLabel') ?? _baseName(savedRoot);
      await _loadEntries(await _walkFolder(Directory(savedRoot), '', skipHeavy: true));
    } else {
      final entries = await _walkFolder(_root!, '', skipHeavy: false);
      if (entries.isEmpty) {
        await _seedStarterFiles();
      } else {
        await _loadEntries(entries);
      }
    }

    final savedTabs = prefs.getStringList('openTabs') ?? [];
    openTabs.addAll(savedTabs.where((p) => files.containsKey(p)));
    if (openTabs.isEmpty && files.isNotEmpty) openTabs.add(files.keys.first);

    final savedActive = prefs.getString('activeId') ?? '';
    activeId = files.containsKey(savedActive)
        ? savedActive
        : (openTabs.isNotEmpty ? openTabs.first : null);

    notifyListeners();
  }

  CodeFile _makeCodeFile({
    required File file,
    required String displayName,
    required String initialContent,
    bool? fromExternalFolder,
  }) {
    final cf = CodeFile(
      file: file,
      displayName: displayName,
      initialContent: initialContent,
      fromExternalFolder: fromExternalFolder ?? isExternalFolder,
    );
    cf.listenForChanges(scheduleSave);
    attachAutoIndent(cf.controller);
    return cf;
  }

  Future<void> _loadEntries(List<MapEntry<String, String>> entries) async {
    for (final entry in entries) {
      final content = await _safeReadText(File(entry.key));
      if (content == null) continue; // binary/unreadable -- skip it
      files[entry.key] = _makeCodeFile(
        file: File(entry.key),
        displayName: entry.value,
        initialContent: content,
      );
    }
  }

  Future<void> _seedStarterFiles() async {
    final starters = <String, String>{
      'welcome.md': '''# Welcome to Nimbus

A code editor built for touch — now a native Flutter app.

## What works today
- Syntax highlighting for 25+ languages, with folding for some of them.
- Real files: everything here lives on your device's storage, not in
  browser storage like the old web version.
- "Open folder" loads a real folder from your phone and saves edits
  straight back to those files.
- The play button runs JavaScript on-device (an embedded engine), no
  internet connection needed.
- Import or export loose files, or a whole project as a zip.

## Coming later
- Python execution -- it needs a licensed runtime on Android, so it's
  deliberately left out of this first pass rather than baking in a cost
  surprise.
- Autocomplete / snippets and find & replace.

Happy building.
''',
      'main.js': '''function greet(name) {
  return "Hello, " + name + "!";
}

console.log(greet("world"));
''',
      'notes.txt': 'Scratch space -- anything you type here just saves to disk.\n',
    };
    for (final entry in starters.entries) {
      final file = File('${_root!.path}/${entry.key}');
      await file.writeAsString(entry.value);
      files[file.path] = _makeCodeFile(
        file: file,
        displayName: entry.key,
        initialContent: entry.value,
      );
    }
  }

  Future<List<MapEntry<String, String>>> _walkFolder(
    Directory dir,
    String base, {
    required bool skipHeavy,
  }) async {
    final result = <MapEntry<String, String>>[];
    List<FileSystemEntity> entities;
    try {
      entities = dir.listSync();
    } catch (_) {
      return result;
    }
    entities.sort((a, b) => _baseName(a.path).compareTo(_baseName(b.path)));

    for (final entity in entities) {
      if (result.length >= _maxFiles) break;
      final name = _baseName(entity.path);
      if (entity is Directory) {
        if (skipHeavy && (_skipDirs.contains(name) || name.startsWith('.'))) {
          continue;
        }
        final sub = await _walkFolder(
          entity,
          base.isEmpty ? name : '$base/$name',
          skipHeavy: skipHeavy,
        );
        result.addAll(sub);
      } else if (entity is File) {
        int len;
        try {
          len = await entity.length();
        } catch (_) {
          continue;
        }
        if (len > _maxFileBytes) continue;
        final rel = base.isEmpty ? name : '$base/$name';
        result.add(MapEntry(entity.path, rel));
      }
    }
    return result;
  }

  Future<String?> _safeReadText(File f) async {
    try {
      return await f.readAsString();
    } catch (_) {
      return null; // likely binary
    }
  }

  static String _baseName(String path) => path.split(Platform.pathSeparator).last;

  String _rootPath() => isExternalFolder ? _externalRootPath! : _root!.path;

  // ---------- tabs ----------

  void openTab(String path) {
    if (!openTabs.contains(path)) openTabs.add(path);
    activeId = path;
    _savePrefs();
    notifyListeners();
  }

  void closeTab(String path) {
    final idx = openTabs.indexOf(path);
    if (idx == -1) return;
    openTabs.removeAt(idx);
    if (activeId == path) {
      if (openTabs.isNotEmpty) {
        activeId = openTabs[(idx - 1).clamp(0, openTabs.length - 1)];
      } else if (files.isNotEmpty) {
        activeId = files.keys.first;
        openTabs.add(activeId!);
      } else {
        activeId = null;
      }
    }
    _savePrefs();
    notifyListeners();
  }

  void setActive(String path) {
    activeId = path;
    _savePrefs();
    notifyListeners();
  }

  // ---------- saving ----------

  void scheduleSave(String path) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      files[path]?.save();
    });
  }

  // ---------- create / rename / delete ----------

  Future<String?> createFile(String name) async {
    name = name.trim();
    if (name.isEmpty) return 'Enter a file name';
    final dir = _rootPath();
    final newPath = '$dir/$name';
    if (files.containsKey(newPath)) return 'That name is taken';
    final file = File(newPath);
    final content = templateFor(name);
    await file.create(recursive: true);
    await file.writeAsString(content);
    files[newPath] = _makeCodeFile(
      file: file,
      displayName: name,
      initialContent: content,
    );
    openTabs.add(newPath);
    activeId = newPath;
    await _savePrefs();
    notifyListeners();
    return null;
  }

  Future<String?> renameFile(String oldPath, String newName) async {
    newName = newName.trim();
    if (newName.isEmpty) return 'Enter a file name';
    final cf = files[oldPath];
    if (cf == null) return 'File not found';
    final dirPath = File(oldPath).parent.path;
    final newPath = '$dirPath/$newName';
    if (files.containsKey(newPath)) return 'That name is taken';

    final movedFile = await File(oldPath).rename(newPath);
    files.remove(oldPath);
    cf.file = movedFile;
    cf.displayName = _renamedDisplay(cf.displayName, newName);
    files[newPath] = cf;

    final tabIdx = openTabs.indexOf(oldPath);
    if (tabIdx != -1) openTabs[tabIdx] = newPath;
    if (activeId == oldPath) activeId = newPath;

    await _savePrefs();
    notifyListeners();
    return null;
  }

  String _renamedDisplay(String oldDisplay, String newName) {
    final idx = oldDisplay.lastIndexOf('/');
    return idx == -1 ? newName : '${oldDisplay.substring(0, idx)}/$newName';
  }

  Future<void> deleteFile(String path) async {
    final cf = files.remove(path);
    if (cf == null) return;
    try {
      await cf.file.delete();
    } catch (_) {
      // already gone -- fine
    }
    cf.dispose();
    final tabIdx = openTabs.indexOf(path);
    if (tabIdx != -1) openTabs.removeAt(tabIdx);
    if (activeId == path) {
      if (openTabs.isNotEmpty) {
        activeId = openTabs[(tabIdx - 1).clamp(0, openTabs.length - 1)];
      } else if (files.isNotEmpty) {
        activeId = files.keys.first;
        openTabs.add(activeId!);
      } else {
        activeId = null;
      }
    }
    await _savePrefs();
    notifyListeners();
  }

  // ---------- open folder (device storage) ----------

  /// Returns null on success, an error message on failure, or throws
  /// nothing -- a plain `false`-ish empty string means "user cancelled".
  Future<String?> openExternalFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return null; // cancelled, not an error
    final dir = Directory(path);
    if (!await dir.exists()) return 'Could not open that folder';

    final entries = await _walkFolder(dir, '', skipHeavy: true);
    if (entries.isEmpty) return 'No readable files found in that folder';

    for (final f in files.values) {
      f.dispose();
    }
    files.clear();
    openTabs.clear();

    isExternalFolder = true;
    _externalRootPath = path;
    projectLabel = _baseName(path);
    await _loadEntries(entries);

    if (files.isEmpty) return 'No readable files found in that folder';
    activeId = files.keys.first;
    openTabs.add(activeId!);

    await _savePrefs();
    notifyListeners();
    return null;
  }

  // ---------- import ----------

  Future<int> importFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return 0;
    var count = 0;
    final dir = _rootPath();
    for (final f in result.files) {
      if (f.bytes == null) continue;
      final name = _uniqueName(f.name, dir);
      final path = '$dir/$name';
      final file = File(path);
      await file.writeAsBytes(f.bytes!);
      String content;
      try {
        content = utf8.decode(f.bytes!);
      } catch (_) {
        continue; // binary file -- keep it on disk but don't open it as text
      }
      files[path] = _makeCodeFile(
        file: file,
        displayName: name,
        initialContent: content,
      );
      count++;
    }
    if (count > 0) {
      await _savePrefs();
      notifyListeners();
    }
    return count;
  }

  Future<int> importZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return 0;
    final bytes = result.files.first.bytes;
    if (bytes == null) return 0;

    final archive = ZipDecoder().decodeBytes(bytes);
    final dir = _rootPath();
    var count = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      if (count >= _maxFiles) break;
      final outPath = '$dir/${entry.name}';
      final outFile = File(outPath);
      final data = entry.content as List<int>;
      String content;
      try {
        content = utf8.decode(data);
      } catch (_) {
        continue; // skip binary entries for now
      }
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(data);
      files[outPath] = _makeCodeFile(
        file: outFile,
        displayName: entry.name,
        initialContent: content,
      );
      count++;
    }
    if (count > 0) {
      await _savePrefs();
      notifyListeners();
    }
    return count;
  }

  String _uniqueName(String name, String dir) {
    var candidate = name;
    var i = 1;
    while (File('$dir/$candidate').existsSync()) {
      final dot = name.lastIndexOf('.');
      final stem = dot == -1 ? name : name.substring(0, dot);
      final ext = dot == -1 ? '' : name.substring(dot);
      candidate = '$stem ($i)$ext';
      i++;
    }
    return candidate;
  }

  // ---------- export ----------

  Future<void> exportFile(String path) async {
    final cf = files[path];
    if (cf == null) return;
    await cf.save();
    await Share.shareXFiles([XFile(cf.file.path)], text: cf.displayName);
  }

  Future<void> exportZip() async {
    final archive = Archive();
    for (final cf in files.values) {
      final bytes = utf8.encode(cf.controller.text);
      archive.addFile(ArchiveFile(cf.displayName, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) return;
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/nimbus-project.zip');
    await zipFile.writeAsBytes(zipBytes);
    await Share.shareXFiles([XFile(zipFile.path)], text: 'Nimbus project export');
  }

  // ---------- settings ----------

  void toggleTheme() {
    isDark = !isDark;
    _savePrefs();
    notifyListeners();
  }

  void setFontSize(double size) {
    fontSize = size.clamp(10, 22);
    _savePrefs();
    notifyListeners();
  }

  // ---------- prefs ----------

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('openTabs', openTabs);
    await prefs.setString('activeId', activeId ?? '');
    await prefs.setBool('isDark', isDark);
    await prefs.setDouble('fontSize', fontSize);
    await prefs.setBool('isExternalFolder', isExternalFolder);
    await prefs.setString('externalRootPath', _externalRootPath ?? '');
    await prefs.setString('projectLabel', projectLabel);
  }
}
