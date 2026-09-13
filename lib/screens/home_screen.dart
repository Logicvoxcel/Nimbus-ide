import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import '../services/js_runner.dart';
import '../services/language_map.dart';
import '../services/project_service.dart';
import '../theme/nimbus_colors.dart';
import '../widgets/accessory_bar.dart';
import '../widgets/console_panel.dart';
import '../widgets/file_explorer_drawer.dart';
import '../widgets/tab_strip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectService project = ProjectService();
  final JsRunner jsRunner = JsRunner();

  bool loading = true;
  bool showConsole = false;
  final List<ConsoleLine> consoleLines = [];

  @override
  void initState() {
    super.initState();
    project.addListener(_onProjectChanged);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await project.init();
    if (mounted) setState(() => loading = false);
  }

  void _onProjectChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    project.removeListener(_onProjectChanged);
    project.disposeAll();
    jsRunner.dispose();
    super.dispose();
  }

  Future<void> _runActive() async {
    final file = project.activeFile;
    if (file == null) return;
    setState(() {
      showConsole = true;
      consoleLines.clear();
    });
    await jsRunner.run(file.controller.text, (line, isError) {
      if (mounted) setState(() => consoleLines.add(ConsoleLine(line, isError)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeFile = project.activeFile;
    final canRun = activeFile != null && isRunnableJs(activeFile.displayName);

    return Scaffold(
      backgroundColor: NimbusColors.bgVoid,
      drawer: FileExplorerDrawer(project: project),
      appBar: AppBar(
        backgroundColor: NimbusColors.bgPanel,
        elevation: 0,
        iconTheme: const IconThemeData(color: NimbusColors.textPrimary),
        title: const Text(
          'Nimbus IDE',
          style: TextStyle(fontSize: 16, color: NimbusColors.textPrimary),
        ),
        actions: [
          if (canRun)
            IconButton(
              tooltip: 'Run',
              icon: const Icon(Icons.play_arrow, color: NimbusColors.accent),
              onPressed: _runActive,
            ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(project.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
            onPressed: project.toggleTheme,
          ),
          PopupMenuButton<String>(
            tooltip: 'Font size',
            icon: const Icon(Icons.text_fields, size: 20),
            color: NimbusColors.bgElevated,
            onSelected: (v) {
              if (v == 'inc') project.setFontSize(project.fontSize + 1);
              if (v == 'dec') project.setFontSize(project.fontSize - 1);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'inc', child: Text('Increase font size', style: TextStyle(color: NimbusColors.textPrimary))),
              PopupMenuItem(value: 'dec', child: Text('Decrease font size', style: TextStyle(color: NimbusColors.textPrimary))),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: NimbusColors.accent))
          : SafeArea(
              child: Column(
                children: [
                  TabStrip(project: project),
                  Expanded(
                    child: activeFile == null
                        ? const Center(
                            child: Text('No file open', style: TextStyle(color: NimbusColors.textDim)),
                          )
                        : Container(
                            width: double.infinity,
                            color: NimbusColors.bgVoid,
                            child: CodeTheme(
                              data: CodeThemeData(styles: project.isDark ? monokaiSublimeTheme : githubTheme),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(12),
                                child: CodeField(
                                  key: ValueKey(activeFile.path),
                                  controller: activeFile.controller,
                                  textStyle: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: project.fontSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (showConsole)
                    ConsolePanel(
                      lines: consoleLines,
                      onClear: () => setState(() => consoleLines.clear()),
                      onClose: () => setState(() => showConsole = false),
                    ),
                  if (activeFile != null) AccessoryBar(controller: activeFile.controller),
                ],
              ),
            ),
    );
  }
}
