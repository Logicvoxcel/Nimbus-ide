import 'package:flutter/material.dart';

import '../models/code_file.dart';
import '../services/language_map.dart';
import '../services/project_service.dart';
import '../theme/nimbus_colors.dart';
import 'prompt_dialog.dart';

class FileExplorerDrawer extends StatelessWidget {
  const FileExplorerDrawer({super.key, required this.project});

  final ProjectService project;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: NimbusColors.bgPanel,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      project.projectLabel.toUpperCase(),
                      style: const TextStyle(
                        color: NimbusColors.textDim,
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'New file',
                    icon: const Icon(Icons.add, color: NimbusColors.textPrimary, size: 20),
                    onPressed: () => _createFile(context),
                  ),
                ],
              ),
            ),
            const Divider(color: NimbusColors.line, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _DrawerAction(
                icon: Icons.folder_open,
                label: 'Open folder (device)',
                onTap: () => _openFolder(context),
              ),
            ),
            const Divider(color: NimbusColors.line, height: 1),
            Expanded(
              child: ListView(
                children: project.orderedFiles
                    .map((f) => _FileRow(
                          file: f,
                          isActive: f.path == project.activeId,
                          project: project,
                        ))
                    .toList(),
              ),
            ),
            const Divider(color: NimbusColors.line, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DrawerAction(
                    icon: Icons.upload_file,
                    label: 'Import files…',
                    onTap: () => _importFiles(context),
                  ),
                  _DrawerAction(
                    icon: Icons.folder_zip,
                    label: 'Import project (.zip)',
                    onTap: () => _importZip(context),
                  ),
                  _DrawerAction(
                    icon: Icons.ios_share,
                    label: 'Export project (.zip)',
                    onTap: () => project.exportZip(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'Files live on your device. Nothing is uploaded anywhere.',
                style: TextStyle(color: NimbusColors.textDim, fontSize: 10, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFile(BuildContext context) async {
    final name = await promptForName(
      context,
      title: 'New file',
      okLabel: 'Create',
      validate: (value) async {
        if (value.trim().isEmpty) return 'Enter a file name';
        return null;
      },
    );
    if (name == null || name.trim().isEmpty) return;
    final error = await project.createFile(name.trim());
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openFolder(BuildContext context) async {
    final error = await project.openExternalFolder();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _importFiles(BuildContext context) async {
    final count = await project.importFiles();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(count == 0 ? 'No files imported' : '$count file(s) imported')),
      );
    }
  }

  Future<void> _importZip(BuildContext context) async {
    final count = await project.importZip();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(count == 0 ? 'No files imported' : '$count file(s) imported')),
      );
    }
  }
}

class _DrawerAction extends StatelessWidget {
  const _DrawerAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: NimbusColors.accent),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: NimbusColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.isActive, required this.project});

  final CodeFile file;
  final bool isActive;
  final ProjectService project;

  @override
  Widget build(BuildContext context) {
    final color = NimbusColors.forExtension(extensionOf(file.displayName));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? NimbusColors.bgElevated : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                project.openTab(file.path);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.lang.badge,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: NimbusColors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18, color: NimbusColors.textDim),
            onPressed: () => _showActions(context),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: NimbusColors.bgPanel,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                file.displayName,
                style: const TextStyle(color: NimbusColors.textDim, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(color: NimbusColors.line, height: 1),
            ListTile(
              title: const Text('Rename', style: TextStyle(color: NimbusColors.textPrimary)),
              onTap: () {
                Navigator.of(context).pop();
                _rename(context);
              },
            ),
            ListTile(
              title: const Text('Export / Share', style: TextStyle(color: NimbusColors.textPrimary)),
              onTap: () {
                Navigator.of(context).pop();
                project.exportFile(file.path);
              },
            ),
            ListTile(
              title: const Text('Delete', style: TextStyle(color: NimbusColors.red)),
              onTap: () async {
                Navigator.of(context).pop();
                final ok = await confirmAction(
                  context,
                  title: 'Delete file',
                  message: 'Delete "${file.displayName}"? This can\u2019t be undone.',
                  okLabel: 'Delete',
                );
                if (ok) await project.deleteFile(file.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final name = await promptForName(
      context,
      title: 'Rename file',
      initial: file.displayName.split('/').last,
      okLabel: 'Rename',
      validate: (value) async {
        if (value.trim().isEmpty) return 'Enter a file name';
        return null;
      },
    );
    if (name == null) return;
    final error = await project.renameFile(file.path, name.trim());
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
