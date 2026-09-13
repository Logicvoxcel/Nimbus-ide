import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';

/// Runs JavaScript entirely on-device (QuickJS on Android, JavaScriptCore
/// on iOS via the flutter_js package) and streams console output back
/// through [onLine] as it happens.
///
/// NOTE: this wraps flutter_js's `getJavascriptRuntime()` / `onMessage` /
/// `sendMessage` bridge as documented by the package. If a future package
/// version renames these, this is the one place to update.
class JsRunner {
  JavascriptRuntime? _runtime;

  static const _consoleChannel = 'nimbusConsole';

  Future<void> run(String code, void Function(String line, bool isError) onLine) async {
    _runtime?.dispose();
    final rt = getJavascriptRuntime();
    _runtime = rt;

    rt.onMessage(_consoleChannel, (dynamic args) {
      try {
        final decoded = jsonDecode(args.toString()) as Map;
        onLine('${decoded['text']}', decoded['isError'] == true);
      } catch (_) {
        onLine(args.toString(), false);
      }
    });

    const shim = '''
      globalThis.console = {
        log: function(){ sendMessage("$_consoleChannel", JSON.stringify({text: Array.prototype.slice.call(arguments).join(" "), isError: false})); },
        info: function(){ sendMessage("$_consoleChannel", JSON.stringify({text: Array.prototype.slice.call(arguments).join(" "), isError: false})); },
        warn: function(){ sendMessage("$_consoleChannel", JSON.stringify({text: "WARN: " + Array.prototype.slice.call(arguments).join(" "), isError: false})); },
        error: function(){ sendMessage("$_consoleChannel", JSON.stringify({text: Array.prototype.slice.call(arguments).join(" "), isError: true})); }
      };
    ''';
    rt.evaluate(shim);

    final result = rt.evaluate(code);
    if (result.isError) {
      onLine(result.stringResult, true);
    } else if (result.stringResult.isNotEmpty && result.stringResult != 'undefined') {
      onLine('=> ${result.stringResult}', false);
    }
  }

  void dispose() {
    _runtime?.dispose();
    _runtime = null;
  }
}
