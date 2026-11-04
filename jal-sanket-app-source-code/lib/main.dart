import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const JalSanketApp());
}

class JalSanketApp extends StatelessWidget {
  const JalSanketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalSanket',
      debugShowCheckedModeBanner: false,
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
