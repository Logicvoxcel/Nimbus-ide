import 'package:flutter/material.dart';

import '../services/language_map.dart';
import '../services/project_service.dart';
import '../theme/nimbus_colors.dart';

class TabStrip extends StatelessWidget {
  const TabStrip({super.key, required this.project});

  final ProjectService project;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: NimbusColors.bgPanel,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: NimbusColors.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: project.openTabs.map((path) {
          final file = project.files[path];
          if (file == null) return const SizedBox.shrink();
          final active = path == project.activeId;
          final color = NimbusColors.forExtension(extensionOf(file.displayName));
          return Container(
            decoration: BoxDecoration(
              color: active ? NimbusColors.bgElevated : null,
              border: Border(
                right: const BorderSide(color: NimbusColors.line),
                bottom: BorderSide(color: active ? NimbusColors.accent : Colors.transparent, width: 2),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => project.setActive(path),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                    child: Row(
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            file.displayName.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: active ? NimbusColors.textPrimary : NimbusColors.textDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => project.closeTab(path),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 8, 10, 8),
                    child: Icon(Icons.close, size: 14, color: NimbusColors.textDim),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
