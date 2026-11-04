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
  // 3. INITIAL DATABASE SEEDING (COMPLETING THE SYSTEM CIRCLE)
  // ---------------------------------------------------------------------------

  /// Seeds default users and initial sample voice cases into Firebase if empty
  Future<void> seedInitialDataIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('firebase_seeded_v2') == true) return;

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
        await saveVoiceCase(c, ashaId: 'ASHA-402', ashaName: 'Sunita Kamble');
      }

      await prefs.setBool('firebase_seeded_v2', true);
      debugPrint('Firebase initial data seeded successfully.');
    } catch (e) {
      debugPrint('seedInitialDataIfNeeded error: $e');
    }
  }
}
