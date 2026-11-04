import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

/// Model representing a stored IoT Alert History record
class AlertHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String parameter;
  final double currentValue;
  final double threshold;
  final String unit;
  final String source;
  final String recommendation;
  final String role;
  final DateTime timestamp;
  final String status; // 'active', 'dismissed', 'resolved'

  AlertHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.parameter,
    required this.currentValue,
    required this.threshold,
    required this.unit,
    required this.source,
    required this.recommendation,
    required this.role,
    required this.timestamp,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'parameter': parameter,
        'currentValue': currentValue,
        'threshold': threshold,
        'unit': unit,
        'source': source,
        'recommendation': recommendation,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  factory AlertHistoryItem.fromJson(Map<String, dynamic> json) {
    return AlertHistoryItem(
      id: json['id']?.toString() ?? 'alert-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'IoT Alert',
      subtitle: json['subtitle']?.toString() ?? '',
      parameter: json['parameter']?.toString() ?? 'Sensor',
      currentValue: (json['currentValue'] is num) ? (json['currentValue'] as num).toDouble() : 0.0,
      threshold: (json['threshold'] is num) ? (json['threshold'] as num).toDouble() : 0.0,
      unit: json['unit']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Citizen',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      status: json['status']?.toString() ?? 'active',
    );
  }
}

/// Service managing persistent IoT Alert History across sessions and Firebase RTDB
class AlertHistoryService {
  static const String historyKey = 'jal_sanket_iot_alert_history';

  /// Save an alert item to history (both local SharedPreferences and Firebase RTDB)
  static Future<void> recordAlert(IotMismatchAlert alert, {required String role}) async {
    final item = AlertHistoryItem(
      id: alert.id,
      title: alert.title,
      subtitle: alert.subtitle,
      parameter: alert.parameter,
      currentValue: alert.currentValue,
      threshold: alert.threshold,
      unit: alert.unit,
      source: alert.source,
      recommendation: alert.recommendation,
      role: role,
      timestamp: alert.detectedAt,
      status: 'active',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(historyKey);
      final List list = raw != null ? jsonDecode(raw) : [];
      list.removeWhere((e) => e['id'] == item.id);
      list.insert(0, item.toJson());
      if (list.length > 50) list.removeRange(50, list.length);
      await prefs.setString(historyKey, jsonEncode(list));
    } catch (e) {
      debugPrint('AlertHistoryService.recordAlert local error: $e');
    }

    // Sync to Firebase RTDB: /IOT_ALERTS_HISTORY/{id}.json
    try {
      await FirebaseService.instance.saveAlertHistory(item.toJson());
    } catch (_) {}
  }

  /// Get all alert history items, sorted newest first
  static Future<List<AlertHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(historyKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        return list.map((e) => AlertHistoryItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Clear all alert history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(historyKey);
    } catch (_) {}
  }
}

