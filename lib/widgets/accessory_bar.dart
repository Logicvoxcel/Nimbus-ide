import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../theme/nimbus_colors.dart';

/// A horizontal row of quick-insert keys for the code editor -- the
/// characters mobile keyboards bury behind long-presses or extra taps.
class AccessoryBar extends StatelessWidget {
  const AccessoryBar({super.key, required this.controller});

  final CodeController controller;

  static const _keys = [
    '\t', '{', '}', '(', ')', '[', ']', ';', ':', '"', "'",
    '<', '>', '/', '\\', '=', '_', '-', '\$', '#', '|', '&', '!', ',',
  ];

  void _insert(String text) {
    final selection = controller.selection;
    var start = selection.start;
    var end = selection.end;
    if (start < 0 || end < 0) {
      start = controller.text.length;
      end = controller.text.length;
    }
    final newText = controller.text.replaceRange(start, end, text);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: start + text.length);
  }

  void _moveCursor(int delta) {
    final selection = controller.selection;
    final offset = (selection.baseOffset + delta).clamp(0, controller.text.length);
    controller.selection = TextSelection.collapsed(offset: offset);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: NimbusColors.bgPanel,
        border: Border(top: BorderSide(color: NimbusColors.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        children: [
          ..._keys.map((k) => _Key(label: k == '\t' ? '⇥' : k, onTap: () => _insert(k))),
          _Key(label: '←', onTap: () => _moveCursor(-1)),
          _Key(label: '→', onTap: () => _moveCursor(1)),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: NimbusColors.bgElevated,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            height: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: NimbusColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
