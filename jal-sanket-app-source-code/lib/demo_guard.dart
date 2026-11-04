// Demo mode guard — checks if this build was compiled with --dart-define=DEMO=true
// Usage: if (DemoGuard.isDemo) { show coming soon } else { navigate normally }

import 'package:flutter/material.dart';

const bool _kIsDemo = bool.fromEnvironment('DEMO', defaultValue: false);

class DemoGuard {
  static bool get isDemo => _kIsDemo;

  /// Show a "Coming Soon" bottom sheet for features not in the demo
  static void showComingSoon(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.rocket_launch_rounded,
                  color: Color(0xFF072146), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              featureName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF072146),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This module is under development.\nFull version coming soon! 🚀',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🏆 Hackathon Demo Build',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF713F12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}