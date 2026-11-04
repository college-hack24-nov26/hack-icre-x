// ─────────────────────────────────────────────────────────────────────────────
//  JalSanket — DEMO BUILD
//  Only Login + Voice modules are active.
//  All other screens show a "Coming Soon" placeholder.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const JalSanketDemoApp());
}

class JalSanketDemoApp extends StatelessWidget {
  const JalSanketDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalSanket Demo',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF072146),
          primary: const Color(0xFF072146),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

