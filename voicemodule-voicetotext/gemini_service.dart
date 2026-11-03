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
    bool mr = false,
    String lang = 'as',
  }) async {
    final apiKey = await getApiKey();

    final String activeLang = (mr == true && lang == 'as') ? 'mr' : lang;
    String targetLangName;
    switch (activeLang) {
      case 'as': targetLangName = 'Assamese'; break;
      case 'bn': targetLangName = 'Bengali'; break;
      case 'hi': targetLangName = 'Hindi'; break;
      case 'mr': targetLangName = 'Marathi'; break;
      case 'mni': targetLangName = 'Manipuri'; break;
      case 'brx': targetLangName = 'Bodo'; break;
      case 'lus': targetLangName = 'Mizo'; break;
      case 'en':
      default: targetLangName = 'English'; break;
    }

    final systemInstruction = '''
You are an expert clinical epidemiology and triage system for rural Primary Health Centres (PHCs) and Sub-Centres across Northeast India (Assam, Meghalaya, Tripura, Arunachal Pradesh, Manipur, Nagaland, Mizoram, Sikkim).
Transcribe and extract structured clinical fields from this spoken transcript into a JSON object. The speaker may speak in Assamese, Bengali, Hindi, English, Marathi, or mixed Northeast regional dialects (e.g. Nagamese, Sylheti, Bodo).

RULES:
1. ONLY extract what was explicitly stated or clearly implied by the patient/ASHA worker. If not mentioned, set the field to null.
2. Normalise all number words to numeric digits:
   - Assamese/Bengali: "এক"=1, "দুই"=2, "তিনি"/"তিন"=3, "চাৰি"/"চার"=4, "পাঁচ"=5, "ছয়"=6, "সাত"=7, "আঠ"/"আট"=8, "ন"/"নয়"=9, "দহ"/"দশ"=10, "বিশ"=20, "পঁচিশ"=25, "ত্ৰিশ"/"তিরিশ"=30.
   - Devanagari/Hindi/Marathi: "एक"=1, "दोन"/"दो"=2, "तीन"=3, "चार"=4, "पाच"/"पाँच"=5, "सहा"/"छह"=6, "सात"=7, "आठ"=8, "नऊ"/"नौ"=9, "दहा"/"दस"=10.
3. "symptoms" must be a list containing ONLY applicable keys from this vocabulary:
   - "diarrhoea", "vomiting", "fever", "typhoid", "jaundice", "cholera", "gastro", "abdominal_pain", "weakness", "thirst", "sunken_eyes", "blood_in_stool".
   - Key multilingual mappings:
     - Assamese "পেটৰ বিষ" / Bengali "পেটে ব্যথা" / Marathi "पोटदुखी" / Hindi "पेट दर्द" -> "abdominal_pain"
     - Assamese "পাতলা শৌচ", "ডায়েৰিয়া", "পেট চলা" / Bengali "পাতলা পায়খানা", "ডায়রিয়া" / Marathi "जुलाब" / Hindi "दस्त" -> "diarrhoea"
     - Assamese/Bengali "বমি" / Marathi "उलटी" / Hindi "उल्टी" -> "vomiting"
     - Assamese "জ্বৰ" / Bengali "জ্বর" / Marathi "ताप" / Hindi "बुखार" -> "fever"
     - Assamese "শৌচত তেজ" / Bengali "মলে রক্ত" / Marathi "शौचात रक्त" / Hindi "शौच में खून" -> "blood_in_stool"
     - Assamese "জণ্ডিচ" / Bengali "জন্ডিস" / Marathi "कावीळ" / Hindi "पीलिया" -> "jaundice"
     - Assamese "কলেৰা", "পটকী" / Bengali "কলেরা" / Marathi "कॉलरा" / Hindi "हैजा" -> "cholera"
4. Evaluate water-borne outbreak risk:
   - "isWaterBorne": true if symptoms include diarrhoea, vomiting, cholera, jaundice, gastro, or typhoid.
   - "waterRiskPercent": integer between 10 and 95 based on severity (e.g. 80-95 for cholera/blood in stool/sunken eyes, 50-75 for fever+diarrhoea, 20-40 for mild abdominal pain).
   - "waterRiskReason": concise explanation in $targetLangName (patient / ASHA worker selected language).
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
      return _buildFallbackExtraction(transcript, villageHint, mr, activeLang);
    }

    return _buildVoiceExtractionFromJson(parsedJson, transcript, usedModel, villageHint, activeLang);
  }

  static VoiceExtraction _buildVoiceExtractionFromJson(
    Map<String, dynamic> j,
    String originalTranscript,
    String model,
    String? villageHint, [
    String activeLang = 'as',
  ]) {
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

    // Symptom vocabulary mapping (Supports Assamese, Bengali, Hindi, English, Marathi)
    final symptomMapping = {
      'abdominal_pain': 'abdominal_pain',
      'पोटदुखी': 'abdominal_pain',
      'पोट दुखी': 'abdominal_pain',
      'stomach pain': 'abdominal_pain',
      'পেটৰ বিষ': 'abdominal_pain',
      'পেটে ব্যথা': 'abdominal_pain',
      'পেটব্যথা': 'abdominal_pain',
      'पेट दर्द': 'abdominal_pain',
      'diarrhoea': 'diarrhoea',
      'diarrhea': 'diarrhoea',
      'जुलाब': 'diarrhoea',
      'पातळ शौच': 'diarrhoea',
      'পাতলা শৌচ': 'diarrhoea',
      'ডায়েৰিয়া': 'diarrhoea',
      'পাতলা পায়খানা': 'diarrhoea',
      'ডায়রিয়া': 'diarrhoea',
      'दस्त': 'diarrhoea',
      'vomiting': 'vomiting',
      'उलट्या': 'vomiting',
      'उलटी': 'vomiting',
      'उल्टी': 'vomiting',
      'বমি': 'vomiting',
      'ওকালি': 'vomiting',
      'fever': 'fever',
      'ताप': 'fever',
      'बुखार': 'fever',
      'জ্বৰ': 'fever',
      'জ্বর': 'fever',
      'typhoid': 'typhoid',
      'टायफॉइड': 'typhoid',
      'टायफॉईड': 'typhoid',
      'टाइफाइड': 'typhoid',
      'টাইফয়েড': 'typhoid',
      'টাইফয়েড': 'typhoid',
      'jaundice': 'jaundice',
      'कावीळ': 'jaundice',
      'पीलिया': 'jaundice',
      'জণ্ডিচ': 'jaundice',
      'জন্ডিস': 'jaundice',
      'cholera': 'cholera',
      'कॉलरा': 'cholera',
      'हैजा': 'cholera',
      'কলেৰা': 'cholera',
      'পটকী': 'cholera',
      'কলেরা': 'cholera',
      'gastro': 'gastro',
      'गॅस्ट्रो': 'gastro',
      'गैस्ट्रो': 'gastro',
      'গেষ্ট্ৰো': 'gastro',
      'গ্যাস্ট্রো': 'gastro',
      'weakness': 'weakness',
      'अशक्तपणा': 'weakness',
      'कमजोरी': 'weakness',
      'দুৰ্বলতা': 'weakness',
      'দুর্বলতা': 'weakness',
      'thirst': 'thirst',
      'तहान': 'thirst',
      'পিয়াহ': 'thirst',
      'তৃষ্ণা': 'thirst',
      'प्यास': 'thirst',
      'sunken_eyes': 'sunken_eyes',
      'डोळे खोल': 'sunken_eyes',
      'চকু সোমাই যোৱা': 'sunken_eyes',
      'চোখ বসে যাওয়া': 'sunken_eyes',
      'blood_in_stool': 'blood_in_stool',
      'शौचात रक्त': 'blood_in_stool',
      'रक्तयुक्त संडास': 'blood_in_stool',
      'শৌচত তেজ': 'blood_in_stool',
      'মলে রক্ত': 'blood_in_stool',
      'मल में खून': 'blood_in_stool',
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
      // Heuristic fallback for multilingual name (Assamese, Bengali, Hindi, English, Marathi)
      final nameMatch = RegExp(r'(?:नाव|name\s*is|নাম|নাম\s*হৈছে|নাম\s*হলো|नाम|नाम\s*है)\s*[:=]?\s*([^\n,]+?)(?=\s+वय|\s+गाव|\s+दोन|\s+\d|\s+বয়স|\s+গাঁও|\s+গ্রাম|\s+उम्र|\s+age|$)').firstMatch(originalTranscript);
      if (nameMatch != null) {
        patientName = nameMatch.group(1)?.trim();
      }
    }

    int? ageYears = j['ageYears'] is num ? (j['ageYears'] as num).toInt() : null;
    if (ageYears == null) {
      final ageMatch = RegExp(r'(?:वय|age|বয়স|বয়স|উম্ৰ|उम्र)\s*[:=]?\s*(\d+)').firstMatch(originalTranscript);
      if (ageMatch != null) {
        ageYears = int.tryParse(ageMatch.group(1)!);
      }
    }

    int? durationDays = j['durationDays'] is num ? (j['durationDays'] as num).toInt() : null;
    if (durationDays == null) {
      final daysMatch = RegExp(r'(\d+)\s*(?:दिवसा|दिवस|days|দিন|दिन)').firstMatch(originalTranscript);
      if (daysMatch != null) {
        durationDays = int.tryParse(daysMatch.group(1)!);
      } else if (originalTranscript.contains('दोन दिवसा') || originalTranscript.contains('দুদিন') || originalTranscript.contains('দুই দিন') || originalTranscript.contains('दो दिन')) {
        durationDays = 2;
      } else if (originalTranscript.contains('तीन दिवसा') || originalTranscript.contains('তিনি দিন') || originalTranscript.contains('তিন দিন') || originalTranscript.contains('तीन दिन')) {
        durationDays = 3;
      } else if (originalTranscript.contains('एक दिवसा') || originalTranscript.contains('একা दिवसा') || originalTranscript.contains('এদিন') || originalTranscript.contains('এক দিন') || originalTranscript.contains('एक दिन')) {
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
        (isWater ? (activeLang == 'as' ? 'দূষিত পানীৰ ফলত হোৱা জলজনিত সংক্ৰমণৰ লক্ষণ পোৱা গৈছে।' : activeLang == 'bn' ? 'দূষিত জলবাহিত সংক্রমণের স্পষ্ট লক্ষণ পাওয়া গেছে।' : activeLang == 'hi' ? 'दूषित पानी से होने वाले जलजन्य संक्रमण के लक्षण पाए गए।' : 'Water-borne clinical infection indicators detected.') : 'Low water contamination risk detected.');

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

  static VoiceExtraction _buildFallbackExtraction(String text, String? villageHint, bool mr, [String lang = 'as']) {
    final activeLang = (mr == true && lang == 'as') ? 'mr' : lang;
    final local = LocalExtractor.extract(text, lang: activeLang);
    // Overlay regex for name, age, days if local missed
    final nameMatch = RegExp(r'(?:नाव|name\s*is|নাম|নাম\s*হৈছে|नाम)\s*[:=]?\s*([^\n,]+?)(?=\s+वय|\s+गाव|\s+দोन|\s+\d|\s+বয়স|\s+গাঁও|\s+গ্রাম|\s+उम्र|$)').firstMatch(text);
    if (nameMatch != null && (local.patientName.value == null || local.patientName.value!.isEmpty)) {
      local.patientName.value = nameMatch.group(1)?.trim();
      local.patientName.status = 'ok';
    }

    final ageMatch = RegExp(r'(?:वय|age|বয়স|বয়স|উম্ৰ|उम्र)\s*[:=]?\s*(\d+)').firstMatch(text);
    if (ageMatch != null && local.ageYears.value == null) {
      local.ageYears.value = int.tryParse(ageMatch.group(1)!);
      local.ageYears.status = 'ok';
    }

    final daysMatch = RegExp(r'(\d+)\s*(?:दिवसा|दिवस|days|দিন|दिन)').firstMatch(text);
    if (daysMatch != null && local.durationDays.value == null) {
      local.durationDays.value = int.tryParse(daysMatch.group(1)!);
      local.durationDays.status = 'ok';
    } else if ((text.contains('दोन दिवसा') || text.contains('দুদিন') || text.contains('দুই দিন') || text.contains('दो दिन')) && local.durationDays.value == null) {
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
