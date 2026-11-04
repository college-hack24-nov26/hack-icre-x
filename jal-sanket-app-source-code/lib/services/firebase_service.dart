import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/voice_engine.dart';

/// Central Firebase Database Service connecting to Firebase Realtime Database
/// Synchronizes Users, ASHA Voice Consultations, and Doctor Triage & Prescriptions.
class FirebaseService {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  // Official Firebase Project Configuration
  static const String apiKey = 'AIzaSyD6ODP5dOcHGKMtYn-OR7xTcJm-qitc228';
  static const String authDomain = 'esp8266webapp-bd4f4.firebaseapp.com';
  static const String databaseBaseUrl =
      'https://esp8266webapp-bd4f4-default-rtdb.firebaseio.com';
  static const String projectId = 'esp8266webapp-bd4f4';
  static const String storageBucket = 'esp8266webapp-bd4f4.firebasestorage.app';
  static const String messagingSenderId = '494629844979';
  static const String appId = '1:494629844979:web:5ac14862c4982f4b978486';
  static const String measurementId = 'G-XR7972DEXF';

  Map<String, String> get config => {
        'apiKey': apiKey,
        'authDomain': authDomain,
        'databaseURL': databaseBaseUrl,
        'projectId': projectId,
        'storageBucket': storageBucket,
        'messagingSenderId': messagingSenderId,
        'appId': appId,
        'measurementId': measurementId,
      };

  final http.Client _client = http.Client();

