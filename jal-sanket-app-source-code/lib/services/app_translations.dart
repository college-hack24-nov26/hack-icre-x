import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Tri-lingual Translation Engine for JalSanket
/// Supports: मराठी (Marathi), English, हिंदी (Hindi)
class AppTranslations {
  static String currentLanguage = 'मराठी';
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('मराठी');

  static const List<String> supportedLanguages = ['मराठी', 'English', 'हिंदी'];

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_language');
      if (saved != null && supportedLanguages.contains(saved)) {
        currentLanguage = saved;
        languageNotifier.value = saved;
      }
    } catch (_) {}
  }

  static Future<void> setLanguage(String lang) async {
    if (!supportedLanguages.contains(lang)) return;
    currentLanguage = lang;
    languageNotifier.value = lang;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang);
    } catch (_) {}
  }

  static String t(String key, [String? lang]) {
    final l = lang ?? currentLanguage;
    final map = _strings[key];
    if (map == null) return key;
    return map[l] ?? map['English'] ?? map['मराठी'] ?? key;
  }

  // Weather condition translator
  static String translateWeather(String condition, [String? lang]) {
    final l = lang ?? currentLanguage;
    final lower = condition.toLowerCase();

    if (lower.contains('clear') || lower.contains('sunny') || lower.contains('स्वच्छ') || lower.contains('साफ')) {
      return l == 'English' ? 'Clear & Dry Weather • No Rain' : (l == 'हिंदी' ? 'साफ व शुष्क मौसम • वर्षा नहीं' : 'स्वच्छ व कोरडे हवामान • पाऊस नाही');
    }
    if (lower.contains('partly') || lower.contains('अंशतः') || lower.contains('आंशिक')) {
      return l == 'English' ? 'Partly Cloudy' : (l == 'हिंदी' ? 'आंशिक रूप से बादल' : 'अंशतः ढगाळ');
    }
    if (lower.contains('cloud') || lower.contains('ढगाळ') || lower.contains('बादल') || lower.contains('overcast')) {
      return l == 'English' ? 'Cloudy Sky • High Humidity' : (l == 'हिंदी' ? 'बादल छाए रहेंगे • उच्च आर्द्रता' : 'ढगाळ हवामान • जास्त आर्द्रता');
    }
    if (lower.contains('thunder') || lower.contains('storm') || lower.contains('वादळ') || lower.contains('तूफान')) {
      return l == 'English' ? 'Thunderstorm Warning' : (l == 'हिंदी' ? 'गरज के साथ तूफान की चेतावनी' : 'वादळी पाऊस इशारा');
    }
    if (lower.contains('rain') || lower.contains('shower') || lower.contains('drizzle') || lower.contains('पाऊस') || lower.contains('वर्षा')) {
      return l == 'English' ? 'Rain / Showers Expected' : (l == 'हिंदी' ? 'वर्षा / बौछारें संभावित' : 'पाऊस / हलक्या सरी संभाव्य');
    }
    return condition;
  }

  static const Map<String, Map<String, String>> _strings = {
    // ── App General ──
    'appName': {
      'मराठी': 'जलसंकेत',
      'English': 'JalSanket',
      'हिंदी': 'जलसंकेत',
    },
    'offline': {
      'मराठी': '● ऑफलाईन',
      'English': '● Offline Ready',
      'हिंदी': '● ऑफलाइन',
    },
    'refresh': {
      'मराठी': 'रिफ्रेश',
      'English': 'Refresh',
      'हिंदी': 'रिफ्रेश',
    },
    'live': {
      'मराठी': 'थेट',
      'English': 'Live',
      'हिंदी': 'लाइव',
    },
    'updatedAt': {
      'मराठी': 'अद्ययावत:',
      'English': 'Updated:',
      'हिंदी': 'अपडेट:',
    },

    // ── Header & Greeting ──
    'greeting': {
      'मराठी': 'नमस्ते,',
      'English': 'Hello,',
      'हिंदी': 'नमस्ते,',
    },
    'phcSubtitle': {
      'मराठी': 'प्राथमिक आरोग्य केंद्र (PHC) • जलजन्य आजार उद्रेक नियंत्रण कक्ष',
      'English': 'Primary Health Centre (PHC) • Waterborne Outbreak Control Room',
      'हिंदी': 'प्राथमिक स्वास्थ्य केंद्र (PHC) • जलजन्य रोग प्रकोप नियंत्रण कक्ष',
    },
    'jjmImdLive': {
      'मराठी': 'JJM व IMD थेट माहिती',
      'English': 'JJM & IMD Live Portal Data',
      'हिंदी': 'JJM एवं IMD लाइव जानकारी',
    },
    'changeVillage': {
      'मराठी': 'गाव बदला',
      'English': 'Change Village',
      'हिंदी': 'गांव बदलें',
    },

    // ── Doctor Triage Banner ──
    'doctorTriageTitleDoc': {
      'मराठी': 'वैद्यकीय तपासणी व संदर्भित रुग्ण',
      'English': 'Doctor Triage & Forwarded Cases',
      'हिंदी': 'चिकित्सा जांच एवं संदर्भित मरीज',
    },
    'doctorTriageTitleStaff': {
      'मराठी': 'डॉक्टरांकडे पाठवलेले रुग्ण',
      'English': 'Forwarded Cases to Doctor',
      'हिंदी': 'डॉक्टर को भेजे गए मरीज',
    },
    'pendingReview': {
      'मराठी': 'प्रलंबित तपासण्या',
      'English': 'pending review',
      'हिंदी': 'समीक्षा लंबित',
    },
    'urgent': {
      'मराठी': 'तातडीचे',
      'English': 'urgent',
      'हिंदी': 'आपातकालीन',
    },
    'reviewBtn': {
      'मराठी': 'तपासा',
      'English': 'Review',
      'हिंदी': 'जांचें',
    },

    // ── Weather Card ──
    'weatherCardTitle': {
      'मराठी': 'हवामान व पर्जन्य अंदाज (IMD)',
      'English': 'Weather & Rain Forecast (IMD)',
      'हिंदी': 'मौसम एवं वर्षा पूर्वानुमान (IMD)',
    },
    'liveImdBadge': {
      'मराठी': 'थेट IMD',
      'English': 'Live IMD',
      'हिंदी': 'लाइव IMD',
    },
    'morning': {
      'मराठी': 'सकाळ',
      'English': 'Morning',
      'हिंदी': 'सुबह',
    },
    'afternoon': {
      'मराठी': 'दुपार',
      'English': 'Afternoon',
      'हिंदी': 'दोपहर',
    },
    'evening': {
      'मराठी': 'संध्याकाळ',
      'English': 'Evening',
      'हिंदी': 'शाम',
    },
    'night': {
      'मराठी': 'रात्र',
      'English': 'Night',
      'हिंदी': 'रात',
    },
    'rainChance': {
      'मराठी': 'पाऊस शक्यता',
      'English': 'Rain Chance',
      'हिंदी': 'वर्षा संभावना',
    },
    'humidity': {
      'मराठी': 'आर्द्रता',
      'English': 'Humidity',
      'हिंदी': 'आर्द्रता',
    },
    'past24hRain': {
      'मराठी': '२४ तास पाऊस',
      'English': '24h Rain',
      'हिंदी': '२४ घंटे वर्षा',
    },
    'wind': {
      'मराठी': 'वारा',
      'English': 'Wind',
      'हिंदी': 'हवा गति',
    },
    'forecast7Days': {
      'मराठी': '७-दिवसीय अंदाज व रडार नकाशा',
      'English': '7-Day Forecast & Radar Map',
      'हिंदी': '७-दिवसीय पूर्वानुमान एवं रडार नक्शा',
    },

    // ── Jal Jeevan Mission Card ──
    'jjmCardTitle': {
      'मराठी': 'Jal Jeevan Mission • गावाची माहिती',
      'English': 'Jal Jeevan Mission • Village Portal',
      'हिंदी': 'जल जीवन मिशन • गांव की जानकारी',
    },
    'jjmCardSubtitle': {
      'मराठी': 'अधिकृत जलस्त्रोत, योजना व प्रयोगशाळा तपासणी',
      'English': 'Official Water Sources, Schemes & Lab Tests',
      'हिंदी': 'आधिकारिक जल स्रोत, योजनाएं एवं लैब जांच',
    },
    'totalTestedSamples': {
      'मराठी': 'एकूण नमुने तपासले',
      'English': 'Total Samples Tested',
      'हिंदी': 'कुल नमूने जांचे गए',
    },
    'safeSamples': {
      'मराठी': 'सुरक्षित नमुने',
      'English': 'Safe Samples',
      'हिंदी': 'सुरक्षित नमूने',
    },
    'unsafeSamples': {
      'मराठी': 'असुरक्षित / दूषित',
      'English': 'Contaminated / Unsafe',
      'हिंदी': 'असुरक्षित / दूषित',
    },
    'remedialAction': {
      'मराठी': 'दुरुस्ती उपाययोजना',
      'English': 'Remedial Action',
      'हिंदी': 'उपचारात्मक कार्रवाई',
    },
    'population': {
      'मराठी': 'लोकसंख्या',
      'English': 'Population',
      'हिंदी': 'जनसंख्या',
    },
    'households': {
      'मराठी': 'कुटुंबे',
      'English': 'Households',
      'हिंदी': 'परिवार',
    },
    'waterSources': {
      'मराठी': 'पाण्याचे स्त्रोत',
      'English': 'Water Sources',
      'हिंदी': 'जल स्रोत',
    },
    'habitations': {
      'मराठी': 'वस्त्या',
      'English': 'Habitations',
      'हिंदी': 'बस्तियां',
    },
    'viewAllSources': {
      'मराठी': 'सर्व स्त्रोत पहा',
      'English': 'View All Sources',
      'हिंदी': 'सभी स्रोत देखें',
    },
    'jjmDashboard': {
      'मराठी': 'JJM डॅशबोर्ड',
      'English': 'JJM Dashboard',
      'हिंदी': 'JJM डैशबोर्ड',
    },

    // ── Outbreak Risk Index ──
    'riskCardTitle': {
      'मराठी': 'रोग उद्रेक धोका निर्देशांक',
      'English': 'Outbreak Risk Index',
      'हिंदी': 'रोग प्रकोप जोखिम सूचकांक',
    },
    'riskCardSubtitle': {
      'मराठी': 'JJM दूषित पाणी + IMD पर्जन्य + नोंदणीकृत रुग्णांवरून गणना',
      'English': 'Calculated from JJM Water + IMD Rain + Reported Cases',
      'हिंदी': 'JJM दूषित जल + IMD वर्षा + दर्ज मरीजों से गणना',
    },
    'lowRisk': {
      'मराठी': 'कमी धोका',
      'English': 'Low Risk',
      'हिंदी': 'कम जोखिम',
    },
    'moderateRisk': {
      'मराठी': 'मध्यम धोका',
      'English': 'Moderate Risk',
      'हिंदी': 'मध्यम जोखिम',
    },
    'highRisk': {
      'मराठी': 'उच्च धोका',
      'English': 'High Risk',
      'हिंदी': 'उच्च जोखिम',
    },
    'severeRisk': {
      'मराठी': 'अति-धोकादायक',
      'English': 'Severe Risk',
      'हिंदी': 'अति-गंभीर जोखिम',
    },
    'villageReportedCases': {
      'मराठी': 'गावातील नोंद रुग्ण',
      'English': 'Village Reported Cases',
      'हिंदी': 'गांव में दर्ज मरीज',
    },
    'contaminatedWaterSamples': {
      'मराठी': 'दूषित पाणी नमुने',
      'English': 'Unsafe Water Samples',
      'हिंदी': 'दूषित जल नमूने',
    },
    'forecastRainfall': {
      'मराठी': 'अंदाजित पाऊस',
      'English': 'Forecast Rainfall',
      'हिंदी': 'अनुमानित वर्षा',
    },

    // ── Quick Actions Grid ──
    'quickActionsTitle': {
      'मराठी': 'जलद कृती व सेवा',
      'English': 'Quick Actions & Services',
      'हिंदी': 'त्वरित कार्य एवं सेवाएं',
    },
    'qaNewCase': {
      'मराठी': 'नवीन रुग्ण नोंद',
      'English': 'New Patient Case',
      'हिंदी': 'नया मरीज दर्ज करें',
    },
    'qaWaterTest': {
      'मराठी': 'जल चाचणी नोंद',
      'English': 'Water Quality Test',
      'हिंदी': 'जल परीक्षण दर्ज करें',
    },
    'qaEarlySignals': {
      'मराठी': 'लक्षण उद्रेक सिग्नल',
      'English': 'Early Outbreak Signals',
      'हिंदी': 'लक्षण प्रकोप सिग्नल',
    },
    'qaVoiceReport': {
      'मराठी': 'व्हॉईस रिपोर्टिंग',
      'English': 'Voice Reporting',
      'हिंदी': 'वॉइस रिपोर्टिंग',
    },
    'qaMap': {
      'मराठी': 'नकाशा दृश्य',
      'English': 'GIS Map View',
      'हिंदी': 'मानचित्र दृश्य',
    },
    'qaWeeklyReport': {
      'मराठी': 'साप्ताहिक अहवाल',
      'English': 'Weekly Report',
      'हिंदी': 'साप्ताहिक रिपोर्ट',
    },
    'qaScanQr': {
      'मराठी': 'QR कोड स्कॅन',
      'English': 'Scan QR Code',
      'हिंदी': 'QR कोड स्कैन',
    },
    'qaAiInsights': {
      'मराठी': 'AI जल-आरोग्य विश्लेषण',
      'English': 'AI Health Insights',
      'हिंदी': 'AI जल-स्वास्थ्य विश्लेषण',
    },

    // ── Bottom Navigation ──
    'navHome': {
      'मराठी': 'मुख्यपृष्ठ',
      'English': 'Home',
      'हिंदी': 'होम',
    },
    'navMap': {
      'मराठी': 'नकाशा',
      'English': 'Map',
      'हिंदी': 'नक्शा',
    },
    'navVoice': {
      'मराठी': 'व्हॉईस रिपोर्ट',
      'English': 'Voice Report',
      'हिंदी': 'वॉइस रिपोर्ट',
    },
    'navIot': {
      'मराठी': 'IoT चाचणी',
      'English': 'IoT Test',
      'हिंदी': 'IoT टेस्ट',
    },
    'navTasks': {
      'मराठी': 'कार्ये',
      'English': 'Tasks',
      'हिंदी': 'कार्य',
    },

    // ── Village Selector Modal ──
    'modalSelectVillage': {
      'मराठी': 'गाव निवडा (Select Village)',
      'English': 'Select Village',
      'हिंदी': 'गांव चुनें (Select Village)',
    },
    'modalSelectVillageSub': {
      'मराठी': 'कोणतेही गाव निवडा • पाण्याचे स्त्रोत व हवामान आपोआप संकलित होईल',
      'English': 'Select any village • Water sources & weather load automatically',
      'हिंदी': 'कोई भी गांव चुनें • जल स्रोत एवं मौसम जानकारी स्वतः लोड होगी',
    },
    'searchVillageHint': {
      'मराठी': 'गाव, तालुका किंवा जिल्हा शोधा (उदा. Kagal, Karad)...',
      'English': 'Search village, taluka or district (e.g. Kagal, Karad)...',
      'हिंदी': 'गांव, तालुका या जिला खोजें (उदा. Kagal, Karad)...',
    },
    'selectEnteredVillage': {
      'मराठी': 'प्रविष्ट केलेले गाव निवडा:',
      'English': 'Select entered village:',
      'हिंदी': 'दर्ज किया गया गांव चुनें:',
    },
    'noVillageFound': {
      'मराठी': 'कोणतेही पूर्व-सूचीबद्ध गाव सापडले नाही.\nवरील बटण दाबून हे गाव थेट लागू करा.',
      'English': 'No preset village found.\nTap the button above to apply this village directly.',
      'हिंदी': 'कोई पूर्व-सूचीबद्ध गांव नहीं मिला।\nऊपर का बटन दबाकर यह गांव सीधे लागू करें।',
    },
    'gpsAutoDetect': {
      'मराठी': 'GPS द्वारे चालू स्थान शोधा',
      'English': 'Auto-Detect Current GPS Location',
      'हिंदी': 'GPS द्वारा वर्तमान स्थान खोजें',
    },
    'gpsAutoDetectSub': {
      'मराठी': 'तुमचे चालू गाव व तालुका आपोआप मॅप होईल',
      'English': 'Your current village & block mapped automatically',
      'हिंदी': 'आपका वर्तमान गांव व तालुका स्वतः मैप होगा',
    },
    'browseByDistrict': {
      'मराठी': 'जिल्हा व तालुक्यानुसार निवडा (Browse by District)',
      'English': 'Browse by District & Taluka',
      'हिंदी': 'जिले एवं तालुका अनुसार चुनें (Browse by District)',
    },
    'browseByDistrictSub': {
      'मराठी': 'महाराष्ट्रातील सर्व ३६ जिल्हे व ३५८ तालुके उपलब्ध',
      'English': 'All 36 districts and 358 talukas of Maharashtra available',
      'हिंदी': 'महाराष्ट्र के सभी ३६ जिले एवं ३५८ तालुके उपलब्ध',
    },
    'stepSelectDistrict': {
      'मराठी': '१. जिल्हा निवडा (Select District)',
      'English': '1. Select District',
      'हिंदी': '१. जिला चुनें (Select District)',
    },
    'stepSelectTaluka': {
      'मराठी': '२. तालुका निवडा (Select Taluka)',
      'English': '2. Select Taluka',
      'हिंदी': '२. तालुका चुनें (Select Taluka)',
    },
    'stepEnterVillage': {
      'मराठी': '३. गाव प्रविष्ट करा (Enter Village Name)',
      'English': '3. Enter Village Name',
      'हिंदी': '३. गांव का नाम दर्ज करें (Enter Village Name)',
    },
    'applyToDashboard': {
      'मराठी': 'हे गाव डॅशबोर्डवर लागू करा',
      'English': 'Apply to Dashboard',
      'हिंदी': 'यह गांव डैशबोर्ड पर लागू करें',
    },
    'quickPresets': {
      'मराठी': '⚡ जलद गाव पर्याय (Quick Village Presets)',
      'English': '⚡ Quick Village Presets',
      'हिंदी': '⚡ त्वरित गांव विकल्प (Quick Village Presets)',
    },
    'searchPanIndia': {
      'मराठी': 'संपूर्ण भारत JJM डेटाबेस शोधा (Search Pan-India)',
      'English': 'Search Pan-India JJM Database',
      'हिंदी': 'अखिल भारतीय JJM डेटाबेस खोजें (Search Pan-India)',
    },
    'panIndiaSub': {
      'मराठी': '३६ राज्ये, ७००+ जिल्हे व सर्व ग्रामपंचायती उपलब्ध',
      'English': '36 States/UTs, 700+ Districts & all Gram Panchayats',
      'हिंदी': '३६ राज्य, ७००+ जिले एवं सभी ग्राम पंचायतें उपलब्ध',
    },

    // ── Telemetry & Surveillance Section ──
    'telemetrySectionTitle': {
      'मराठी': 'IoT सेन्सर व आपत्कालीन निगराणी',
      'English': 'IoT Sensors & Emergency Monitoring',
      'हिंदी': 'IoT सेंसर एवं आपातकालीन निगरानी',
    },
    'liveNodeBadge': {
      'मराठी': 'थेट नोड',
      'English': 'Live Node',
      'हिंदी': 'लाइव नोड',
    },
    'surveillanceSectionTitle': {
      'मराठी': 'साथरोग पूर्वसूचना व जोखीम विश्लेषण',
      'English': 'Outbreak Warning & Risk Analysis',
      'हिंदी': 'रोग प्रकोप पूर्वसूचना एवं जोखिम विश्लेषण',
    },
    'surveillanceBadge': {
      'मराठी': 'निगराणी',
      'English': 'Surveillance',
      'हिंदी': 'निगरानी',
    },
    'alertActiveTitle': {
      'मराठी': '१ सतर्कता सक्रिय',
      'English': '1 Alert Active',
      'हिंदी': '१ चेतावनी सक्रिय',
    },
    'alertActiveSub': {
      'मराठी': 'धोक्याची चिन्हे असलेला १ परिसर निगराणीखाली',
      'English': '1 area under active surveillance with risk indicators',
      'हिंदी': 'जोखिम संकेतों वाला १ क्षेत्र निगरानी में',
    },
    'casesChartTitle': {
      'मराठी': 'नोंदणीकृत रुग्ण आलेख',
      'English': 'Reported Cases Graph',
      'हिंदी': 'पंजीकृत मरीज ग्राफ',
    },
    'totalRecordedCases': {
      'मराठी': 'एकूण नोंद',
      'English': 'Total Cases',
      'हिंदी': 'कुल मरीज',
    },
    'dailyAverage': {
      'मराठी': 'दैनिक सरासरी',
      'English': 'Daily Avg',
      'हिंदी': 'दैनिक औसत',
    },
    'perDay': {
      'मराठी': '/ दिवस',
      'English': '/ day',
      'हिंदी': '/ दिन',
    },
    'patients': {
      'मराठी': 'रुग्ण',
      'English': 'cases',
      'हिंदी': 'मरीज',
    },
    'safe': {
      'मराठी': 'सुरक्षित',
      'English': 'Safe',
      'हिंदी': 'सुरक्षित',
    },
    'outbreakAlert': {
      'मराठी': 'उद्रेक सतर्कता',
      'English': 'Outbreak Alert',
      'हिंदी': 'प्रकोप चेतावनी',
    },
    'monitored': {
      'मराठी': 'निगराणीत',
      'English': 'Monitored',
      'हिंदी': 'निगरानी में',
    },
    'riskCalcFromJjmImd': {
      'मराठी': 'JJM व IMD स्क्रॅप केलेल्या डेटावरून थेट गणना',
      'English': 'Calculated live from JJM & IMD scraped data',
      'हिंदी': 'JJM एवं IMD स्क्रैप किए गए डेटा से लाइव गणना',
    },
    'riskIndex': {
      'मराठी': 'जोखीम निर्देशांक',
      'English': 'Risk Index',
      'हिंदी': 'जोखिम सूचकांक',
    },
    'factorWaterLab': {
      'मराठी': '१. जल गुणवत्ता व लॅब अहवाल',
      'English': '1. Water Quality & Lab Reports',
      'हिंदी': '१. जल गुणवत्ता एवं लैब रिपोर्ट',
    },
    'factorWeatherRain': {
      'मराठी': '२. हवामान व पर्जन्य जोखीम',
      'English': '2. Weather & Rainfall Risk',
      'हिंदी': '२. मौसम एवं वर्षा जोखिम',
    },
    'factorOutbreakCases': {
      'मराठी': '३. रुग्ण उद्रेक व साथीचे संकेत',
      'English': '3. Outbreak & Disease Signals',
      'हिंदी': '३. मरीज प्रकोप एवं रोग संकेत',
    },
    'status': {
      'मराठी': 'स्थिती:',
      'English': 'Status:',
      'हिंदी': 'स्थिति:',
    },
    'points': {
      'मराठी': 'गुण',
      'English': 'pts',
      'हिंदी': 'अंक',
    },

    // ── OpenStreetMap & Water Sources Mapping ──
    'mapWaterSourcesCount': {
      'मराठी': 'पाण्याचे स्त्रोत नकाशावर',
      'English': 'Water Sources on Map',
      'हिंदी': 'जल स्रोत नक्शे पर',
    },
    'filterAll': {
      'मराठी': 'सर्व',
      'English': 'All',
      'हिंदी': 'सभी',
    },
    'filterTaps': {
      'मराठी': '🚰 नळ योजना',
      'English': '🚰 PWS Taps',
      'हिंदी': '🚰 नल योजना',
    },
    'filterBorewells': {
      'मराठी': '💧 बोअरवेल',
      'English': '💧 Borewells',
      'हिंदी': '💧 बोरवेल',
    },
    'filterWells': {
      'मराठी': '🏛️ विहिरी',
      'English': '🏛️ Dug Wells',
      'हिंदी': '🏛️ कुएं',
    },
    'filterAlerts': {
      'मराठी': '⚠️ सतर्कता',
      'English': '⚠️ Alerts',
      'हिंदी': '⚠️ अलर्ट',
    },
    'viewOnMap': {
      'मराठी': 'OpenStreetMap वर पहा',
      'English': 'View on OpenStreetMap',
      'हिंदी': 'OpenStreetMap पर देखें',
    },
    'sourceDetails': {
      'मराठी': 'जलस्त्रोत तपशील',
      'English': 'Water Source Details',
      'हिंदी': 'जल स्रोत विवरण',
    },
    'testWaterHere': {
      'मराठी': 'येथे पाणी चाचणी करा',
      'English': 'Test Water Here',
      'हिंदी': 'यहां जल परीक्षण करें',
    },
    'safeBis': {
      'मराठी': 'सुरक्षित (BIS मानकानुसार)',
      'English': 'Safe (BIS Compliant)',
      'हिंदी': 'सुरक्षित (BIS मानक अनुसार)',
    },
    'contaminatedAlert': {
      'मराठी': 'दूषित / दुरुस्ती आवश्यक',
      'English': 'Contaminated / Action Needed',
      'हिंदी': 'दूषित / सुधार आवश्यक',
    },
    'searchSourceHint': {
      'मराठी': 'गाव किंवा पाण्याचे स्त्रोत शोधा...',
      'English': 'Search village or water source...',
      'हिंदी': 'गांव या जल स्रोत खोजें...',
    },
  };
}
