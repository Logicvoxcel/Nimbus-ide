import 'package:flutter/material.dart';

/// Brand palette — carried over from the original web/HTML version of
/// Nimbus so the Flutter app looks and feels like the same product.
class NimbusColors {
  NimbusColors._();

  static const bgVoid = Color(0xFF0D0F14);
  static const bgPanel = Color(0xFF14171F);
  static const bgElevated = Color(0xFF1B1F2A);
  static const line = Color(0xFF262B38);
  static const textPrimary = Color(0xFFE4E6EB);
  static const textDim = Color(0xFF7C8394);
  static const accent = Color(0xFFE8A33D);
  static const accentDim = Color(0xFF8A6A32);
  static const teal = Color(0xFF4FBFA8);
  static const red = Color(0xFFE5586B);

  /// Small per-extension accent colors for file badges/tab dots.
  static const Map<String, Color> languageColors = {
    'html': Color(0xFFE8A33D),
    'htm': Color(0xFFE8A33D),
    'css': Color(0xFF4FA8E8),
    'scss': Color(0xFFE85F9C),
    'js': Color(0xFFE8D93D),
    'mjs': Color(0xFFE8D93D),
    'jsx': Color(0xFF4FD1C5),
    'ts': Color(0xFF4F7FE8),
    'tsx': Color(0xFF4F9FE8),
    'json': Color(0xFFB0B8C4),
    'py': Color(0xFF4FBFA8),
    'java': Color(0xFFE8763D),
    'c': Color(0xFF8AA6E8),
    'h': Color(0xFF8AA6E8),
    'cpp': Color(0xFF8A6AE8),
    'cc': Color(0xFF8A6AE8),
    'hpp': Color(0xFF8A6AE8),
    'cs': Color(0xFF8A5FE8),
    'go': Color(0xFF4FD1C5),
    'rs': Color(0xFFE8763D),
    'rb': Color(0xFFE5586B),
    'php': Color(0xFF8A8AE8),
    'swift': Color(0xFFE8763D),
    'kt': Color(0xFFB085E8),
    'sql': Color(0xFF4FA8E8),
    'sh': Color(0xFFB0B8C4),
    'bash': Color(0xFFB0B8C4),
    'yml': Color(0xFFE85F9C),
    'yaml': Color(0xFFE85F9C),
    'md': Color(0xFFB0B8C4),
    'xml': Color(0xFFE8A33D),
    'dart': Color(0xFF4FBFE8),
    'lua': Color(0xFF4F7FE8),
    'r': Color(0xFF4F7FE8),
    'scala': Color(0xFFE5586B),
    'ini': Color(0xFFB0B8C4),
    'txt': Color(0xFF7C8394),
  };

  static Color forExtension(String ext) =>
      languageColors[ext.toLowerCase()] ?? textDim;
}