  /// Health check verifying live connectivity to Firebase Realtime Database
  Future<bool> checkConnection() async {
    try {
      final res = await _client
          .get(Uri.parse('$databaseBaseUrl/.json?shallow=true'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 1. USERS & STAFF MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Clean Firebase key from invalid characters (. $ # [ ] /)
  String _sanitizeKey(String raw) {
    return raw.replaceAll(RegExp(r'[.$#\[\]/]'), '_').trim();
  }

  /// Save or update a registered user in Firebase: /users/{userId}.json
  Future<bool> saveUser(Map<String, dynamic> user) async {
    final rawId = user['id']?.toString() ?? user['name']?.toString() ?? 'USER_${DateTime.now().millisecondsSinceEpoch}';
    final key = _sanitizeKey(rawId);

    final payload = {
      'id': user['id'] ?? rawId,
      'name': user['name'] ?? '',
      'role': user['role'] ?? 'ASHA Worker',
      'village': user['village'] ?? '',
      'pin': user['pin'] ?? '1234',
      'registeredAt': user['registeredAt'] ?? DateTime.now().toIso8601String(),
      'lastActive': DateTime.now().toIso8601String(),
    };

    try {
      final url = Uri.parse('$databaseBaseUrl/users/$key.json');
      final res = await _client
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.saveUser error (offline fallback): $e');
      return false;
    }
  }

  /// Fetch all registered users from Firebase: /users.json
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/users.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final List<Map<String, dynamic>> list = [];
          decoded.forEach((key, value) {
            if (value is Map) {
              list.add(Map<String, dynamic>.from(value));
            }
          });
          // Sort by registeredAt desc
          list.sort((a, b) => (b['registeredAt'] ?? '').compareTo(a['registeredAt'] ?? ''));
          return list;
        }
      }
    } catch (e) {
      debugPrint('FirebaseService.fetchUsers error: $e');
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 2. VOICE RECOGNITION CASES (ASHA ↔ DOCTOR CIRCLE)
  // ---------------------------------------------------------------------------

  /// Save a patient case extracted from voice or manual entry into Firebase: /voice_cases/{caseId}.json
  Future<bool> saveVoiceCase(
    SavedCaseRow caseRow, {
    String? ashaId,
    String? ashaName,
  }) async {
    final key = _sanitizeKey(caseRow.id);
    final data = caseRow.toJson();

    // Attach staff context
    if (ashaId != null) data['ashaId'] = ashaId;
    if (ashaName != null) data['ashaName'] = ashaName;
    data['syncedAt'] = DateTime.now().toIso8601String();

    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases/$key.json');
      final res = await _client
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.saveVoiceCase error: $e');
      return false;
    }
  }

  /// Fetch all voice cases from Firebase: /voice_cases.json
  Future<List<SavedCaseRow>> fetchVoiceCases() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final List<SavedCaseRow> list = [];
          decoded.forEach((k, v) {
            if (v is Map) {
              try {
                list.add(SavedCaseRow.fromJson(Map<String, dynamic>.from(v)));
              } catch (_) {}
            }
          });
          // Sort newest first
          list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
          return list;
        }
      }
    } catch (e) {
      debugPrint('FirebaseService.fetchVoiceCases error: $e');
    }
    return [];
  }

  /// Forward a case to the Doctor: patches /voice_cases/{caseId}.json
  Future<bool> forwardCaseToDoctor(
    String caseId, {
    String? notes,
    String priority = 'normal',
    String? ashaId,
    String? ashaName,
  }) async {
    final key = _sanitizeKey(caseId);
    final patchData = {
      'isForwardedToDoctor': true,
      'forwardedAt': DateTime.now().toIso8601String(),
      'priority': priority,
      'doctorStatus': 'pending',
      if (notes != null && notes.isNotEmpty) 'doctorNotes': notes,
      'ashaId': ?ashaId,
      'ashaName': ?ashaName,
    };

    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases/$key.json');
      final res = await _client
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(patchData),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.forwardCaseToDoctor error: $e');
      return false;
    }
  }

  /// Complete the Circle: Doctor reviews case, records diagnosis, clinical notes & prescription
  Future<bool> saveDoctorReview({
    required String caseId,
    required String doctorName,
    String? doctorId,
    required String assessment,
    required String plan,
  }) async {
    final key = _sanitizeKey(caseId);
    final patchData = {
      'doctorStatus': 'reviewed',
      'doctorName': doctorName,
      'doctorId': doctorId ?? 'MO-101',
      'reviewedAt': DateTime.now().toIso8601String(),
      'doctorAssessment': assessment,
      'doctorPlan': plan,
    };

    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases/$key.json');
      final res = await _client
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(patchData),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.saveDoctorReview error: $e');
      return false;
    }
  }

  /// Delete a single voice case from Firebase: DELETE /voice_cases/{caseId}.json
  Future<bool> deleteVoiceCase(String caseId) async {
    final key = _sanitizeKey(caseId);
    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases/$key.json');
      final res = await _client.delete(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.deleteVoiceCase error: $e');
      return false;
    }
  }

  /// Clear all voice cases from Firebase: DELETE /voice_cases.json
  Future<bool> clearAllVoiceCases() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/voice_cases.json');
      final res = await _client.delete(url).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.clearAllVoiceCases error: $e');
      return false;
    }
  }

  /// Save signed clinical consult note: /doctor_consult_notes/{sessionId}.json
  Future<bool> saveConsultNote(
    SignedConsultNote note, {
    String? doctorName,
    String? doctorId,
  }) async {
    final key = _sanitizeKey(note.sessionId);
    final data = note.toJson();
    if (doctorName != null) data['doctorName'] = doctorName;
    if (doctorId != null) data['doctorId'] = doctorId;

    try {
      final url = Uri.parse('$databaseBaseUrl/doctor_consult_notes/$key.json');
      final res = await _client
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200;
    } catch (e) {
      debugPrint('FirebaseService.saveConsultNote error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. IOT SENSOR DATA, THRESHOLDS & VALUE MISMATCH MONITORING
  // ---------------------------------------------------------------------------

  /// Fetch live SENSOR_DATA directly from Firebase: /SENSOR_DATA.json
  Future<Map<String, dynamic>?> fetchSensorData() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/SENSOR_DATA.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('FirebaseService.fetchSensorData error: $e');
    }
    return null;
  }

  /// Fetch CONFIG limits directly from Firebase: /CONFIG.json
  Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/CONFIG.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('FirebaseService.fetchConfig error: $e');
    }
    return null;
  }

  /// Fetch latest test record from Firebase: /TEST_RESULTS.json
  Future<Map<String, dynamic>?> fetchLatestTestResult() async {
    try {
      final url = Uri.parse('$databaseBaseUrl/TEST_RESULTS.json');
      final res = await _client.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded.isNotEmpty) {
          Map<String, dynamic>? latest;
          num maxMs = 0;
          decoded.forEach((k, v) {
            if (v is Map) {
              final ms = (v['endMs'] is num)
                  ? (v['endMs'] as num)
                  : ((v['startMs'] is num) ? (v['startMs'] as num) : 0);
              if (ms >= maxMs) {
                maxMs = ms;
                latest = Map<String, dynamic>.from(v);
              }
            }
          });
          return latest;
        }
      }
    } catch (e) {
      debugPrint('FirebaseService.fetchLatestTestResult error: $e');
    }
    return null;
  }

  /// Evaluates IoT sensor reading against CONFIG limits from the IoT RTDB tags.
  /// If values exceed limits (e.g. TDS > tdsMax or Turbidity > turbidityMax or chlorinationRequired),
  /// returns a structured [IotMismatchAlert] for alerting Jalrakshak / Citizen.
  Future<IotMismatchAlert?> checkIotMismatch() async {
    try {
      final config = await fetchConfig() ?? {'tdsMax': 500, 'turbidityMax': 5, 'maxDoseMl': 50};
      final sensor = await fetchSensorData();
      final latestTest = await fetchLatestTestResult();

      final double tdsLimit = (config['tdsMax'] is num) ? (config['tdsMax'] as num).toDouble() : 500.0;
      final double turbidityLimit = (config['turbidityMax'] is num) ? (config['turbidityMax'] as num).toDouble() : 5.0;

      // 1. Check live SENSOR_DATA
      if (sensor != null) {
        final double? sensorTds = (sensor['TDS'] is num) ? (sensor['TDS'] as num).toDouble() : null;
        final double? sensorTurb = (sensor['TurbidityNTU_Estimate'] is num)
            ? (sensor['TurbidityNTU_Estimate'] as num).toDouble()
            : ((sensor['Turbidity'] is num) ? (sensor['Turbidity'] as num).toDouble() : null);

        if (sensorTds != null && sensorTds > tdsLimit) {
          return IotMismatchAlert(
            id: 'tds-sensor-${DateTime.now().millisecondsSinceEpoch}',
            title: '⚠️ आयओटी इशारा: TDS मर्यादा ओलांडली!',
            subtitle: 'पाण्यातील एकूण विरघळलेले क्षार सुरक्षित निकषापेक्षा जास्त आहेत.',
            parameter: 'TDS (क्षार)',
            currentValue: sensorTds,
            threshold: tdsLimit,
            unit: 'ppm',
            source: 'SENSOR_DATA.TDS',
            recommendation: 'पाणी त्वरित उकळून प्यावे व जलसुरक्षकाने स्त्रोत शुद्धीकरण करावे.',
            detectedAt: DateTime.now(),
          );
        }

        if (sensorTurb != null && sensorTurb > turbidityLimit) {
          return IotMismatchAlert(
            id: 'turb-sensor-${DateTime.now().millisecondsSinceEpoch}',
            title: '⚠️ आयओटी इशारा: पाणी गढूळ आढळले!',
            subtitle: 'पाण्याचा गढूळपणा सुरक्षित मर्यादेपेक्षा (५ NTU) जास्त नोंदवला गेला आहे.',
            parameter: 'Turbidity (गढूळपणा)',
            currentValue: sensorTurb,
            threshold: turbidityLimit,
            unit: 'NTU',
            source: 'SENSOR_DATA.Turbidity',
            recommendation: 'पाण्यात तुरटी फिरवून गाळून घ्यावे व क्लोरीनेशन डोस द्यावा.',
            detectedAt: DateTime.now(),
          );
        }
      }

      // 2. Check latest TEST_RESULTS
      if (latestTest != null) {
        final bool chlorReq = latestTest['chlorinationRequired'] == true;
        final double testTds = (latestTest['TDS'] is num) ? (latestTest['TDS'] as num).toDouble() : 0.0;
        final double testTurb = (latestTest['Turbidity'] is num) ? (latestTest['Turbidity'] as num).toDouble() : 0.0;
        final String waterStatus = (latestTest['waterStatus'] ?? '').toString();

        if (chlorReq || waterStatus.toLowerCase().contains('alert') || waterStatus.toLowerCase().contains('contaminat')) {
          return IotMismatchAlert(
            id: 'test-chlor-${latestTest['testId'] ?? DateTime.now().millisecondsSinceEpoch}',
            title: '⚠️ आयओटी चाचणी इशारा: तातडीचे क्लोरीनेशन आवश्यक!',
            subtitle: 'जल चाचणी अहवालानुसार पाण्याच्या स्त्रोतामध्ये तात्काळ निर्जंतुकीकरण आवश्यक आहे.',
            parameter: 'Chlorination Status',
            currentValue: testTurb > 0 ? testTurb : 1.0,
            threshold: 0.0,
            unit: 'Alert',
            source: 'TEST_RESULTS.${latestTest['testId'] ?? 'latest'}',
            recommendation: 'जलसुरक्षकाने लगेच विहिरीत / टाकीत निर्धारित टीसीएल (TCL) डोस टाकावा.',
            detectedAt: DateTime.now(),
          );
        }

        if (testTds > tdsLimit) {
          return IotMismatchAlert(
            id: 'test-tds-${latestTest['testId'] ?? DateTime.now().millisecondsSinceEpoch}',
            title: '⚠️ चाचणी अहवाल: TDS मर्यादा ओलांडली!',
            subtitle: 'प्रयोगशाळा/IoT चाचणीत TDS सुरक्षित मर्यादेपेक्षा जास्त आढळला आहे.',
            parameter: 'TDS (क्षार)',
            currentValue: testTds,
            threshold: tdsLimit,
            unit: 'ppm',
            source: 'TEST_RESULTS.${latestTest['testId'] ?? 'latest'}',
            recommendation: 'नागरिकांनी पाणी किमान २० मिनिटे उकळून प्यावे.',
            detectedAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('checkIotMismatch error: $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. INITIAL DATABASE SEEDING (COMPLETING THE SYSTEM CIRCLE)
  // ---------------------------------------------------------------------------

  /// Seeds default users and initial sample voice cases into Firebase if empty
  Future<void> seedInitialDataIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('firebase_seeded_v3') == true) return;

      // Seed standard staff
      final defaultUsers = [
        {'id': 'MO-101', 'name': 'Dr. Patil', 'role': 'Medical Officer', 'village': 'शिरोळ (Shirol)', 'pin': '1234'},
        {'id': 'ASHA-402', 'name': 'Sunita Kamble', 'role': 'ASHA Worker', 'village': 'शिरोळ (Shirol)', 'pin': '1234'},
        {'id': 'THO-201', 'name': 'Dr. Deshmukh', 'role': 'THO', 'village': 'हातकणंगले (Hatkanangle)', 'pin': '1234'},
        {'id': 'BDO-301', 'name': 'Rajesh More', 'role': 'BDO', 'village': 'शिरोळ (Shirol)', 'pin': '1234'},
        {'id': 'JR-501', 'name': 'Ramesh Pawar', 'role': 'Jalrakshak', 'village': 'शिरोळ (Shirol)', 'pin': '1234'},
        {'id': 'CIT-901', 'name': 'Sachin Jadhav', 'role': 'Citizen', 'village': 'शिरोळ (Shirol)', 'pin': '1234'},
      ];

      for (final u in defaultUsers) {
        await saveUser(u);
      }

      // Seed initial high-priority cases from LocalStore
      final demoCases = LocalStore.initialDemoCases;
      for (final c in demoCases) {
        // Ensure both demo cases are forwarded to Doctor so Doctor triage has immediate data
        final fwdCase = c.copyWith(
          isForwardedToDoctor: true,
          doctorStatus: c.doctorStatus == 'reviewed' ? 'reviewed' : 'pending',
          priority: c.severityFlag ? 'urgent' : 'normal',
        );
        await saveVoiceCase(fwdCase, ashaId: 'ASHA-402', ashaName: 'Sunita Kamble');
      }

      await prefs.setBool('firebase_seeded_v3', true);
      debugPrint('Firebase initial data seeded successfully (v3 with doctor sync).');
    } catch (e) {
      debugPrint('seedInitialDataIfNeeded error: $e');
    }
  }
}

/// Model representing a detected IoT sensor mismatch from Firebase RTDB (SENSOR_DATA/CONFIG/TEST_RESULTS)
class IotMismatchAlert {
  final String id;
  final String title;
  final String subtitle;
  final String parameter;
  final double currentValue;
  final double threshold;
  final String unit;
  final String source;
  final String recommendation;
  final DateTime detectedAt;

  IotMismatchAlert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.parameter,
    required this.currentValue,
    required this.threshold,
    required this.unit,
    required this.source,
    required this.recommendation,
    required this.detectedAt,
  });
}
