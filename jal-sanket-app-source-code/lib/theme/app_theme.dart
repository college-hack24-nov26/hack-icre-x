import 'package:flutter/material.dart';

/// Centralized JalSanket Design System Tokens
/// Pure architectural, Swiss precision styling with sharp rectangular cards,
/// authoritative typography, and the official JalSanket Logo color harmony.
class AppTheme {
  // Brand Logo Color Palette
  static const Color navy = Color(0xFF062B5B);       // Primary deep brand blue
  static const Color primaryBlue = Color(0xFF0284C7); // Mid water blue
  static const Color cyan = Color(0xFF00BCD4);        // Clean water cyan accent
  static const Color darkSlate = Color(0xFF0F172A);   // Executive slate text
  static const Color textSecondary = Color(0xFF475569);// Subtitle text
  static const Color textMuted = Color(0xFF64748B);    // Muted text
  static const Color background = Color(0xFFF1F5F9);   // Uniform app-wide slate background
  static const Color cardWhite = Color(0xFFFFFFFF);   // Pure white card surfaces
  static const Color border = Color(0xFFCBD5E1);      // Precision 1px hairline border
  static const Color borderLight = Color(0xFFE2E8F0); // Subtle card border

  // Status Indicators
  static const Color safeGreen = Color(0xFF16A34A);
  static const Color safeBg = Color(0xFFF0FDF4);
  static const Color watchAmber = Color(0xFFD97706);
  static const Color watchBg = Color(0xFFFEF3C7);
  static const Color alertRed = Color(0xFFDC2626);
  static const Color alertBg = Color(0xFFFEF2F2);

  // Card Geometry: Strict zero radius as requested
  static const BorderRadius cardRadius = BorderRadius.zero;

  // Reusable Sharp Card Box Decoration
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      color: color ?? cardWhite,
      borderRadius: BorderRadius.zero,
      border: Border.all(
        color: borderColor ?? borderLight,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  // Header Gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [navy, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
