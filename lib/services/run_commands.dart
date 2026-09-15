import 'language_map.dart';

/// The shell command to run [filename] (relative to its own directory,
/// which is passed separately as the working directory), or null if this
/// extension has no run command configured yet.
///
/// Always a single shell string, invoked as `bash -c "<command>"`, so
/// compiled-language two-step commands (compile, then run) work uniformly
/// with everything else.
String? shellCommandFor(String filename) {
  final ext = extensionOf(filename);
  final stem = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
  final quoted = '"$filename"';

  switch (ext) {
    case 'py':
      return 'python3 $quoted';
    case 'js':
    case 'mjs':
    case 'cjs':
      return 'node $quoted';
    case 'c':
      return 'cc $quoted -o ./nimbus_run_out && ./nimbus_run_out';
    case 'cpp':
    case 'cc':
      return 'c++ $quoted -o ./nimbus_run_out && ./nimbus_run_out';
    case 'java':
      return 'javac $quoted && java $stem';
    case 'go':
      return 'go run $quoted';
    case 'rb':
      return 'ruby $quoted';
    case 'php':
      return 'php $quoted';
    case 'rs':
      return 'rustc $quoted -o ./nimbus_run_out && ./nimbus_run_out';
    case 'sh':
    case 'bash':
      return 'bash $quoted';
    case 'pl':
      return 'perl $quoted';
    case 'lua':
      return 'lua $quoted';
    default:
      return null;
  }
}

/// The Termux package(s) `pkg install` needs for a given extension, shown
/// in the setup/error UI so the user knows exactly what to install.
String? termuxPackageFor(String filename) {
  final ext = extensionOf(filename);
  switch (ext) {
    case 'py':
      return 'python';
    case 'js':
    case 'mjs':
    case 'cjs':
      return 'nodejs';
    case 'c':
    case 'cpp':
    case 'cc':
      return 'clang';
    case 'java':
      return 'openjdk-17';
    case 'go':
      return 'golang';
    case 'rb':
      return 'ruby';
    case 'php':
      return 'php';
    case 'rs':
      return 'rust';
    case 'pl':
      return 'perl';
    case 'lua':
      return 'lua';
    default:
      return null;
  }
}
