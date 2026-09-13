import 'package:flutter/material.dart';

import '../theme/nimbus_colors.dart';

class ConsoleLine {
  ConsoleLine(this.text, this.isError);
  final String text;
  final bool isError;
}

class ConsolePanel extends StatelessWidget {
  const ConsolePanel({
    super.key,
    required this.lines,
    required this.onClear,
    required this.onClose,
  });

  final List<ConsoleLine> lines;
  final VoidCallback onClear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      color: NimbusColors.bgPanel,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NimbusColors.line)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: NimbusColors.line)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Console', style: TextStyle(color: NimbusColors.textDim, fontSize: 12)),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear', style: TextStyle(color: NimbusColors.textDim, fontSize: 11)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: NimbusColors.textDim),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: Text('No output yet', style: TextStyle(color: NimbusColors.textDim, fontSize: 12)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: lines.length,
                    itemBuilder: (context, i) {
                      final line = lines[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          line.text,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: line.isError ? NimbusColors.red : NimbusColors.textPrimary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
