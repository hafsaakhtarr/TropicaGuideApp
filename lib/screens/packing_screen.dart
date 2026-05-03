import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/packing_screen.dart';
import 'screens/optimizer_screen.dart';
import 'screens/checklist_screen.dart';

void main() {
  runApp(const TropicaGuideApp());
}

class TropicaGuideApp extends StatelessWidget {
  const TropicaGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TropicaGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TColors.bg,
        fontFamily: 'Nunito',
      ),
      // Start on packing screen for now — swap to your nav later
      home: const PackingScreen(),
      routes: {
        '/packing':   (_) => const PackingScreen(),
        '/optimizer': (_) => const OptimizerScreen(),
        '/checklist': (_) => const ChecklistScreen(),
      },
    );
  }
}