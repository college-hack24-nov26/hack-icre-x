import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service connecting to native Android NotificationManager via MethodChannel.
/// Ensures real-time alerts appear directly in the mobile system notification panel / shade.
class SystemNotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.example.jal_sanket_2/system_notifications');

  /// Displays an alert in Android's notification shade with high priority, sound and vibration.
  /// Automatically dismisses from the notification panel after [autoDismissSeconds] (default: 30 seconds).
  static Future<void> showIotAlertNotification({
    int id = 1001,
    required String title,
    required String body,
    int autoDismissSeconds = 30,
  }) async {
    try {
      await _channel.invokeMethod('showSystemNotification', {
        'id': id,
        'title': title,
        'body': body,
      });

      if (autoDismissSeconds > 0) {
        Future.delayed(Duration(seconds: autoDismissSeconds), () {
          cancelNotification(id);
        });
      }
    } catch (e) {
      debugPrint('SystemNotificationService.showIotAlertNotification error: $e');
    }
  }

  /// Dismisses / wipes out the notification from the mobile notification panel
  static Future<void> cancelNotification(int id) async {
    try {
      await _channel.invokeMethod('cancelSystemNotification', {'id': id});
    } catch (_) {}
  }
}
