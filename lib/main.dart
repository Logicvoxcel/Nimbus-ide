import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/nimbus_colors.dart';

void main() {
  runApp(const NimbusApp());
}

class NimbusApp extends StatelessWidget {
  const NimbusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nimbus IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: NimbusColors.bgVoid,
        colorScheme: const ColorScheme.dark(
          primary: NimbusColors.accent,
          secondary: NimbusColors.teal,
          surface: NimbusColors.bgPanel,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: NimbusColors.bgElevated,
          contentTextStyle: TextStyle(color: NimbusColors.textPrimary),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
