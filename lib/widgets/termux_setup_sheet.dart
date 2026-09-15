import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/termux_bridge.dart';
import '../theme/nimbus_colors.dart';

Future<void> showTermuxSetupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: NimbusColors.bgPanel,
    isScrollControlled: true,
    builder: (context) => const _TermuxSetupSheet(),
  );
}

class _TermuxSetupSheet extends StatefulWidget {
  const _TermuxSetupSheet();

  @override
  State<_TermuxSetupSheet> createState() => _TermuxSetupSheetState();
}

class _TermuxSetupSheetState extends State<_TermuxSetupSheet> {
  bool loading = true;
  bool installed = false;
  bool permitted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => loading = true);
    final inst = await TermuxBridge.isInstalled();
    final perm = inst ? await TermuxBridge.hasPermission() : false;
    if (mounted) {
      setState(() {
        installed = inst;
        permitted = perm;
        loading = false;
      });
    }
  }

  Future<void> _openInstallPage() async {
    final uri = Uri.parse('https://f-droid.org/packages/com.termux/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Run Python, C, Java & more',
              style: TextStyle(color: NimbusColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nimbus runs these through Termux, a free terminal app, instead of '
              'bundling a separate paid engine for every language.',
              style: TextStyle(color: NimbusColors.textDim, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: NimbusColors.accent)),
              )
            else ...[
              _StatusRow(label: 'Termux installed', ok: installed),
              const SizedBox(height: 8),
              _StatusRow(label: 'Permission granted', ok: permitted),
              const SizedBox(height: 20),
              if (!installed) ...[
                _StepButton(
                  label: 'Get Termux from F-Droid',
                  onTap: _openInstallPage,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use F-Droid or GitHub releases, not the Play Store listing -- '
                  'it was discontinued years ago and no longer works properly.',
                  style: TextStyle(color: NimbusColors.textDim, fontSize: 11, height: 1.4),
                ),
              ] else if (!permitted) ...[
                _StepButton(
                  label: 'Grant permission',
                  onTap: () async {
                    await TermuxBridge.requestPermission();
                    await Future.delayed(const Duration(milliseconds: 400));
                    _check();
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'If nothing happens, grant it manually: Settings → Apps → '
                  'Nimbus IDE → Permissions.',
                  style: TextStyle(color: NimbusColors.textDim, fontSize: 11, height: 1.4),
                ),
              ] else ...[
                const Text(
                  'One-time setup, run inside Termux itself:',
                  style: TextStyle(color: NimbusColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const _CommandBlock('termux-setup-storage'),
                const SizedBox(height: 6),
                const _CommandBlock('pkg install python nodejs golang rust ruby openjdk-17 clang -y'),
                const SizedBox(height: 8),
                const Text(
                  'Only install what you actually plan to run -- each package '
                  'download adds to that one-time setup.',
                  style: TextStyle(color: NimbusColors.textDim, fontSize: 11, height: 1.4),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _check,
                  child: const Text('Re-check status', style: TextStyle(color: NimbusColors.accent)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? NimbusColors.teal : NimbusColors.textDim,
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: NimbusColors.textPrimary, fontSize: 13)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: NimbusColors.accent,
          foregroundColor: NimbusColors.bgVoid,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  const _CommandBlock(this.command);
  final String command;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NimbusColors.bgVoid,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NimbusColors.line),
      ),
      child: Text(
        command,
        style: const TextStyle(color: NimbusColors.teal, fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
