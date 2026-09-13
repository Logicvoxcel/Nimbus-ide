import 'package:highlight/highlight_core.dart' show Mode;
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/scss.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/typescript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/go.dart';
import 'package:highlight/languages/rust.dart';
import 'package:highlight/languages/ruby.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/swift.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/sql.dart';
import 'package:highlight/languages/bash.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/lua.dart';
import 'package:highlight/languages/perl.dart';
import 'package:highlight/languages/r.dart';
import 'package:highlight/languages/scala.dart';
import 'package:highlight/languages/ini.dart';
import 'package:highlight/languages/plaintext.dart';

/// Extension -> (highlight.js-ported Mode, short badge label).
///
/// `flutter_code_editor` takes one of these `Mode` objects directly as its
/// `language:` parameter (see the package's own usage example), so this is
/// the single place that needs updating to teach Nimbus a new language.
class LanguageInfo {
  final Mode mode;
  final String badge;
  const LanguageInfo(this.mode, this.badge);
}

final Map<String, LanguageInfo> _byExt = {
  'html': LanguageInfo(xml, 'HTML'),
  'htm': LanguageInfo(xml, 'HTML'),
  'xml': LanguageInfo(xml, 'XML'),
  'css': LanguageInfo(css, 'CSS'),
  'scss': LanguageInfo(scss, 'SCS'),
  'js': LanguageInfo(javascript, 'JS'),
  'mjs': LanguageInfo(javascript, 'JS'),
  'cjs': LanguageInfo(javascript, 'JS'),
  'jsx': LanguageInfo(javascript, 'JSX'),
  'ts': LanguageInfo(typescript, 'TS'),
  'tsx': LanguageInfo(typescript, 'TSX'),
  'json': LanguageInfo(json, 'JSN'),
  'py': LanguageInfo(python, 'PY'),
  'java': LanguageInfo(java, 'JAV'),
  'c': LanguageInfo(cpp, 'C'),
  'h': LanguageInfo(cpp, 'H'),
  'cpp': LanguageInfo(cpp, 'C++'),
  'cc': LanguageInfo(cpp, 'C++'),
  'hpp': LanguageInfo(cpp, 'HPP'),
  'cs': LanguageInfo(cs, 'C#'),
  'go': LanguageInfo(go, 'GO'),
  'rs': LanguageInfo(rust, 'RS'),
  'rb': LanguageInfo(ruby, 'RB'),
  'php': LanguageInfo(php, 'PHP'),
  'swift': LanguageInfo(swift, 'SWI'),
  'kt': LanguageInfo(kotlin, 'KT'),
  'sql': LanguageInfo(sql, 'SQL'),
  'sh': LanguageInfo(bash, 'SH'),
  'bash': LanguageInfo(bash, 'SH'),
  'yml': LanguageInfo(yaml, 'YML'),
  'yaml': LanguageInfo(yaml, 'YML'),
  'md': LanguageInfo(markdown, 'MD'),
  'dart': LanguageInfo(dart, 'DART'),
  'lua': LanguageInfo(lua, 'LUA'),
  'pl': LanguageInfo(perl, 'PL'),
  'r': LanguageInfo(r, 'R'),
  'scala': LanguageInfo(scala, 'SCA'),
  'ini': LanguageInfo(ini, 'INI'),
  'toml': LanguageInfo(ini, 'TML'),
};

String extensionOf(String nameOrPath) {
  final base = nameOrPath.split('/').last;
  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return '';
  return base.substring(dot + 1).toLowerCase();
}

LanguageInfo languageFor(String nameOrPath) {
  final ext = extensionOf(nameOrPath);
  return _byExt[ext] ?? LanguageInfo(plaintext, ext.isEmpty ? 'TXT' : ext.substring(0, ext.length > 3 ? 3 : ext.length).toUpperCase());
}

/// Starter template content for brand-new files, keyed by extension.
String templateFor(String name) {
  final ext = extensionOf(name);
  switch (ext) {
    case 'html':
    case 'htm':
      return '<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8">\n  <title>$name</title>\n</head>\n<body>\n  \n</body>\n</html>\n';
    case 'css':
      return '/* $name */\n';
    case 'js':
    case 'mjs':
    case 'cjs':
      return '// $name\n';
    case 'py':
      return '# $name\n';
    case 'json':
      return '{\n  \n}\n';
    case 'md':
      return '# ${name.replaceAll(RegExp(r'\.[^.]+$'), '')}\n\n';
    case 'java':
      final cls = name.replaceAll(RegExp(r'\.[^.]+$'), '');
      return 'public class $cls {\n    public static void main(String[] args) {\n        \n    }\n}\n';
    default:
      return '';
  }
}

bool isRunnableJs(String name) {
  final ext = extensionOf(name);
  return ext == 'js' || ext == 'mjs' || ext == 'cjs';
}

bool isHtml(String name) {
  final ext = extensionOf(name);
  return ext == 'html' || ext == 'htm';
}
