import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'voice_engine.dart';

class GeminiService {
  static const String defaultApiKey = 'AQ.Ab8RN6K4G0ytlw_07UXfaOvuqIFFzGn5beFvxYg8DxQeWNMmJA';
  static const String primaryModel = 'gemini-3.5-flash';
  static const String fallbackModel = 'gemini-2.5-flash';

  static Future<String> getApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString('custom_gemini_api_key');
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim();
      }
    } catch (_) {}
    return defaultApiKey;
  }

  static Future<VoiceExtraction> extract(
    String transcript, {
    String? villageHint,
    bool mr = true,
  }) async {
    final apiKey = await getApiKey();

    final systemInstruction = '''
You are an expert clinical epidemiology and triage system for rural Primary Health Centres (PHCs) in Maharashtra, India.
Transcribe and extract structured clinical fields from this spoken Marathi / Hindi / English transcript into a JSON object.

RULES:
1. ONLY extract what was explicitly stated or clearly implied by the patient/ASHA worker. If not mentioned, set the field to null.
2. Normalise all number words to numeric digits (e.g. "एक"=1, "दोन"=2, "तीन"=3, "चार"=4, "पाच"=5, "सहा"=6, "सात"=7, "आठ"=8, "नऊ"=9, "दहा"=10, "वीस"=20, "बावीस"=22, "बत्तीस"=32).
3. "symptoms" must be a list containing ONLY applicable keys from this vocabulary:
   - "diarrhoea", "vomiting", "fever", "typhoid", "jaundice", "cholera", "gastro", "abdominal_pain", "weakness", "thirst", "sunken_eyes", "blood_in_stool".
   - Note: If patient has "पोट दुखी" or "पोटदुखी", map to "abdominal_pain".
   - If patient has "जुलाब" or "पातळ संडास", map to "diarrhoea".
   - If patient has "उलटी" or "उलट्या", map to "vomiting".
   - If patient has "ताप", map to "fever".
4. Evaluate water-borne outbreak risk:
   - "isWaterBorne": true if symptoms include diarrhoea, vomiting, cholera, jaundice, gastro, or typhoid.
   - "waterRiskPercent": integer between 10 and 95 based on severity (e.g. 80-95 for cholera/blood in stool/sunken eyes, 50-75 for fever+diarrhoea, 20-40 for mild abdominal pain).
   - "waterRiskReason": concise explanation in ${mr ? 'Marathi' : 'English'}.
5. Return JSON ONLY with the exact schema:
{
  "transcript": string,
  "patientName": string or null,
  "ageYears": integer or null,
  "gender": "male" or "female" or "other" or null,
  "village": string or null,
  "durationDays": integer or null,
  "stoolsPerDay": integer or null,
  "vomitCount": integer or null,
  "fever": boolean or null,
  "diarrhoea": boolean or null,
  "vomiting": boolean or null,
  "bloodInStool": boolean or null,
  "ableToDrink": boolean or null,
  "verySleepy": boolean or null,
  "urinePassed": boolean or null,
  "waterSource": string or null,
  "othersSickAtHome": boolean or null,
  "orsGiven": boolean or null,
  "pregnancy": boolean or null,
  "infant": boolean or null,
  "symptoms": string[],
  "isWaterBorne": boolean,
  "waterRiskPercent": integer,
  "waterRiskReason": string
}
''';

    final userContent = '''
Transcript: "$transcript"
${villageHint != null && villageHint.trim().isNotEmpty ? 'Village context from UI: $villageHint' : ''}
Extract into JSON:
''';

    Map<String, dynamic>? parsedJson;
    String usedModel = primaryModel;

    for (final model in [primaryModel, fallbackModel]) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final requestBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '$systemInstruction\n\n$userContent'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'temperature': 0.1,
          }
        });

        final resp = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'aistudio-build',
          },
          body: requestBody,
        ).timeout(const Duration(seconds: 12));

        if (resp.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
          final text = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            final cleanText = text.replaceAll(RegExp(r'^```json\s*|^```\s*|```$', multiLine: true), '').trim();
            parsedJson = jsonDecode(cleanText) as Map<String, dynamic>;
            usedModel = model;
            break;
          }
        } else {
          debugPrint('Gemini API $model returned status ${resp.statusCode}: ${resp.body}');
        }
      } catch (e) {
        debugPrint('Gemini extraction error with $model: $e');
      }
    }

    if (parsedJson == null) {
      debugPrint('Gemini extraction failed, using fallback heuristic parser');
      return _buildFallbackExtraction(transcript, villageHint, mr);
    }

    return _buildVoiceExtractionFromJson(parsedJson, transcript, usedModel, villageHint);
  }

  static VoiceExtraction _buildVoiceExtractionFromJson(
    Map<String, dynamic> j,
    String originalTranscript,
    String model,
    String? villageHint,
  ) {
    VField<T> makeField<T>(dynamic val, {double conf = 0.95}) {
      if (val == null) {
        return VField<T>(value: null, conf: 0.0, status: 'missing');
      }
      return VField<T>(
        value: val as T,
        conf: conf,
        evidence: originalTranscript,
        status: 'ok',
      );
    }

    // Symptom vocabulary mapping
    final symptomMapping = {
      'abdominal_pain': 'abdominal_pain',
      'पोटदुखी': 'abdominal_pain',
      'पोट दुखी': 'abdominal_pain',
      'stomach pain': 'abdominal_pain',
      'diarrhoea': 'diarrhoea',
      'diarrhea': 'diarrhoea',
      'जुलाब': 'diarrhoea',
      'पातळ शौच': 'diarrhoea',
      'vomiting': 'vomiting',
      'उलट्या': 'vomiting',
      'उलटी': 'vomiting',
      'fever': 'fever',
      'ताप': 'fever',
      'typhoid': 'typhoid',
      'टायफॉइड': 'typhoid',
      'टायफॉईड': 'typhoid',
      'jaundice': 'jaundice',
      'कावीळ': 'jaundice',
      'cholera': 'cholera',
      'कॉलरा': 'cholera',
      'gastro': 'gastro',
      'गॅस्ट्रो': 'gastro',
      'weakness': 'weakness',
      'अशक्तपणा': 'weakness',
      'thirst': 'thirst',
      'तहान': 'thirst',
      'sunken_eyes': 'sunken_eyes',
      'blood_in_stool': 'blood_in_stool',
      'रक्तयुक्त संडास': 'blood_in_stool',
    };

    final symList = <String>[];
    if (j['symptoms'] is List) {
      for (final s in j['symptoms'] as List) {
        if (s is String && s.isNotEmpty) {
          final mapped = symptomMapping[s.toLowerCase().trim()] ?? s;
          if (!symList.contains(mapped)) symList.add(mapped);
        }
      }
    }

    // Direct checks from text & booleans
    final low = originalTranscript.toLowerCase();
    if (low.contains('पोट दुखी') || low.contains('पोटदुखी') || low.contains('stomach')) {
      if (!symList.contains('abdominal_pain')) symList.add('abdominal_pain');
    }
    if (low.contains('जुलाब') || low.contains('diarrh') || j['diarrhoea'] == true) {
      if (!symList.contains('diarrhoea')) symList.add('diarrhoea');
    }
    if (low.contains('उलट्या') || low.contains('उलटी') || low.contains('vomit') || j['vomiting'] == true) {
      if (!symList.contains('vomiting')) symList.add('vomiting');
    }
    if (low.contains('ताप') || low.contains('fever') || j['fever'] == true) {
      if (!symList.contains('fever')) symList.add('fever');
    }
    if (low.contains('रक्त') || j['bloodInStool'] == true) {
      if (!symList.contains('blood_in_stool')) symList.add('blood_in_stool');
    }

    String? patientName = j['patientName'] as String?;
    if (patientName == null || patientName.isEmpty) {
      // Heuristic fallback for Marathi name
      final nameMatch = RegExp(r'(?:नाव|name\s*is)\s*[:=]?\s*([^\n,]+?)(?=\s+वय|\s+गाव|\s+दोन|\s+\d|$)').firstMatch(originalTranscript);
      if (nameMatch != null) {
        patientName = nameMatch.group(1)?.trim();
      }
    }

    int? ageYears = j['ageYears'] is num ? (j['ageYears'] as num).toInt() : null;
    if (ageYears == null) {
      final ageMatch = RegExp(r'(?:वय|age)\s*[:=]?\s*(\d+)').firstMatch(originalTranscript);
      if (ageMatch != null) {
        ageYears = int.tryParse(ageMatch.group(1)!);
      }
    }

    int? durationDays = j['durationDays'] is num ? (j['durationDays'] as num).toInt() : null;
    if (durationDays == null) {
      final daysMatch = RegExp(r'(\d+)\s*(?:दिवसा|दिवस|days)').firstMatch(originalTranscript);
      if (daysMatch != null) {
        durationDays = int.tryParse(daysMatch.group(1)!);
      } else if (originalTranscript.contains('दोन दिवसा')) {
        durationDays = 2;
      } else if (originalTranscript.contains('तीन दिवसा')) {
        durationDays = 3;
      } else if (originalTranscript.contains('एक दिवसा') || originalTranscript.contains('एका दिवसा')) {
        durationDays = 1;
      }
    }

    String? villageVal = j['village'] as String?;
    if ((villageVal == null || villageVal.isEmpty) && villageHint != null && villageHint.isNotEmpty) {
      villageVal = villageHint;
    }

    final isWater = j['isWaterBorne'] as bool? ??
        (symList.contains('diarrhoea') || symList.contains('cholera') || symList.contains('gastro'));
    final riskPercent = j['waterRiskPercent'] is num ? (j['waterRiskPercent'] as num).toInt() : (isWater ? 60 : 25);
    final riskReason = j['waterRiskReason'] as String? ??
        (isWater ? 'दूषित पाण्यामुळे होणाऱ्या जलजन्य संसर्गाची लक्षणे आढळली.' : 'सध्या कमी धोका - लक्षणे सौम्य आहेत.');

    final ext = VoiceExtraction(
      transcript: originalTranscript,
      meta: {
        'modelVersion': model,
        'promptVersion': 'gemini-clinical-v1',
        'inputMode': 'voice',
        'provenance': 'gemini-ai',
      },
      patientName: makeField<String>(patientName),
      gender: makeField<String>(j['gender'] as String?),
      village: makeField<String>(villageVal),
      waterSource: makeField<String>(j['waterSource'] as String?),
      ageYears: makeField<int>(ageYears),
      durationDays: makeField<int>(durationDays),
      stoolsPerDay: makeField<int>(j['stoolsPerDay'] is num ? (j['stoolsPerDay'] as num).toInt() : null),
      vomitCount: makeField<int>(j['vomitCount'] is num ? (j['vomitCount'] as num).toInt() : null),
      symptoms: makeField<List<String>>(symList.isNotEmpty ? symList : null),
      fever: makeField<bool>(j['fever'] as bool? ?? symList.contains('fever')),
      bloodInStool: makeField<bool>(j['bloodInStool'] as bool? ?? symList.contains('blood_in_stool')),
      ableToDrink: makeField<bool>(j['ableToDrink'] as bool?),
      verySleepy: makeField<bool>(j['verySleepy'] as bool?),
      urinePassed: makeField<bool>(j['urinePassed'] as bool?),
      othersSickAtHome: makeField<bool>(j['othersSickAtHome'] as bool?),
      orsGiven: makeField<bool>(j['orsGiven'] as bool?),
      pregnancy: makeField<bool>(j['pregnancy'] as bool?),
      infant: makeField<bool>(j['infant'] as bool?),
      isWaterBorne: isWater,
      waterRiskPercent: riskPercent,
      waterRiskReason: riskReason,
    );

    return ext;
  }

  static VoiceExtraction _buildFallbackExtraction(String text, String? villageHint, bool mr) {
    final local = LocalExtractor.extract(text);
    // Overlay regex for marathi name, age, days if local missed
    final nameMatch = RegExp(r'(?:नाव|name\s*is)\s*[:=]?\s*([^\n,]+?)(?=\s+वय|\s+गाव|\s+दोन|\s+\d|$)').firstMatch(text);
    if (nameMatch != null && (local.patientName.value == null || local.patientName.value!.isEmpty)) {
      local.patientName.value = nameMatch.group(1)?.trim();
      local.patientName.status = 'ok';
    }

    final ageMatch = RegExp(r'(?:वय|age)\s*[:=]?\s*(\d+)').firstMatch(text);
    if (ageMatch != null && local.ageYears.value == null) {
      local.ageYears.value = int.tryParse(ageMatch.group(1)!);
      local.ageYears.status = 'ok';
    }

    final daysMatch = RegExp(r'(\d+)\s*(?:दिवसा|दिवस|days)').firstMatch(text);
    if (daysMatch != null && local.durationDays.value == null) {
      local.durationDays.value = int.tryParse(daysMatch.group(1)!);
      local.durationDays.status = 'ok';
    } else if (text.contains('दोन दिवसा') && local.durationDays.value == null) {
      local.durationDays.value = 2;
      local.durationDays.status = 'ok';
    }

    if (text.contains('पोट दुखी') || text.contains('पोटदुखी')) {
      final list = local.symptoms.value ?? [];
      if (!list.contains('abdominal_pain')) {
        list.add('abdominal_pain');
        local.symptoms.value = list;
      }
    }

    if ((local.village.value == null || local.village.value!.isEmpty) && villageHint != null && villageHint.isNotEmpty) {
      local.village.value = villageHint;
    }

    return local;
  }
}
