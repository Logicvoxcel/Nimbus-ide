import 'dart:io';

import '../models/code_file.dart';
import 'run_commands.dart';
import 'termux_bridge.dart';

class RunLine {
  const RunLine(this.text, this.isError);
  final String text;
  final bool isError;
}

class RunOutcome {
  const RunOutcome(this.lines);
  final List<RunLine> lines;
}

class TermuxRunService {
  /// Runs [file] through Termux. Returns null only when there's genuinely
  /// nothing to show (shouldn't normally happen -- failures come back as
  /// an outcome with error lines instead, so the UI always has something
  /// concrete to display).
  static Future<RunOutcome> run(CodeFile file) async {
    final name = file.displayName.split('/').last;

    final command = shellCommandFor(name);
    if (command == null) {
      final pkg = termuxPackageFor(name);
      return RunOutcome([
        RunLine(
          pkg == null
              ? 'No run command configured for this file type yet.'
              : 'No run command configured for this file type yet. (Expected package: $pkg)',
          true,
        ),
      ]);
    }

    String workdir;
    if (file.fromExternalFolder) {
      workdir = File(file.path).parent.path;
    } else {
      await file.save(); // make sure the staged copy reflects the latest edits
      final staged = await TermuxBridge.stageFile('run', name, file.controller.text);
      if (staged == null) {
        return const RunOutcome([
          RunLine('Could not prepare this file for Termux (storage write failed).', true),
        ]);
      }
      workdir = File(staged).parent.path;
    }

    final result = await TermuxBridge.runCommand(
      path: TermuxBridge.bashPath,
      arguments: ['-c', command],
      workdir: workdir,
    );

    final lines = <RunLine>[];
    if (result.err != 0) {
      lines.add(RunLine(
        result.errmsg.isNotEmpty ? result.errmsg : 'Termux could not run this command.',
        true,
      ));
    }
    for (final l in result.stdout.split('\n')) {
      if (l.isNotEmpty) lines.add(RunLine(l, false));
    }
    for (final l in result.stderr.split('\n')) {
      if (l.isNotEmpty) lines.add(RunLine(l, true));
    }
    if (result.err == 0) {
      lines.add(RunLine('— exit code ${result.exitCode} —', result.exitCode != 0));
    }
    return RunOutcome(lines);
  }
}
