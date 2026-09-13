import 'package:flutter/material.dart';

import '../theme/nimbus_colors.dart';

/// Shows a text-input dialog and keeps it open with an inline error message
/// if [validate] returns one. Returns the accepted name, or null if the
/// user cancelled.
Future<String?> promptForName(
  BuildContext context, {
  required String title,
  String initial = '',
  required String okLabel,
  required Future<String?> Function(String value) validate,
}) async {
  final controller = TextEditingController(text: initial);
  String? error;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final result = await validate(controller.text);
            if (result != null) {
              setState(() => error = result);
            } else {
              Navigator.of(context).pop(controller.text.trim());
            }
          }

          return AlertDialog(
            backgroundColor: NimbusColors.bgPanel,
            title: Text(title, style: const TextStyle(color: NimbusColors.textPrimary, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: NimbusColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'name.ext',
                    hintStyle: const TextStyle(color: NimbusColors.textDim),
                    enabledBorder: null,
                    filled: true,
                    fillColor: NimbusColors.bgVoid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: NimbusColors.line),
                    ),
                  ),
                  onSubmitted: (_) => submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: NimbusColors.red, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: NimbusColors.textDim)),
              ),
              TextButton(
                onPressed: submit,
                child: Text(okLabel, style: const TextStyle(color: NimbusColors.accent, fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      );
    },
  );
}

/// A simple Cancel/Confirm dialog for destructive actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String okLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: NimbusColors.bgPanel,
      title: Text(title, style: const TextStyle(color: NimbusColors.textPrimary, fontSize: 16)),
      content: Text(message, style: const TextStyle(color: NimbusColors.textDim, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel', style: TextStyle(color: NimbusColors.textDim)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(okLabel, style: const TextStyle(color: NimbusColors.red, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result ?? false;
}
