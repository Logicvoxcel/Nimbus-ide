import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// Controllers currently applying their own programmatic edit -- guards
/// against the listener re-triggering itself when we insert the indent text.
final Set<CodeController> _autoIndenting = {};

/// Wires up auto-indent-on-Enter for [controller]. Built directly on
/// TextEditingController's own value/selection API rather than any
/// third-party auto-indent feature, so its behavior is fully known and
/// doesn't depend on guessing another package's internals.
void attachAutoIndent(CodeController controller) {
  controller.addListener(() => _onChange(controller));
}

void _onChange(CodeController controller) {
  if (_autoIndenting.contains(controller)) return;

  final text = controller.text;
  final selection = controller.selection;
  if (!selection.isCollapsed) return;
  final cursor = selection.baseOffset;
  if (cursor <= 0 || cursor > text.length) return;
  if (text[cursor - 1] != '\n') return; // only act right after Enter

  final beforeNewline = text.substring(0, cursor - 1);
  final prevLineStart = beforeNewline.lastIndexOf('\n') + 1;
  final prevLine = beforeNewline.substring(prevLineStart);

  final leading = RegExp(r'^[ \t]*').firstMatch(prevLine)?.group(0) ?? '';
  var indent = leading;

  final trimmedPrev = prevLine.trimRight();
  if (trimmedPrev.isNotEmpty) {
    final lastChar = trimmedPrev[trimmedPrev.length - 1];
    if (lastChar == '{' || lastChar == '(' || lastChar == '[' || lastChar == ':') {
      indent = '$indent  ';
    }
  }

  if (indent.isEmpty) return;

  _autoIndenting.add(controller);
  final newText = text.replaceRange(cursor, cursor, indent);
  controller.value = controller.value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: cursor + indent.length),
    composing: TextRange.empty,
  );
  _autoIndenting.remove(controller);
}
