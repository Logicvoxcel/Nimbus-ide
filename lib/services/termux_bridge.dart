import 'package:flutter/services.dart';

class TermuxResult {
  const TermuxResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.err,
    required this.errmsg,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
  final int err;
  final String errmsg;
}

/// Talks to Termux (a separately-installed app) through Android's normal
/// inter-app Intent mechanism -- see MainActivity.kt for the native side.
/// Nothing here links against Termux's code, so this stays independent of
/// its GPL-3.0 license.
class TermuxBridge {
  static const _channel = MethodChannel('com.nimbus.ide/termux');

  static const bashPath = '/data/data/com.termux/files/usr/bin/bash';

  static Future<bool> isInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isInstalled') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {
      // The setup screen re-checks status when the user comes back to it.
    }
  }

  /// Stages [content] into the shared Downloads/NimbusIDE/<subDir> folder
  /// and returns the resulting real filesystem path, or null on failure.
  static Future<String?> stageFile(String subDir, String filename, String content) async {
    try {
      return await _channel.invokeMethod<String>('stageFile', {
        'subDir': subDir,
        'filename': filename,
        'content': content,
      });
    } catch (_) {
      return null;
    }
  }

  static Future<TermuxResult> runCommand({
    required String path,
    List<String> arguments = const [],
    String? workdir,
    bool background = true,
  }) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('runCommand', {
        'path': path,
        'arguments': arguments,
        'workdir': workdir,
        'background': background,
      }).timeout(
        const Duration(seconds: 25),
        onTimeout: () => null,
      );
      if (raw == null) {
        return const TermuxResult(
          stdout: '',
          stderr: '',
          exitCode: -1,
          err: -1,
          errmsg: 'Termux never responded. Open the Termux status sheet and confirm '
              'allow-external-apps is enabled in ~/.termux/termux.properties — '
              "Termux silently rejects commands (with its own error screen, not ours) "
              'when that\u2019s off.',
        );
      }
      return TermuxResult(
        stdout: (raw['stdout'] as String?) ?? '',
        stderr: (raw['stderr'] as String?) ?? '',
        exitCode: (raw['exitCode'] as int?) ?? 0,
        err: (raw['err'] as int?) ?? 0,
        errmsg: (raw['errmsg'] as String?) ?? '',
      );
    } on PlatformException catch (e) {
      return TermuxResult(
        stdout: '',
        stderr: '',
        exitCode: -1,
        err: -1,
        errmsg: e.message ?? e.code,
      );
    }
  }
}
