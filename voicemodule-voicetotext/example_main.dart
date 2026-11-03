import 'package:flutter/material.dart';
import 'voice_module.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  Voice Module — Standalone Example / Entry Point
///
///  Run directly with:
///    flutter run voice_module/example_main.dart
///
///  Or integrate into your existing app:
///    Navigator.of(context).push(
///      MaterialPageRoute(builder: (_) => const VoiceScreen()),
///    );
/// ─────────────────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoiceModuleApp());
}

class VoiceModuleApp extends StatelessWidget {
  const VoiceModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalSanket Voice AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF072146),
          primary: const Color(0xFF072146),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF072146),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const VoiceScreen(
        userName: 'Anita Kulkarni',
        userId: 'A-412',
        userRole: 'ASHA Worker', // Switch to 'Medical Officer' to view doctor triage
        showBottomNav: false,
      ),
    );
  }
}

