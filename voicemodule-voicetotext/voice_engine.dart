import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- DATA MODELS ---

class VField<T> {
  T? value;
  double conf;
  String? evidence;
  String status; // 'ok' | 'missing' | 'invalid' | 'no_evidence'
  bool edited;

  VField({
    this.value,
    this.conf = 0.0,
    this.evidence,
    this.status = 'missing',
    this.edited = false,
  });

  Map<String, dynamic> toJson() => {
        'value': value,
        'conf': conf,
        'evidence': evidence,
        'status': status,
        'edited': edited,
      };

  factory VField.fromJson(dynamic j) {
    if (j == null || j is! Map) {
      return VField<T>(value: null, conf: 0, evidence: null, status: 'missing');
    }
    return VField<T>(
      value: j['value'] as T?,
      conf: (j['conf'] is num) ? (j['conf'] as num).toDouble() : 0.0,
      evidence: j['evidence'] as String?,
      status: j['status'] as String? ?? (j['value'] == null ? 'missing' : 'ok'),
      edited: j['edited'] == true,
    );
  }
}

class VoiceExtraction {
  String transcript;
  List<String> warnings;
  List<String> missingPrompts;
  Map<String, String> meta;

  VField<String> patientName;
  VField<String> gender;
  VField<String> village;
  VField<String> waterSource;
  VField<int> ageYears;
  VField<int> durationDays;
  VField<int> stoolsPerDay;
  VField<int> vomitCount;
  VField<List<String>> symptoms;
  VField<bool> fever;
  VField<bool> bloodInStool;
  VField<bool> ableToDrink;
  VField<bool> verySleepy;
  VField<bool> urinePassed;
  VField<bool> othersSickAtHome;
  VField<bool> orsGiven;
  VField<bool> pregnancy;
  VField<bool> infant;

  int? waterRiskPercent;
  bool? isWaterBorne;
  String? waterRiskReason;
  List<String> healthTips;

  VoiceExtraction({
    required this.transcript,
    List<String>? warnings,
    List<String>? missingPrompts,
    Map<String, String>? meta,
    VField<String>? patientName,
    VField<String>? gender,
    VField<String>? village,
    VField<String>? waterSource,
    VField<int>? ageYears,
    VField<int>? durationDays,
    VField<int>? stoolsPerDay,
    VField<int>? vomitCount,
    VField<List<String>>? symptoms,
    VField<bool>? fever,
    VField<bool>? bloodInStool,
    VField<bool>? ableToDrink,
    VField<bool>? verySleepy,
    VField<bool>? urinePassed,
    VField<bool>? othersSickAtHome,
    VField<bool>? orsGiven,
    VField<bool>? pregnancy,
    VField<bool>? infant,
    this.waterRiskPercent,
    this.isWaterBorne,
    this.waterRiskReason,
    List<String>? healthTips,
  })  : warnings = warnings ?? [],
        missingPrompts = missingPrompts ?? [],
        meta = meta ??
            {
              'modelVersion': 'local-rules',
              'promptVersion': 'local-1',
              'inputMode': 'typed',
              'provenance': 'simulated',
            },
        patientName = patientName ?? VField<String>(),
        gender = gender ?? VField<String>(),
        village = village ?? VField<String>(),
        waterSource = waterSource ?? VField<String>(),
        ageYears = ageYears ?? VField<int>(),
        durationDays = durationDays ?? VField<int>(),
        stoolsPerDay = stoolsPerDay ?? VField<int>(),
        vomitCount = vomitCount ?? VField<int>(),
        symptoms = symptoms ?? VField<List<String>>(),
        fever = fever ?? VField<bool>(),
        bloodInStool = bloodInStool ?? VField<bool>(),
        ableToDrink = ableToDrink ?? VField<bool>(),
        verySleepy = verySleepy ?? VField<bool>(),
        urinePassed = urinePassed ?? VField<bool>(),
        othersSickAtHome = othersSickAtHome ?? VField<bool>(),
        orsGiven = orsGiven ?? VField<bool>(),
        pregnancy = pregnancy ?? VField<bool>(),
        infant = infant ?? VField<bool>(),
        healthTips = healthTips ?? [];

  VoiceExtraction clone() {
    return VoiceExtraction(
      transcript: transcript,
      warnings: List.from(warnings),
      missingPrompts: List.from(missingPrompts),
      meta: Map.from(meta),
      patientName: VField(value: patientName.value, conf: patientName.conf, evidence: patientName.evidence, status: patientName.status, edited: patientName.edited),
      gender: VField(value: gender.value, conf: gender.conf, evidence: gender.evidence, status: gender.status, edited: gender.edited),
      village: VField(value: village.value, conf: village.conf, evidence: village.evidence, status: village.status, edited: village.edited),
      waterSource: VField(value: waterSource.value, conf: waterSource.conf, evidence: waterSource.evidence, status: waterSource.status, edited: waterSource.edited),
      ageYears: VField(value: ageYears.value, conf: ageYears.conf, evidence: ageYears.evidence, status: ageYears.status, edited: ageYears.edited),
      durationDays: VField(value: durationDays.value, conf: durationDays.conf, evidence: durationDays.evidence, status: durationDays.status, edited: durationDays.edited),
      stoolsPerDay: VField(value: stoolsPerDay.value, conf: stoolsPerDay.conf, evidence: stoolsPerDay.evidence, status: stoolsPerDay.status, edited: stoolsPerDay.edited),
      vomitCount: VField(value: vomitCount.value, conf: vomitCount.conf, evidence: vomitCount.evidence, status: vomitCount.status, edited: vomitCount.edited),
      symptoms: VField(value: symptoms.value != null ? List.from(symptoms.value!) : null, conf: symptoms.conf, evidence: symptoms.evidence, status: symptoms.status, edited: symptoms.edited),
      fever: VField(value: fever.value, conf: fever.conf, evidence: fever.evidence, status: fever.status, edited: fever.edited),
      bloodInStool: VField(value: bloodInStool.value, conf: bloodInStool.conf, evidence: bloodInStool.evidence, status: bloodInStool.status, edited: bloodInStool.edited),
      ableToDrink: VField(value: ableToDrink.value, conf: ableToDrink.conf, evidence: ableToDrink.evidence, status: ableToDrink.status, edited: ableToDrink.edited),
      verySleepy: VField(value: verySleepy.value, conf: verySleepy.conf, evidence: verySleepy.evidence, status: verySleepy.status, edited: verySleepy.edited),
      urinePassed: VField(value: urinePassed.value, conf: urinePassed.conf, evidence: urinePassed.evidence, status: urinePassed.status, edited: urinePassed.edited),
      othersSickAtHome: VField(value: othersSickAtHome.value, conf: othersSickAtHome.conf, evidence: othersSickAtHome.evidence, status: othersSickAtHome.status, edited: othersSickAtHome.edited),
      orsGiven: VField(value: orsGiven.value, conf: orsGiven.conf, evidence: orsGiven.evidence, status: orsGiven.status, edited: orsGiven.edited),
      pregnancy: VField(value: pregnancy.value, conf: pregnancy.conf, evidence: pregnancy.evidence, status: pregnancy.status, edited: pregnancy.edited),
      infant: VField(value: infant.value, conf: infant.conf, evidence: infant.evidence, status: infant.status, edited: infant.edited),
      waterRiskPercent: waterRiskPercent,
      isWaterBorne: isWaterBorne,
      waterRiskReason: waterRiskReason,
      healthTips: List.from(healthTips),
    );
  }
}

class WaterRiskAssessment {
  final int percentage;
  final bool isWaterBorne;
  final String level; // 'low' | 'moderate' | 'high'
  final String reason;
  final List<String> tips;
  final List<String> matchedFactors;

  WaterRiskAssessment({
    required this.percentage,
    required this.isWaterBorne,
    required this.level,
    required this.reason,
    required this.tips,
    required this.matchedFactors,
  });
}

class SavedCaseRow {
  final String id;
  final String savedAt;
  final String villageId;
  final String village;
  final String patientPseudoId;
  final String? patientName;
  final String transcript;
  final List<String> symptoms;
  final int? ageYears;
  final String? ageBand;
  final String? gender;
  final int? durationDays;
  final bool? fever;
  final int? stoolsPerDay;
  final int? vomitCount;
  final bool? bloodInStool;
  final bool? ableToDrink;
  final bool? verySleepy;
  final bool? urinePassed;
  final bool? othersSickAtHome;
  final bool? orsGiven;
  final bool? pregnancy;
  final bool? infant;
  final String? waterSourceText;
  final List<String> dangerSigns;
  final bool severityFlag;
  final int waterRiskPercent;
  final bool isWaterBorne;
  final String waterRiskReason;
  final List<String> healthTips;
  final Map<String, dynamic> edits;
  final String inputMode;
  final String provenance;
  final int durationSec;
  final bool isForwardedToDoctor;
  final String? forwardedAt;
  final String? doctorNotes;
  final String priority;
  final String doctorStatus;
  final String? doctorName;
  final String? reviewedAt;
  final String? doctorAssessment;
  final String? doctorPlan;

  String get name => (patientName != null && patientName!.trim().isNotEmpty) ? patientName! : 'अनामिक';
  int get age => ageYears ?? 0;

  SavedCaseRow({
    required this.id,
    required this.savedAt,
    required this.villageId,
    required this.village,
    required this.patientPseudoId,
    this.patientName,
    required this.transcript,
    required this.symptoms,
    this.ageYears,
    this.ageBand,
    this.gender,
    this.durationDays,
    this.fever,
    this.stoolsPerDay,
    this.vomitCount,
    this.bloodInStool,
    this.ableToDrink,
    this.verySleepy,
    this.urinePassed,
    this.othersSickAtHome,
    this.orsGiven,
    this.pregnancy,
    this.infant,
    this.waterSourceText,
    required this.dangerSigns,
    required this.severityFlag,
    required this.waterRiskPercent,
    required this.isWaterBorne,
    required this.waterRiskReason,
    required this.healthTips,
    required this.edits,
    this.inputMode = 'typed',
    this.provenance = 'live',
    this.durationSec = 0,
    this.isForwardedToDoctor = false,
    this.forwardedAt,
    this.doctorNotes,
    this.priority = 'normal',
    this.doctorStatus = 'none',
    this.doctorName,
    this.reviewedAt,
    this.doctorAssessment,
    this.doctorPlan,
  });

  SavedCaseRow copyWith({
    String? id,
    String? savedAt,
    String? villageId,
    String? village,
    String? patientPseudoId,
    String? patientName,
    String? transcript,
    List<String>? symptoms,
    int? ageYears,
    String? ageBand,
    String? gender,
    int? durationDays,
    bool? fever,
    int? stoolsPerDay,
    int? vomitCount,
    bool? bloodInStool,
    bool? ableToDrink,
    bool? verySleepy,
    bool? urinePassed,
    bool? othersSickAtHome,
    bool? orsGiven,
    bool? pregnancy,
    bool? infant,
    String? waterSourceText,
    List<String>? dangerSigns,
    bool? severityFlag,
    int? waterRiskPercent,
    bool? isWaterBorne,
    String? waterRiskReason,
    List<String>? healthTips,
    Map<String, dynamic>? edits,
    String? inputMode,
    String? provenance,
    int? durationSec,
    bool? isForwardedToDoctor,
    String? forwardedAt,
    String? doctorNotes,
    String? priority,
    String? doctorStatus,
    String? doctorName,
    String? reviewedAt,
    String? doctorAssessment,
    String? doctorPlan,
  }) {
    return SavedCaseRow(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      villageId: villageId ?? this.villageId,
      village: village ?? this.village,
      patientPseudoId: patientPseudoId ?? this.patientPseudoId,
      patientName: patientName ?? this.patientName,
      transcript: transcript ?? this.transcript,
      symptoms: symptoms ?? this.symptoms,
      ageYears: ageYears ?? this.ageYears,
      ageBand: ageBand ?? this.ageBand,
      gender: gender ?? this.gender,
      durationDays: durationDays ?? this.durationDays,
      fever: fever ?? this.fever,
      stoolsPerDay: stoolsPerDay ?? this.stoolsPerDay,
      vomitCount: vomitCount ?? this.vomitCount,
      bloodInStool: bloodInStool ?? this.bloodInStool,
      ableToDrink: ableToDrink ?? this.ableToDrink,
      verySleepy: verySleepy ?? this.verySleepy,
      urinePassed: urinePassed ?? this.urinePassed,
      othersSickAtHome: othersSickAtHome ?? this.othersSickAtHome,
      orsGiven: orsGiven ?? this.orsGiven,
      pregnancy: pregnancy ?? this.pregnancy,
      infant: infant ?? this.infant,
      waterSourceText: waterSourceText ?? this.waterSourceText,
      dangerSigns: dangerSigns ?? this.dangerSigns,
      severityFlag: severityFlag ?? this.severityFlag,
      waterRiskPercent: waterRiskPercent ?? this.waterRiskPercent,
      isWaterBorne: isWaterBorne ?? this.isWaterBorne,
      waterRiskReason: waterRiskReason ?? this.waterRiskReason,
      healthTips: healthTips ?? this.healthTips,
      edits: edits ?? this.edits,
      inputMode: inputMode ?? this.inputMode,
      provenance: provenance ?? this.provenance,
      durationSec: durationSec ?? this.durationSec,
      isForwardedToDoctor: isForwardedToDoctor ?? this.isForwardedToDoctor,
      forwardedAt: forwardedAt ?? this.forwardedAt,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      priority: priority ?? this.priority,
      doctorStatus: doctorStatus ?? this.doctorStatus,
      doctorName: doctorName ?? this.doctorName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      doctorAssessment: doctorAssessment ?? this.doctorAssessment,
      doctorPlan: doctorPlan ?? this.doctorPlan,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt,
        'villageId': villageId,
        'village': village,
        'patientPseudoId': patientPseudoId,
        'patientName': patientName,
        'transcript': transcript,
        'symptoms': symptoms,
        'ageYears': ageYears,
        'ageBand': ageBand,
        'gender': gender,
        'durationDays': durationDays,
        'fever': fever,
        'stoolsPerDay': stoolsPerDay,
        'vomitCount': vomitCount,
        'bloodInStool': bloodInStool,
        'ableToDrink': ableToDrink,
        'verySleepy': verySleepy,
        'urinePassed': urinePassed,
        'othersSickAtHome': othersSickAtHome,
        'orsGiven': orsGiven,
        'pregnancy': pregnancy,
        'infant': infant,
        'waterSourceText': waterSourceText,
        'dangerSigns': dangerSigns,
        'severityFlag': severityFlag,
        'waterRiskPercent': waterRiskPercent,
        'isWaterBorne': isWaterBorne,
        'waterRiskReason': waterRiskReason,
        'healthTips': healthTips,
        'edits': edits,
        'inputMode': inputMode,
        'provenance': provenance,
        'durationSec': durationSec,
        'isForwardedToDoctor': isForwardedToDoctor,
        'forwardedAt': forwardedAt,
        'doctorNotes': doctorNotes,
        'priority': priority,
        'doctorStatus': doctorStatus,
        'doctorName': doctorName,
        'reviewedAt': reviewedAt,
        'doctorAssessment': doctorAssessment,
        'doctorPlan': doctorPlan,
      };

  factory SavedCaseRow.fromJson(Map<String, dynamic> j) {
    return SavedCaseRow(
      id: j['id'] as String? ?? 'case-${DateTime.now().millisecondsSinceEpoch}',
      savedAt: j['savedAt'] as String? ?? DateTime.now().toIso8601String(),
      villageId: j['villageId'] as String? ?? '',
      village: j['village'] as String? ?? '',
      patientPseudoId: j['patientPseudoId'] as String? ?? 'P-UNKNOWN',
      patientName: j['patientName'] as String?,
      transcript: j['transcript'] as String? ?? '',
      symptoms: (j['symptoms'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ageYears: j['ageYears'] as int?,
      ageBand: j['ageBand'] as String?,
      gender: j['gender'] as String?,
      durationDays: j['durationDays'] as int?,
      fever: j['fever'] as bool?,
      stoolsPerDay: j['stoolsPerDay'] as int?,
      vomitCount: j['vomitCount'] as int?,
      bloodInStool: j['bloodInStool'] as bool?,
      ableToDrink: j['ableToDrink'] as bool?,
      verySleepy: j['verySleepy'] as bool?,
      urinePassed: j['urinePassed'] as bool?,
      othersSickAtHome: j['othersSickAtHome'] as bool?,
      orsGiven: j['orsGiven'] as bool?,
      pregnancy: j['pregnancy'] as bool?,
      infant: j['infant'] as bool?,
      waterSourceText: j['waterSourceText'] as String?,
      dangerSigns: (j['dangerSigns'] as List?)?.map((e) => e.toString()).toList() ?? [],
      severityFlag: j['severityFlag'] == true,
      waterRiskPercent: (j['waterRiskPercent'] as num?)?.toInt() ?? 0,
      isWaterBorne: j['isWaterBorne'] == true,
      waterRiskReason: j['waterRiskReason'] as String? ?? '',
      healthTips: (j['healthTips'] as List?)?.map((e) => e.toString()).toList() ?? [],
      edits: (j['edits'] is Map) ? Map<String, dynamic>.from(j['edits'] as Map) : {},
      inputMode: j['inputMode'] as String? ?? 'typed',
      provenance: j['provenance'] as String? ?? 'live',
      durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
      isForwardedToDoctor: j['isForwardedToDoctor'] == true,
      forwardedAt: j['forwardedAt'] as String?,
      doctorNotes: j['doctorNotes'] as String?,
      priority: j['priority'] as String? ?? 'normal',
      doctorStatus: j['doctorStatus'] as String? ?? (j['isForwardedToDoctor'] == true ? 'pending' : 'none'),
      doctorName: j['doctorName'] as String?,
      reviewedAt: j['reviewedAt'] as String?,
      doctorAssessment: j['doctorAssessment'] as String?,
      doctorPlan: j['doctorPlan'] as String?,
    );
  }
}

class DoctorConsideration {
  final String condition;
  final String evidenceQuote;
  final String confidence; // 'low' | 'medium' | 'high'

  DoctorConsideration({
    required this.condition,
    required this.evidenceQuote,
    required this.confidence,
  });
}

class DoctorGuideline {
  final String id;
  final String title;
  final int page;
  final String topic;
  final String text;

  DoctorGuideline({
    required this.id,
    required this.title,
    required this.page,
    required this.topic,
    required this.text,
  });
}

class DoctorResult {
  final String transcript;
  final String? diseaseLabel;
  final String subjective;
  final String objective;
  final List<String> askNext;
  final List<DoctorConsideration> consider;
  final List<String> redFlags;
  final List<DoctorGuideline> guidelines;
  final String? suggestedAssessment;
  final String? suggestedPlan;
  final Map<String, dynamic> context;

  DoctorResult({
    required this.transcript,
    this.diseaseLabel,
    required this.subjective,
    required this.objective,
    required this.askNext,
    required this.consider,
    required this.redFlags,
    required this.guidelines,
    this.suggestedAssessment,
    this.suggestedPlan,
    required this.context,
  });
}

class SignedConsultNote {
  final String sessionId;
  final String patientPseudoId;
  final String consentId;
  final String signedAt;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;

  SignedConsultNote({
    required this.sessionId,
    required this.patientPseudoId,
    required this.consentId,
    required this.signedAt,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'patientPseudoId': patientPseudoId,
        'consentId': consentId,
        'signedAt': signedAt,
        'subjective': subjective,
        'objective': objective,
        'assessment': assessment,
        'plan': plan,
      };

  factory SignedConsultNote.fromJson(Map<String, dynamic> j) {
    return SignedConsultNote(
      sessionId: j['sessionId'] as String? ?? '',
      patientPseudoId: j['patientPseudoId'] as String? ?? '',
      consentId: j['consentId'] as String? ?? '',
      signedAt: j['signedAt'] as String? ?? '',
      subjective: j['subjective'] as String? ?? '',
      objective: j['objective'] as String? ?? '',
      assessment: j['assessment'] as String? ?? '',
      plan: j['plan'] as String? ?? '',
    );
  }
}

// --- LABELS & CONSTANTS ---

const Map<String, Map<String, String>> symptomLabels = {
  'diarrhoea': {'mr': 'जुलाब', 'en': 'Diarrhoea'},
  'vomiting': {'mr': 'उलट्या', 'en': 'Vomiting'},
  'typhoid': {'mr': 'टायफॉइड', 'en': 'Typhoid'},
  'jaundice': {'mr': 'कावीळ', 'en': 'Jaundice'},
  'cholera': {'mr': 'कॉलरा / पटकी', 'en': 'Cholera / Patki'},
  'gastro': {'mr': 'गॅस्ट्रो', 'en': 'Gastroenteritis'},
  'abdominal_pain': {'mr': 'पोटदुखी', 'en': 'Abdominal pain'},
  'weakness': {'mr': 'अशक्तपणा', 'en': 'Weakness'},
  'thirst': {'mr': 'तहान', 'en': 'Excessive thirst'},
  'sunken_eyes': {'mr': 'डोळे खोल', 'en': 'Sunken eyes'},
  'blood_in_stool': {'mr': 'शौचात रक्त', 'en': 'Blood in stool'},
  'fever': {'mr': 'ताप', 'en': 'Fever'},
};

const Map<String, Map<String, String>> dangerLabels = {
  'sunken_eyes': {'mr': 'डोळे खोल गेले', 'en': 'Sunken eyes'},
  'unable_to_drink': {'mr': 'पाणी पिऊ शकत नाही', 'en': 'Unable to drink fluids'},
  'very_sleepy': {'mr': 'खूप सुस्त / झोपाळू', 'en': 'Lethargic / very sleepy'},
  'lethargy': {'mr': 'खूप सुस्त / झोपाळू', 'en': 'Lethargic / very sleepy'},
  'blood_in_stool': {'mr': 'शौचात रक्त', 'en': 'Blood in stool (Dysentery)'},
  'repeated_vomiting': {'mr': 'वारंवार उलट्या (≥ ३)', 'en': 'Repeated vomiting (≥ 3)'},
  'infant': {'mr': 'लहान बाळ (< १ वर्ष)', 'en': 'Infant (< 1 year)'},
  'very_young_child': {'mr': 'लहान बाळ (< १ वर्ष)', 'en': 'Infant (< 1 year)'},
  'pregnancy': {'mr': 'गर्भवती महिला', 'en': 'Pregnant patient'},
  'long_illness': {'mr': 'आजार जास्त दिवसांचा (≥ ७ दिवस)', 'en': 'Prolonged illness (≥ 7 days)'},
  'long_duration': {'mr': 'आजार जास्त दिवसांचा (≥ ७ दिवस)', 'en': 'Prolonged illness (≥ 7 days)'},
};

class SampleReport {
  final String id;
  final String titleMr;
  final String titleEn;
  final String tagMr;
  final String tagEn;
  final String severity; // 'mild' | 'danger' | 'warning' | 'cluster'
  final String transcript;

  const SampleReport({
    required this.id,
    required this.titleMr,
    required this.titleEn,
    required this.tagMr,
    required this.tagEn,
    required this.severity,
    required this.transcript,
  });
}

const List<SampleReport> sampleReports = [
  SampleReport(
    id: 'omkar',
    titleMr: 'रुग्ण नोंद (ओमकार कांबळे, वाघोली गाव)',
    titleEn: 'Patient Report (Omkar Kamble, Wagholi Village)',
    tagMr: 'पोटदुखी · २ दिवस · पाणी पिणे सामान्य',
    tagEn: 'Abdominal Pain · 2 Days · Able to Drink',
    severity: 'mild',
    transcript:
        'नाव ओमकार सागर कांबळे वय 22 दोन दिवसापासून पोट दुखी आहे पाणी पाच वेळा पितो दिवसातून',
  ),
  SampleReport(
    id: 'mild',
    titleMr: 'सौम्य केस (राकेश, पिंपरी गाव)',
    titleEn: 'Mild Case (Rakesh, Pimpri Village)',
    tagMr: 'जुलाब व उलट्या · ताप नाही',
    tagEn: 'Diarrhoea & Vomiting · No Fever',
    severity: 'mild',
    transcript:
        'रुग्णाचे नाव राकेश, वय बत्तीस, पिंपरी गाव. त्याला तीन दिवसांपासून जुलाब आणि उलट्या होत आहेत, ताप नाही.',
  ),
  SampleReport(
    id: 'danger',
    titleMr: 'धोक्याची चिन्हे (सुनीता, शिरोळ गाव)',
    titleEn: 'Danger Signs (Sunita, Shirol Village)',
    tagMr: 'शौचात रक्त · डोळे खोल · पाणी पिऊ शकत नाही',
    tagEn: 'Blood in Stool · Sunken Eyes · Unable to Drink',
    severity: 'danger',
    transcript:
        'रुग्णाचे नाव सुनीता, वय पाच, शिरोळ गाव. तिला दोन दिवसांपासून जुलाब आहे, शौचात रक्त आहे, डोळे खोल गेले आहेत, पाणी पिऊ शकत नाही.',
  ),
  SampleReport(
    id: 'cluster',
    titleMr: 'जलजन्य क्लस्टर व विहिरीचे पाणी (शंकर, वाघोली गाव)',
    titleEn: 'Well-Water Cluster (Shankar, Wagholi Village)',
    tagMr: 'कॉलरा लक्षणे · ८ वेळा जुलाब · घरात इतरही आजारी',
    tagEn: 'Suspected Cholera · 8 Stools/Day · Household Cluster',
    severity: 'cluster',
    transcript:
        'रुग्णाचे नाव शंकर, वय चाळीस, वाघोली गाव. त्याला दोन दिवसांपासून आठ वेळा जुलाब आणि चार वेळा उलट्या होत आहेत. खूप तहान लागली आहे आणि अशक्तपणा आहे. विहीर पाण्याचा स्रोत आहे, घरात इतर आजारी आहेत, ओआरएस दिले आहे.',
  ),
  SampleReport(
    id: 'jaundice',
    titleMr: 'कावीळ आणि ताप (प्रिया, खेड गाव, गर्भवती)',
    titleEn: 'Jaundice & Fever in Pregnancy (Priya, Khed Village)',
    tagMr: 'कावीळ · ताप · गर्भवती महिला',
    tagEn: 'Jaundice · Fever · Pregnant Patient',
    severity: 'danger',
    transcript:
        'रुग्णाचे नाव प्रिया, वय पंचवीस, खेड गाव. तिला पाच दिवसांपासून कावीळ आणि ताप आहे, पिवळी लघवी होत आहे आणि उलट्या होत आहेत. ती गर्भवती आहे, पाणी पिते.',
  ),
];

// --- LOCAL EXTRACTOR & DOMAIN LOGIC ---

class LocalExtractor {
  static const Map<String, int> numMap = {
    'शून्य': 0, 'एक': 1, 'दोन': 2, 'तीन': 3, 'चार': 4,
    'पाच': 5, 'सहा': 6, 'सात': 7, 'आठ': 8, 'नऊ': 9, 'दहा': 10,
    'बारा': 12, 'पंधरा': 15, 'वीस': 20, 'पंचवीस': 25, 'तीस': 30,
    'बत्तीस': 32, 'पस्तीस': 35, 'चाळीस': 40, 'पंचेचाळीस': 45,
    'पन्नास': 50, 'साठ': 60,
    'ek': 1, 'don': 2, 'teen': 3, 'char': 4, 'paach': 5, 'pach': 5,
    'saha': 6, 'saat': 7, 'aath': 8, 'nau': 9, 'daha': 10,
    'baara': 12, 'pandhra': 15, 'vees': 20, 'tees': 30, 'battees': 32,
    'chalis': 40, 'pannas': 50,
  };

  static const Map<String, String> devDigits = {
    '०': '0', '१': '1', '२': '2', '३': '3', '४': '4',
    '५': '5', '६': '6', '७': '7', '८': '8', '९': '9',
  };

  static String norm(String s) {
    var r = s;
    devDigits.forEach((k, v) {
      r = r.replaceAll(k, v);
    });
    return r;
  }

  static String clean(String s) {
    return s.replaceAll(RegExp(r'[,.।!?"]'), '').trim();
  }

  static int? toInt(String t) {
    final x = clean(norm(t)).toLowerCase();
    final p = int.tryParse(x);
    if (p != null) return p;
    return numMap[x];
  }

  static VField<T> f<T>(T? v, String? ev, [double c = 0.8]) {
    return VField<T>(
      value: v,
      conf: c,
      evidence: ev,
      status: v != null ? 'ok' : 'missing',
    );
  }

  static VoiceExtraction extract(String text) {
    final t = norm(text);
    final ext = VoiceExtraction(transcript: text);

    // Patient Name
    final nameRegex = RegExp(r'(?<![A-Za-z])(?:नाव|naav|name)\s+(\S+)', caseSensitive: false);
    final nameMatch = nameRegex.firstMatch(t);
    if (nameMatch != null) {
      ext.patientName = f<String>(clean(nameMatch.group(1)!), nameMatch.group(0), 0.85);
    } else {
      final leadingNameRegex = RegExp(r'^\s*([^,।0-9]+?)\s+(?:वय|vay|age)\b', caseSensitive: false);
      final lm = leadingNameRegex.firstMatch(t);
      if (lm != null) {
        var cand = clean(lm.group(1)!.replaceAll(RegExp(r'^(?:रुग्णाचे|रुग्ण|patient)\s+', caseSensitive: false), ''));
        if (cand.length >= 2 && cand.split(RegExp(r'\s+')).length <= 4) {
          ext.patientName = f<String>(cand, lm.group(0), 0.8);
        }
      }
    }

    // Age
    final ageRegex = RegExp(r'(?<![A-Za-z])(?:वय|vay|age)\s+(\S+)', caseSensitive: false);
    final am = ageRegex.firstMatch(t);
    if (am != null) {
      final a = toInt(am.group(1)!);
      if (a != null) ext.ageYears = f<int>(a, am.group(0), 0.85);
    }

    // Village
    final villageAfter = RegExp(r'(?:गाव|gaav|gaon|village)\s+([^\s,।]+)', caseSensitive: false).firstMatch(t);
    final villageBefore = RegExp(r'(\S+)\s+(?:गाव|gaav|gaon|village)', caseSensitive: false).firstMatch(t);
    const stopWords = {'वय', 'बारा', 'दोन', 'तीन', 'चार', 'पाच', 'सहा', 'सात', 'आठ', 'नऊ', 'दहा', 'वीस', 'तीस', 'चाळीस', 'पन्नास'};

    if (villageAfter != null && !RegExp(r'^(?:मध्ये|आहे|येथे|मधील)$', caseSensitive: false).hasMatch(clean(villageAfter.group(1)!))) {
      ext.village = f<String>(clean(villageAfter.group(1)!), villageAfter.group(0), 0.8);
    } else if (villageBefore != null && !stopWords.contains(clean(villageBefore.group(1)!).toLowerCase()) && toInt(villageBefore.group(1)!) == null) {
      ext.village = f<String>(clean(villageBefore.group(1)!), villageBefore.group(0), 0.75);
    }

    // Duration Days
    final durMatch = RegExp(r'(\S+)\s+(?:दिवस|दिवसांपासून|divas|divasaanpasun|days?)', caseSensitive: false).firstMatch(t);
    if (durMatch != null) {
      final d = toInt(durMatch.group(1)!);
      if (d != null) ext.durationDays = f<int>(d, durMatch.group(0), 0.85);
    }

    // Stools
    final stoolMatch = RegExp(r'(\S+)\s+वेळा\s+(?:शौच|जुलाब)', caseSensitive: false).firstMatch(t);
    if (stoolMatch != null) {
      final n = toInt(stoolMatch.group(1)!);
      if (n != null) ext.stoolsPerDay = f<int>(n, stoolMatch.group(0), 0.85);
    }

    // Vomit Count
    final vomitMatch = RegExp(r'(\S+)\s+वेळा\s+उलट', caseSensitive: false).firstMatch(t);
    if (vomitMatch != null) {
      final n = toInt(vomitMatch.group(1)!);
      if (n != null) ext.vomitCount = f<int>(n, vomitMatch.group(0), 0.85);
    }

    // Symptoms matching
    final symptoms = <String>{};
    final symEvidence = <String>[];

    void checkSym(String code, RegExp pattern) {
      final sm = pattern.firstMatch(t);
      if (sm != null) {
        symptoms.add(code);
        symEvidence.add(sm.group(0)!);
      }
    }

    checkSym('diarrhoea', RegExp(r'जुलाब|julaab|पातळ शौच|loose motion|diarrh', caseSensitive: false));
    checkSym('vomiting', RegExp(r'उलट्या|उलटी|ulti|ulatyaa|vomit', caseSensitive: false));
    checkSym('abdominal_pain', RegExp(r'पोटदुखी|पोट दुखत|potdukhi|stomach pain', caseSensitive: false));
    checkSym('weakness', RegExp(r'अशक्तपणा|अशक्त|ashakta|weakness', caseSensitive: false));
    checkSym('thirst', RegExp(r'तहान|tahan', caseSensitive: false));
    checkSym('sunken_eyes', RegExp(r'डोळे खोल|khol gelele|sunken', caseSensitive: false));
    checkSym('jaundice', RegExp(r'कावीळ|काविळ|kavil|jaundice|पिवळे डोळे|पिवळी लघवी', caseSensitive: false));
    checkSym('cholera', RegExp(r'कॉलरा|पटकी|cholera|patki', caseSensitive: false));
    checkSym('gastro', RegExp(r'गॅस्ट्रो|gastro|gastroenteritis', caseSensitive: false));
    checkSym('typhoid', RegExp(r'टायफॉइड|typhoid|विषमज्वर', caseSensitive: false));

    // Fever
    final noFever = RegExp(r'ताप नाही|taap nahi|no fever', caseSensitive: false).firstMatch(t);
    final fever = RegExp(r'ताप|taap|fever', caseSensitive: false).firstMatch(t);
    if (noFever != null) {
      ext.fever = f<bool>(false, noFever.group(0), 0.85);
    } else if (fever != null) {
      ext.fever = f<bool>(true, fever.group(0), 0.85);
      symptoms.add('fever');
      symptoms.add('typhoid');
      symEvidence.add(fever.group(0)!);
    }

    // Blood in stool
    final noBlood = RegExp(r'रक्त नाही|rakta nahi|no blood', caseSensitive: false).firstMatch(t);
    final blood = RegExp(r'शौचात रक्त|रक्त|rakta|blood', caseSensitive: false).firstMatch(t);
    if (noBlood != null) {
      ext.bloodInStool = f<bool>(false, noBlood.group(0), 0.85);
    } else if (blood != null) {
      ext.bloodInStool = f<bool>(true, blood.group(0), 0.85);
      symptoms.add('blood_in_stool');
      symEvidence.add(blood.group(0)!);
    }

    if (symptoms.isNotEmpty) {
      ext.symptoms = f<List<String>>(symptoms.toList(), symEvidence.join(', '), 0.85);
    }

    // Able to drink
    final cantDrink = RegExp(r'पाणी पिऊ शकत नाही|पाणी पित नाही|pani pit nahi|unable to drink|not able to drink', caseSensitive: false).firstMatch(t);
    final canDrink = RegExp(r'पाणी पितो|पाणी पिते|पाणी पिऊ शकतो|pani pito|drinking', caseSensitive: false).firstMatch(t);
    if (cantDrink != null) {
      ext.ableToDrink = f<bool>(false, cantDrink.group(0), 0.85);
    } else if (canDrink != null) {
      ext.ableToDrink = f<bool>(true, canDrink.group(0), 0.85);
    }

    // Very Sleepy
    final sleepy = RegExp(r'सुस्त|झोपाळू|susta|lethargic|very sleepy', caseSensitive: false).firstMatch(t);
    if (sleepy != null) ext.verySleepy = f<bool>(true, sleepy.group(0), 0.85);

    // ORS
    final ors = RegExp(r'(?<![A-Za-z])(?:ors|ओआरएस)(?![A-Za-z])\s*(दिले|नाही|nahi)?', caseSensitive: false).firstMatch(t);
    if (ors != null) {
      final negated = ors.group(1) != null && RegExp(r'नाही|nahi', caseSensitive: false).hasMatch(ors.group(1)!);
      ext.orsGiven = f<bool>(!negated, ors.group(0)!.trim(), 0.85);
    }

    // Others sick
    final others = RegExp(r'इतरही आजारी|इतर आजारी|others sick', caseSensitive: false).firstMatch(t);
    if (others != null) ext.othersSickAtHome = f<bool>(true, others.group(0), 0.85);

    // Water source
    final ws = RegExp(r'विहीर|कूपनलिका|हँडपंप|नदी|ओढा|नल|पाइपलाइन|well|borewell|river|tap', caseSensitive: false).firstMatch(t);
    if (ws != null) ext.waterSource = f<String>(ws.group(0), ws.group(0), 0.8);

    // Pregnancy
    final preg = RegExp(r'गर्भवती|pregnan', caseSensitive: false).firstMatch(t);
    if (preg != null) ext.pregnancy = f<bool>(true, preg.group(0), 0.85);

    // Infant
    final infant = RegExp(r'बाळ|infant|baby', caseSensitive: false).firstMatch(t);
    if (infant != null) ext.infant = f<bool>(true, infant.group(0), 0.85);

    // Gender
    if (RegExp(r'त्याला|tyala', caseSensitive: false).hasMatch(t)) {
      ext.gender = f<String>('male', 'त्याला', 0.65);
    } else if (RegExp(r'तिला|tila|ती', caseSensitive: false).hasMatch(t)) {
      ext.gender = f<String>('female', 'तिला', 0.65);
    }

    return ext;
  }
}

List<String> computeDangerSigns(VoiceExtraction x) {
  final d = <String>[];
  final sy = x.symptoms.value ?? [];
  if (sy.contains('sunken_eyes')) d.add('sunken_eyes');
  if (x.ableToDrink.value == false) d.add('unable_to_drink');
  if (x.verySleepy.value == true) d.add('very_sleepy');
  if (x.bloodInStool.value == true || sy.contains('blood_in_stool')) d.add('blood_in_stool');
  if ((x.vomitCount.value ?? 0) >= 3) d.add('repeated_vomiting');
  if (x.infant.value == true || (x.ageYears.value != null && x.ageYears.value! < 1)) d.add('infant');
  if (x.pregnancy.value == true) d.add('pregnancy');
  if ((x.durationDays.value ?? 0) >= 7) d.add('long_illness');
  return d;
}

WaterRiskAssessment computeWaterRisk(VoiceExtraction x, {bool mr = true}) {
  final sy = x.symptoms.value ?? [];
  int score = 0;
  final matched = <String>[];

  if (sy.contains('cholera')) {
    score += 45;
    matched.add(mr ? 'कॉलरा / पटकी' : 'Cholera');
  }
  if (sy.contains('jaundice')) {
    score += 40;
    matched.add(mr ? 'कावीळ' : 'Jaundice');
  }
  if (sy.contains('gastro')) {
    score += 35;
    matched.add(mr ? 'गॅस्ट्रो' : 'Gastroenteritis');
  }
  if (sy.contains('typhoid') || x.fever.value == true) {
    score += 25;
    matched.add(mr ? 'टायफॉइड / ताप' : 'Typhoid / Fever');
  }
  if (sy.contains('diarrhoea')) {
    score += 30;
    matched.add(mr ? 'जुलाब' : 'Diarrhoea');
  }
  if (sy.contains('vomiting')) {
    score += 20;
    matched.add(mr ? 'उलट्या' : 'Vomiting');
  }
  if (sy.contains('blood_in_stool') || x.bloodInStool.value == true) {
    score += 25;
    matched.add(mr ? 'शौचात रक्त' : 'Dysentery / Blood in stool');
  }
  if (sy.contains('abdominal_pain')) {
    score += 15;
    matched.add(mr ? 'पोटदुखी' : 'Abdominal pain');
  }
  if (x.othersSickAtHome.value == true) {
    score += 20;
    matched.add(mr ? 'घरात इतरही आजारी' : 'Household cluster');
  }

  final ws = (x.waterSource.value ?? '').toLowerCase();
  if (ws.contains('विहीर') ||
      ws.contains('well') ||
      ws.contains('ओढा') ||
      ws.contains('नदी') ||
      ws.contains('river') ||
      ws.contains('कूपनलिका') ||
      ws.contains('borewell') ||
      ws.contains('handpump') ||
      ws.contains('हँडपंप')) {
    score += 15;
    matched.add(mr ? 'असुरक्षित पाण्याचा स्रोत' : 'Unprotected water source');
  }

  final isWater = score >= 25 ||
      sy.any((s) => ['cholera', 'jaundice', 'gastro', 'diarrhoea', 'typhoid'].contains(s));

  int pct;
  if (isWater) {
    pct = score.clamp(35, 96);
  } else {
    pct = score.clamp(5, 25);
  }

  final level = pct >= 70 ? 'high' : pct >= 40 ? 'moderate' : 'low';

  String reason;
  if (sy.contains('jaundice')) {
    reason = mr
        ? 'सध्याची लक्षणे (${matched.join(', ')}) दूषित पाण्यामुळे होणाऱ्या विषाणूजन्य कावीळ (Hepatitis A / E) संसर्गाशी सुसंगत आहेत.'
        : 'Reported symptoms (${matched.join(', ')}) strongly correlate with water-borne Viral Hepatitis (Hep A/E).';
  } else if (sy.contains('cholera')) {
    reason = mr
        ? 'सध्याची लक्षणे (${matched.join(', ')}) तीव्र जलजन्य कॉलरा / पटकी संसर्गाशी सुसंगत असून तात्काळ जलसंजीवनी आवश्यक आहे.'
        : 'Reported symptoms (${matched.join(', ')}) indicate high risk of acute water-borne Cholera.';
  } else if (sy.contains('typhoid') && !sy.contains('diarrhoea')) {
    reason = mr
        ? 'सध्याची लक्षणे (${matched.join(', ')}) दूषित पाणी किंवा अन्नातून पसरणाऱ्या विषमज्वराशी (Typhoid / Enteric Fever) सुसंगत आहेत.'
        : 'Reported indicators (${matched.join(', ')}) correlate with water/food-borne Enteric Fever (Typhoid).';
  } else if (sy.contains('abdominal_pain') && !sy.contains('diarrhoea') && !sy.contains('vomiting')) {
    reason = isWater
        ? (mr
            ? 'पोटदुखी व पाण्याचा स्रोत (${matched.join(', ')}) लक्षात घेता दूषित पाण्यामुळे होणारा जंत संसर्ग किंवा गॅस्ट्रायटिसची शक्यता आहे.'
            : 'Abdominal pain with ${matched.join(', ')} suggests possible water-borne protozoal/worm infection or gastritis.')
        : (mr
            ? 'केवळ पोटदुखी हे लक्षण असून तीव्र जलजन्य अतिसाराची चिन्हे नाहीत; तरीही उकळलेले पाणी व हलका आहार घ्यावा.'
            : 'Isolated abdominal pain without acute diarrhoeal signs; advise boiled water and light diet.');
  } else if (isWater) {
    reason = mr
        ? 'सध्याची लक्षणे (${matched.join(', ')}) दूषित पाणी किंवा अस्वच्छतेमुळे उद्भवणाऱ्या जलजन्य आजाराशी (Water-borne Illness) सुसंगत आहेत.'
        : 'Reported clinical indicators (${matched.join(', ')}) strongly correlate with a water-borne infection.';
  } else {
    reason = mr
        ? 'सध्याची लक्षणे थेट दूषित पाण्यामुळे उद्भवलेली वाटत नाहीत. तरीही स्वच्छता व योग्य काळजी आवश्यक आहे.'
        : 'Symptoms do not directly indicate a water-borne cause. Routine hydration and hygiene are advised.';
  }

  List<String> tips;
  if (sy.contains('jaundice')) {
    tips = mr
        ? [
            'पिण्याचे पाणी किमान २० मिनिटे उकळून थंड करूनच प्या.',
            'तेलकट, तळलेले व मसालेदार पदार्थ पूर्णपणे टाळा; मऊ व सात्त्विक आहार घ्या.',
            'रुग्णाला पूर्ण विश्रांती द्या आणि डॉक्टरांच्या सल्ल्याशिवाय कोणतीही औषधे घेऊ नका.',
            'प्राथमिक आरोग्य केंद्रात (PHC) रक्त तपासणी (Bilirubin / LFT) करून घ्या.',
          ]
        : [
            'Drink only water that has been boiled vigorously for 20 minutes.',
            'Strictly avoid oily, fried, and spicy foods; take a soft carbohydrate-rich diet.',
            'Ensure complete rest and avoid unprescribed medications.',
            'Visit the PHC for Liver Function Tests (Bilirubin / LFT).',
          ];
  } else if (isWater) {
    tips = mr
        ? [
            'पिण्याचे पाणी किमान २० मिनिटे उकळून किंवा मेडिक्लोर / क्लोरिन गोळ्या टाकूनच प्या.',
            'डिहायड्रेशन रोखण्यासाठी रुग्णाला वारंवार ओआरएस (ORS) पाणी, ताक किंवा लिंबू पाणी द्या.',
            'उघड्यावरील, शिळे अन्न किंवा अस्वच्छ बर्फ खाणे टाळा.',
            'जेवणापूर्वी व शौचाहून आल्यावर हात साबणाने स्वच्छ धुवा.',
            if (pct >= 70) 'धोक्याची चिन्हे आढळल्यास त्वरित जवळच्या प्राथमिक आरोग्य केंद्रात (PHC) दाखवा.',
          ]
        : [
            'Boil drinking water vigorously for 20 minutes or treat with chlorine drops.',
            'Administer low-osmolarity ORS solution after every loose stool to prevent dehydration.',
            'Avoid open, unhygienic, or stale food and untreated surface water.',
            'Wash hands thoroughly with soap before meals and after defecation.',
            if (pct >= 70) 'Seek immediate medical evaluation at the nearest Primary Health Centre (PHC).',
          ];
  } else {
    tips = mr
        ? [
            'भरपूर स्वच्छ पाणी प्या आणि पुरेशी विश्रांती घ्या.',
            'घरगुती ताजा व हलका आहार घ्या (उदा. मऊ भात, खिचडी, फळे).',
            'हात व वैयक्तिक स्वच्छता राखा; जेवणापूर्वी हात स्वच्छ धुवा.',
            '२ दिवसांत आराम न वाटल्यास डॉक्टरांचा किंवा आशा सेविकेचा सल्ला घ्या.',
          ]
        : [
            'Drink plenty of clean fluids and ensure adequate rest.',
            'Eat light, fresh, nutritious home-cooked meals.',
            'Maintain personal hygiene and wash hands regularly.',
            'Consult a doctor or ASHA health worker if symptoms persist over 2 days.',
          ];
  }

  return WaterRiskAssessment(
    percentage: pct,
    isWaterBorne: isWater,
    level: level,
    reason: reason,
    tips: tips,
    matchedFactors: matched,
  );
}

DoctorResult buildSimulatedDoctorConsult(String text, {bool mr = true}) {
  final t = text.toLowerCase();
  bool has(Pattern p) => p.allMatches(t).isNotEmpty;

  final extracted = LocalExtractor.extract(text);
  final age = extracted.ageYears.value;
  final duration = extracted.durationDays.value;
  final village = extracted.village.value ?? (mr ? 'शिरोळ / पिंपरी' : 'Shirol / Pimpri');

  final flags = <String>[];
  if (has(RegExp(r'डोळे खोल|sunken'))) flags.add('sunken_eyes');
  if (has(RegExp(r'पाणी पिऊ शकत नाही|पाणी पित नाही|unable to drink'))) flags.add('unable_to_drink');
  if (has(RegExp(r'सुस्त|झोपाळू|lethargic'))) flags.add('lethargy');
  if (!has(RegExp(r'रक्त नाही|no blood')) && has(RegExp(r'शौचात रक्त|रक्त|आमांश|blood|dysentery'))) flags.add('blood_in_stool');
  if (has(RegExp(r'गर्भवती|pregnan'))) flags.add('pregnancy');
  if (has(RegExp(r'चार वेळा उलट|पाच वेळा उलट|वारंवार उलट्या|तीन वेळा उलट'))) flags.add('repeated_vomiting');
  if ((age != null && age < 1) || has(RegExp(r'बाळ|infant|baby'))) flags.add('very_young_child');
  if (duration != null && duration >= 7) flags.add('long_duration');

  final snippet = text.length > 90 ? '${text.substring(0, 90)}…' : text;

  final hasDiarrhoea = has(RegExp(r'जुलाब|पातळ शौच|loose motion|diarrh|गॅस्ट्रो|gastro|अतिसार'));
  final hasCholera = has(RegExp(r'कॉलरा|पटकी|cholera|patki|आठ वेळा जुलाब|भाताच्या पेज'));
  final hasBloodStool = !has(RegExp(r'रक्त नाही|no blood')) && has(RegExp(r'शौचात रक्त|रक्त पड|आमांश|आव पड|dysentery|blood in stool'));
  final hasJaundice = has(RegExp(r'कावीळ|काविळ|पिवळे डोळे|पिवळी लघवी|jaundice|hepatitis|यकृत'));
  final hasFever = !has(RegExp(r'ताप नाही|no fever|taap nahi')) && has(RegExp(r'ताप|थंडी वाजून|टायफॉइड|विषमज्वर|डेंग्यू|मलेरिया|fever|typhoid|malaria|dengue'));
  final hasAbdominalPain = has(RegExp(r'पोटदुखी|पोट दुख|पोटात दुख|पोटात कळ|पोटात गोळा|अॅसिडिटी|जंत|potdukhi|stomach pain|abdominal pain|gastritis'));
  final hasVomiting = has(RegExp(r'उलट्या|उलटी|मळमळ|ulti|vomit|nausea'));

  String diseaseLabel = '';
  final considerations = <DoctorConsideration>[];
  final askNext = <String>[];
  final guidelines = <DoctorGuideline>[];
  String suggestedAssessment = '';
  String suggestedPlan = '';

  if (hasJaundice) {
    diseaseLabel = mr ? 'कावीळ / विषाणूजन्य यकृत संसर्ग (Jaundice / Viral Hepatitis)' : 'Suspected Viral Hepatitis / Jaundice';
    considerations.add(DoctorConsideration(
      condition: mr ? 'जलजन्य विषाणूजन्य कावीळ — Hepatitis A / E' : 'Suspected Water-Borne Viral Hepatitis (Hepatitis A / E)',
      evidenceQuote: snippet,
      confidence: 'high',
    ));
    askNext.addAll(mr
        ? [
            'डोळे, नखे आणि लघवी किती दिवसांपासून पिवळी दिसत आहे? (Duration of yellow eyes & dark urine)',
            'पोटाच्या उजव्या वरच्या बाजूला दुखणे, मळमळ किंवा भूक मंदावणे आहे का? (RUQ pain, anorexia or nausea)',
            'शौचाचा रंग पांढरट/मातीसारखा आहे का आणि अंगाला खाज सुटते का? (Clay-colored stools or itching)',
            'रुग्ण गर्भवती आहे का? (गर्भवती महिलांमध्ये Hepatitis E अत्यंत धोकादायक असतो)',
          ]
        : [
            'How many days have scleral icterus and dark urine been present?',
            'Is there right upper quadrant pain, loss of appetite, or nausea?',
            'Are stools pale/clay-colored or is there generalized itching?',
            'Is the patient pregnant? (High fulminant risk in pregnancy)',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-hep-1',
      title: mr ? 'IDSP जलजन्य कावीळ प्रोटोकॉल' : 'IDSP Water-Borne Hepatitis Surveillance',
      page: 28,
      topic: 'jaundice',
      text: mr ? 'कावीळ रुग्ण आढळल्यास तात्काळ LFT रक्त तपासणी करा व विहिरीचे क्लोरिनेशन करा.' : 'Perform baseline Liver Function Tests (LFT) and chlorinate drinking source.',
    ));
    suggestedAssessment = mr ? 'संशित जलजन्य विषाणूजन्य कावीळ — Hepatitis A/E' : 'Suspected Acute Water-Borne Viral Hepatitis (Hep A/E)';
    suggestedPlan = mr ? '१. LFT रक्त तपासणी.\n२. तेलकट व मसालेदार आहार पूर्ण बंद; उकळलेले पाणी देणे.\n३. पूर्ण विश्रांती.' : '1. Order LFT.\n2. Fat-free bland diet & boiled water.\n3. Complete bed rest.';
  } else if (hasAbdominalPain && !hasDiarrhoea && !hasCholera && !hasBloodStool) {
    diseaseLabel = mr ? 'पोटदुखी व पचनसंस्था तक्रार (Acute Abdominal Pain)' : 'Acute Abdominal Pain / Enteric Evaluation';
    considerations.add(DoctorConsideration(
      condition: mr ? 'तीव्र गॅस्ट्रायटिस / जलजन्य जंत संसर्ग' : 'Acute Gastritis / Water-Borne Helminthiasis',
      evidenceQuote: snippet,
      confidence: 'high',
    ));
    askNext.addAll(mr
        ? [
            'पोटात नेमके कुठे दुखते — नाभीभोवती, उजव्या खालच्या बाजूला की वरच्या भागात?',
            'जेवणापूर्वी किंवा जेवणानंतर पोटदुखी वाढते का? सोबत मळमळ होते का?',
            'शौचास साफ होते का? बद्धकोष्ठता किंवा शौचात जंत दिसले का?',
            'पिण्याचे पाणी कोणत्या स्रोताचे आहे आणि पाणी उकळून पितात का?',
          ]
        : [
            'Where exactly is the abdominal pain located?',
            'Does the pain worsen before or after meals, and is there nausea?',
            'Are bowel movements regular, or is there constipation / visible worms?',
            'What is the household drinking water source and is it boiled?',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-abd-1',
      title: mr ? 'PHC तीव्र पोटदुखी शारीरिक तपासणी प्रोटोकॉल' : 'PHC Acute Abdominal Pain Clinical Protocol',
      page: 16,
      topic: 'abdominal_pain',
      text: mr ? 'पोटाची प्रत्यक्ष तपासणी करून कडकपणा (guarding) तपासा; वेदनाशामक न देता कारणावर उपचार करा.' : 'Palpate abdomen for tenderness/guarding before prescribing analgesics.',
    ));
    suggestedAssessment = mr ? 'तीव्र पोटदुखी — गॅस्ट्रायटिस / जलजन्य जंत संसर्ग संशय' : 'Acute Abdominal Pain — ?Gastritis / ?Helminthiasis';
    suggestedPlan = mr ? '१. पोटाची प्रत्यक्ष तपासणी व शौच तपासणी.\n२. हलका पचायला सोपा आहार व Albendazole जंतनाशक.\n३. पाणी २० मिनिटे उकळून पिणे.' : '1. Abdominal examination.\n2. Bland diet & deworming as indicated.\n3. Boiled drinking water.';
  } else if (hasFever && !hasDiarrhoea && !hasCholera && !hasBloodStool) {
    diseaseLabel = mr ? 'तीव्र ताप / विषमज्वर संशय (Acute Febrile Illness / Typhoid)' : 'Acute Febrile Illness / Enteric Fever';
    considerations.add(DoctorConsideration(
      condition: mr ? 'जलजन्य विषमज्वर / टायफॉइड ताप' : 'Suspected Water-Borne Enteric Fever (Typhoid)',
      evidenceQuote: snippet,
      confidence: 'high',
    ));
    askNext.addAll(mr
        ? [
            'ताप किती दिवसांपासून आहे आणि संध्याकाळी जास्त चढतो का?',
            'तापासोबत थंडी वाजून येणे, तीव्र डोकेदुखी किंवा अंगदुखी आहे का?',
            'पोटात दुखणे, भूक न लागणे किंवा बद्धकोष्ठता आहे का?',
            'पिण्याच्या पाण्याचा स्रोत कोणता आहे? अलीकडे न उकळलेले पाणी प्यायले का?',
          ]
        : [
            'How many days has the fever been present, and is there step-ladder rise?',
            'Are there chills/rigors, headache, or myalgia?',
            'Is there abdominal discomfort or anorexia?',
            'What is the drinking water source?',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-fev-1',
      title: mr ? 'NRHM ताप व विषमज्वर (Typhoid) प्रोटोकॉल' : 'NRHM Febrile Illness & Typhoid Protocol',
      page: 19,
      topic: 'fever',
      text: mr ? '३ दिवसांपेक्षा जास्त ताप असल्यास CBC आणि Typhidot IgM तपासणी करा.' : 'Order CBC, MP/RDT, and Typhidot IgM for fever >= 3 days.',
    ));
    suggestedAssessment = mr ? 'तीव्र ताप — जलजन्य विषमज्वर (Typhoid) / विषाणूजन्य ताप संशय' : 'Acute Febrile Illness — ?Enteric Fever (Typhoid)';
    suggestedPlan = mr ? '१. CBC व Typhidot तपासणी.\n२. पॅरासिटामॉल व कोमट पाण्याच्या घड्या.\n३. भरपूर उकळलेले पाणी, ORS व विश्रांती.' : '1. Order CBC and Typhidot.\n2. Weight-based Paracetamol & tepid sponging.\n3. Boiled fluids, ORS, and rest.';
  } else if (hasBloodStool) {
    diseaseLabel = mr ? 'तीव्र आमांश / शौचात रक्त (Acute Dysentery)' : 'Acute Dysentery (Blood in Stool)';
    considerations.add(DoctorConsideration(
      condition: mr ? 'तीव्र जिवाणूजन्य आमांश (Shigellosis / Dysentery)' : 'Acute Bacillary Dysentery (Shigellosis)',
      evidenceQuote: snippet,
      confidence: 'high',
    ));
    askNext.addAll(mr
        ? [
            'शौचात रक्त किती वेळा पडले आणि चिकट आव आहे का?',
            'शौचास जाताना पोटात तीव्र मुरडा किंवा कळ येते का?',
            'रुग्ण स्वतःहून पाणी व ORS पिऊ शकतो का आणि लघवी झाली आहे का?',
          ]
        : [
            'How many bloody or mucoid stools have occurred?',
            'Is there severe abdominal cramping during defecation?',
            'Is the patient able to drink ORS and passing urine?',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-dys-1',
      title: mr ? 'NRHM आमांश (Dysentery) संदर्भ प्रोटोकॉल' : 'NRHM Acute Dysentery Referral Protocol',
      page: 11,
      topic: 'dysentery',
      text: mr ? 'शौचात रक्त हे अनिवार्य धोक्याचे चिन्ह आहे; त्वरित ORS व PHC वैद्यकीय देखरेखीखाली उपचार करा.' : 'Blood in stool is a mandatory danger sign requiring immediate ORS & medical review.',
    ));
    suggestedAssessment = mr ? 'तीव्र आमांश / शौचात रक्त (Acute Dysentery — धोक्याचे चिन्ह)' : 'Acute Dysentery with Blood in Stool (Danger Sign Present)';
    suggestedPlan = mr ? '१. त्वरित ORS जलसंजीवनी.\n२. PHC डॉक्टरांमार्फत आमांश प्रतिजैविक उपचार व १४ दिवस झिंक.\n३. पाणी स्रोत निर्जंतुकीकरण.' : '1. Immediate ORS rehydration.\n2. Antibiotic therapy per PHC protocol + 14-day Zinc.\n3. Disinfect water source.';
  } else if (hasCholera) {
    diseaseLabel = mr ? 'संशित कॉलरा / पटकी उद्रेक (Suspected Cholera)' : 'Suspected Cholera Outbreak Cluster';
    considerations.add(DoctorConsideration(
      condition: mr ? 'संशित तीव्र कॉलरा / पटकी संसर्ग' : 'Suspected Acute Cholera (Profuse Rice-Water Stools)',
      evidenceQuote: snippet,
      confidence: 'high',
    ));
    askNext.addAll(mr
        ? [
            'शौच भाताच्या पेजसारखे पांढरट व पाण्यासारखे होत आहे का?',
            'वारंवार उलट्या होत आहेत का आणि डोळे खोल गेले आहेत का?',
            'गावात किंवा वाडीत इतर किती लोकांना जुलाब-उलट्यांचा त्रास आहे?',
          ]
        : [
            'Are stools painless and rice-water in appearance?',
            'Is there repeated vomiting or sunken eyes?',
            'How many other village members have similar symptoms?',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-cho-1',
      title: mr ? 'NRHM तीव्र डिहायड्रेशन आपत्कालीन प्रोटोकॉल' : 'NRHM Cholera & Severe Dehydration Resuscitation',
      page: 18,
      topic: 'cholera',
      text: mr ? 'तीव्र जलशुष्कतेची चिन्हे असल्यास त्वरित IV रिंगर लॅक्टेट (100 ml/kg) सुरू करा व ORS द्या.' : 'Start rapid IV Ringer Lactate (100 ml/kg) for severe dehydration + continuous ORS.',
    ));
    suggestedAssessment = mr ? 'संशित कॉलरा / तीव्र जलजन्य अतिसार व क्लस्टर धोका' : 'Suspected Acute Cholera / Severe Gastroenteritis Cluster';
    suggestedPlan = mr ? '१. तात्काळ ORS / IV रिंगर लॅक्टेट जलसंजीवनी.\n२. शौच नमुना तपासणी व १४ दिवस झिंक.\n३. IDSP अंतर्गत उद्रेक सूचना व विहिरीचे सुपर-क्लोरिनेशन.' : '1. Rapid fluid resuscitation (ORS/IV RL).\n2. Stool sample & Zinc.\n3. IDSP outbreak notification & well super-chlorination.';
  } else {
    diseaseLabel = mr ? 'तीव्र जलजन्य अतिसार / गॅस्ट्रोएन्टेरिटिस (Acute Gastroenteritis)' : 'Acute Water-Borne Gastroenteritis';
    considerations.add(DoctorConsideration(
      condition: mr ? 'तीव्र जलजन्य अतिसार / गॅस्ट्रोएन्टेरिटिस' : 'Acute Water-Borne Diarrhoeal Illness',
      evidenceQuote: snippet,
      confidence: flags.isNotEmpty ? 'high' : 'medium',
    ));
    if (hasVomiting) {
      considerations.add(DoctorConsideration(
        condition: mr ? 'उलट्यांसह इलेक्ट्रोलाईट व जलशुष्कता धोका' : 'Acute Gastroenteritis with Emesis',
        evidenceQuote: snippet,
        confidence: 'medium',
      ));
    }
    askNext.addAll(mr
        ? [
            'दिवसातून किती वेळा पातळ शौच होत आहे आणि शौचात रक्त आहे का?',
            'सध्या लघवी सामान्य होते का आणि डोळे खोल गेले आहेत का?',
            'रुग्ण पाणी व ORS व्यवस्थित पिऊ शकतो का?',
            'पिण्याच्या पाण्याचा मुख्य स्रोत कोणता आहे?',
          ]
        : [
            'How many loose stools per day, and is there any blood?',
            'Is urine output adequate, and are eyes sunken?',
            'Is the patient able to drink ORS without vomiting?',
            'What is the primary household drinking water source?',
          ]);
    guidelines.add(DoctorGuideline(
      id: 'g-ors-1',
      title: mr ? 'NRHM / WHO IMNCI जलसंजीवनी प्रोटोकॉल' : 'NRHM / WHO IMNCI Hydration Protocol',
      page: 14,
      topic: 'ors',
      text: mr ? 'प्रत्येक पातळ शौचानंतर ओआरएस (ORS) द्या: मुलांसाठी १००-२०० मि.ली., मोठ्यांसाठी भरपूर.' : 'Give low-osmolarity ORS after every loose stool (Plan A/B).',
    ));
    guidelines.add(DoctorGuideline(
      id: 'g-zinc-1',
      title: mr ? 'राष्ट्रीय अतिसार नियंत्रण कार्यक्रम — झिंक (Zinc)' : 'National Diarrhoea Control Zinc Guideline',
      page: 22,
      topic: 'zinc',
      text: mr ? 'बालकांना १४ दिवस सलग विरघळणाऱ्या झिंक गोळ्या (२० मि.ग्रॅ./दिवस) द्या.' : 'Dispersible Zinc for 14 continuous days (20 mg/day for children).',
    ));
    suggestedAssessment = mr ? 'तीव्र जलजन्य अतिसार / गॅस्ट्रोएन्टेरिटिस' : 'Acute Water-Borne Gastroenteritis';
    suggestedPlan = mr ? '१. प्रत्येक पातळ शौचानंतर ORS जलसंजीवनी.\n२. १४ दिवस झिंक गोळ्या व हलका आहार.\n३. पाणी २० मिनिटे उकळून पिणे.' : '1. Low-osmolarity ORS after loose stools.\n2. 14-day Zinc course & light diet.\n3. Boil drinking water for 20 minutes.';
  }

  return DoctorResult(
    transcript: text,
    diseaseLabel: diseaseLabel,
    subjective: mr ? 'रुग्णाची नोंदवलेली तक्रार ($diseaseLabel): $text' : 'Patient reported history ($diseaseLabel): $text',
    objective: flags.isNotEmpty
        ? (mr ? 'तपासणीत आढळलेली धोक्याची चिन्हे: ${flags.map((f) => dangerLabels[f]?['mr'] ?? f).join(', ')}. तात्काळ वैद्यकीय मूल्यांकन आवश्यक.' : 'Triggered clinical red flags: ${flags.map((f) => dangerLabels[f]?['en'] ?? f).join(', ')}.')
        : (mr ? 'सामान्य स्थिती स्थिर; तीव्र डिहायड्रेशन किंवा धोक्याची चिन्हे नाहीत.' : 'General condition stable; no immediate severe danger signs.'),
    askNext: askNext,
    consider: considerations,
    redFlags: flags,
    guidelines: guidelines,
    suggestedAssessment: suggestedAssessment,
    suggestedPlan: suggestedPlan,
    context: {
      'village': village,
      'casesThisWeek': 5,
      'floodFlag': true,
      'provenance': 'simulated',
    },
  );
}

// --- LOCAL PERSISTENT STORE (SharedPreferences) ---

class LocalStore {
  static const String casesKey = 'local_cases_v1';
  static const String identKey = 'local_identity_v1';
  static const String seededKey = 'jalsanket_seeded_v1';
  static const String notesKey = 'jalsanket_consult_notes_v1';

  static final List<SavedCaseRow> _initialDemoCases = [
    SavedCaseRow(
      id: 'case-seed-1',
      savedAt: DateTime.now().subtract(const Duration(minutes: 42)).toIso8601String(),
      villageId: 'v-shirol',
      village: 'शिरोळ (Shirol)',
      patientPseudoId: 'P-SHL-041',
      patientName: 'सुनीता (Sunita)',
      transcript:
          'रुग्णाचे नाव सुनीता, वय पाच, शिरोळ गाव. तिला दोन दिवसांपासून जुलाब आहे, शौचात रक्त आहे, डोळे खोल गेले आहेत, पाणी पिऊ शकत नाही.',
      symptoms: ['diarrhoea', 'blood_in_stool', 'sunken_eyes'],
      ageYears: 5,
      ageBand: '5-14',
      gender: 'female',
      durationDays: 2,
      fever: false,
      stoolsPerDay: 7,
      vomitCount: 2,
      bloodInStool: true,
      ableToDrink: false,
      verySleepy: true,
      urinePassed: false,
      othersSickAtHome: true,
      orsGiven: true,
      pregnancy: false,
      infant: false,
      waterSourceText: 'विहीर (Open Well #3)',
      dangerSigns: ['sunken_eyes', 'unable_to_drink', 'very_sleepy', 'blood_in_stool'],
      severityFlag: true,
      waterRiskPercent: 90,
      isWaterBorne: true,
      waterRiskReason:
          'सध्याची लक्षणे (जुलाब, शौचात रक्त, घरात इतरही आजारी, असुरक्षित पाण्याचा स्रोत) दूषित पाण्यामुळे उद्भवणाऱ्या जलजन्य आजाराशी सुसंगत आहेत.',
      healthTips: [
        'पिण्याचे पाणी किमान २० मिनिटे उकळून किंवा मेडिक्लोर / क्लोरिन गोळ्या टाकूनच प्या.',
        'डिहायड्रेशन रोखण्यासाठी रुग्णाला वारंवार ओआरएस (ORS) पाणी, ताक किंवा लिंबू पाणी द्या.',
        'धोक्याची चिन्हे आढळल्यास त्वरित जवळच्या प्राथमिक आरोग्य केंद्रात (PHC) दाखवा.',
      ],
      edits: {'stoolsPerDay': 7},
      inputMode: 'audio',
      provenance: 'live',
      durationSec: 18,
      isForwardedToDoctor: true,
      forwardedAt: DateTime.now().subtract(const Duration(minutes: 42)).toIso8601String(),
      doctorNotes: 'धोक्याची चिन्हे आढळली (तातडीने सलाईन व ओआरएस आवश्यक)',
      priority: 'urgent',
      doctorStatus: 'pending',
    ),
    SavedCaseRow(
      id: 'case-seed-2',
      savedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 15)).toIso8601String(),
      villageId: 'v-pimpri',
      village: 'पिंपरी (Pimpri)',
      patientPseudoId: 'P-PMP-019',
      patientName: 'राकेश (Rakesh)',
      transcript:
          'रुग्णाचे नाव राकेश, वय बत्तीस, पिंपरी गाव. त्याला तीन दिवसांपासून जुलाब आणि उलट्या होत आहेत, ताप नाही.',
      symptoms: ['diarrhoea', 'vomiting'],
      ageYears: 32,
      ageBand: '15-59',
      gender: 'male',
      durationDays: 3,
      fever: false,
      stoolsPerDay: 4,
      vomitCount: 2,
      bloodInStool: false,
      ableToDrink: true,
      verySleepy: false,
      urinePassed: true,
      othersSickAtHome: false,
      orsGiven: true,
      pregnancy: false,
      infant: false,
      waterSourceText: 'ग्रामपंचायत नळ (Tap Water)',
      dangerSigns: [],
      severityFlag: false,
      waterRiskPercent: 50,
      isWaterBorne: true,
      waterRiskReason:
          'सध्याची लक्षणे (जुलाब, उलट्या) दूषित पाणी किंवा अस्वच्छतेमुळे उद्भवणाऱ्या जलजन्य आजाराशी (Water-borne Illness) सुसंगत आहेत.',
      healthTips: [
        'पिण्याचे पाणी किमान २० मिनिटे उकळून किंवा मेडिक्लोर / क्लोरिन गोळ्या टाकूनच प्या.',
        'डिहायड्रेशन रोखण्यासाठी रुग्णाला वारंवार ओआरएस (ORS) पाणी, ताक किंवा लिंबू पाणी द्या.',
        'जेवणापूर्वी व शौचाहून आल्यावर हात साबणाने स्वच्छ धुवा.',
      ],
      edits: {},
      inputMode: 'typed',
      provenance: 'live',
      durationSec: 0,
    ),
  ];

  static Future<void> ensureSeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seeded = prefs.getBool(seededKey) ?? false;
      if (!seeded || !prefs.containsKey(casesKey)) {
        final listJson = jsonEncode(_initialDemoCases.map((e) => e.toJson()).toList());
        await prefs.setString(casesKey, listJson);
        await prefs.setString(
          identKey,
          jsonEncode({
            'P-SHL-041': 'सुनीता (Sunita)',
            'P-PMP-019': 'राकेश (Rakesh)',
          }),
        );
        await prefs.setBool(seededKey, true);
      }
    } catch (_) {}
  }

  static Future<List<SavedCaseRow>> all() async {
    await ensureSeeded();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(casesKey);
      if (raw == null || raw.isEmpty) return List.from(_initialDemoCases);

      final List decoded = jsonDecode(raw);
      final identRaw = prefs.getString(identKey);
      final Map<String, dynamic> idents = identRaw != null ? jsonDecode(identRaw) : {};

      return decoded.map((e) {
        final row = SavedCaseRow.fromJson(Map<String, dynamic>.from(e as Map));
        final resolvedName = row.patientName ?? idents[row.patientPseudoId] as String?;
        if (resolvedName != row.patientName) {
          return row.copyWith(patientName: resolvedName);
        }
        return row;
      }).toList();
    } catch (_) {
      return List.from(_initialDemoCases);
    }
  }

  static Future<SavedCaseRow> saveFromExtraction(
    VoiceExtraction x, {
    required String villageId,
    required String patientPseudoId,
    required List<String> danger,
    required int durationSec,
    WaterRiskAssessment? risk,
    bool isForwardedToDoctor = false,
    String? doctorNotes,
    String priority = 'normal',
    String doctorStatus = 'none',
  }) async {
    await ensureSeeded();
    final r = risk ?? computeWaterRisk(x);
    final age = x.ageYears.value;

    final row = SavedCaseRow(
      id: 'case-${DateTime.now().millisecondsSinceEpoch}',
      savedAt: DateTime.now().toIso8601String(),
      villageId: villageId.isNotEmpty ? villageId : (x.village.value ?? 'v-local'),
      village: x.village.value ?? (villageId.isNotEmpty ? villageId : 'स्थानिक गाव'),
      patientPseudoId: patientPseudoId,
      patientName: x.patientName.value,
      transcript: x.transcript,
      symptoms: x.symptoms.value ?? [],
      ageYears: age,
      ageBand: age == null ? null : age < 5 ? '0-4' : age < 15 ? '5-14' : age < 60 ? '15-59' : '60+',
      gender: x.gender.value,
      durationDays: x.durationDays.value,
      fever: x.fever.value,
      stoolsPerDay: x.stoolsPerDay.value,
      vomitCount: x.vomitCount.value,
      bloodInStool: x.bloodInStool.value,
      ableToDrink: x.ableToDrink.value,
      verySleepy: x.verySleepy.value,
      urinePassed: x.urinePassed.value,
      othersSickAtHome: x.othersSickAtHome.value,
      orsGiven: x.orsGiven.value,
      pregnancy: x.pregnancy.value,
      infant: x.infant.value,
      waterSourceText: x.waterSource.value,
      dangerSigns: danger,
      severityFlag: danger.isNotEmpty,
      waterRiskPercent: r.percentage,
      isWaterBorne: r.isWaterBorne,
      waterRiskReason: r.reason,
      healthTips: r.tips,
      edits: {},
      inputMode: x.meta['inputMode'] ?? 'typed',
      provenance: x.meta['provenance'] ?? 'live',
      durationSec: durationSec,
      isForwardedToDoctor: isForwardedToDoctor,
      forwardedAt: isForwardedToDoctor ? DateTime.now().toIso8601String() : null,
      doctorNotes: doctorNotes,
      priority: priority,
      doctorStatus: doctorStatus,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final cases = await all();
      cases.insert(0, row);
      await prefs.setString(casesKey, jsonEncode(cases.map((e) => e.toJson()).toList()));

      if (x.patientName.value != null && x.patientName.value!.trim().isNotEmpty) {
        final identRaw = prefs.getString(identKey);
        final Map<String, dynamic> idents = identRaw != null ? jsonDecode(identRaw) : {};
        idents[patientPseudoId] = x.patientName.value!.trim();
        await prefs.setString(identKey, jsonEncode(idents));
      }
    } catch (_) {}

    return row;
  }

  static Future<void> forwardCaseToDoctor(
    String caseId, {
    String? notes,
    String priority = 'normal',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cases = await all();
      final idx = cases.indexWhere((c) => c.id == caseId);
      if (idx != -1) {
        cases[idx] = cases[idx].copyWith(
          isForwardedToDoctor: true,
          forwardedAt: DateTime.now().toIso8601String(),
          doctorNotes: notes,
          priority: priority,
          doctorStatus: 'pending',
        );
        await prefs.setString(casesKey, jsonEncode(cases.map((e) => e.toJson()).toList()));
      }
    } catch (_) {}
  }

  static Future<void> saveDoctorReviewForCase(
    String caseId, {
    required String doctorName,
    required String assessment,
    required String plan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cases = await all();
      final idx = cases.indexWhere((c) => c.id == caseId);
      if (idx != -1) {
        cases[idx] = cases[idx].copyWith(
          doctorStatus: 'reviewed',
          doctorName: doctorName,
          reviewedAt: DateTime.now().toIso8601String(),
          doctorAssessment: assessment,
          doctorPlan: plan,
        );
        await prefs.setString(casesKey, jsonEncode(cases.map((e) => e.toJson()).toList()));
      }
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(casesKey, jsonEncode([]));
      await prefs.setString(identKey, jsonEncode({}));
    } catch (_) {}
  }

  static Future<void> restoreDemoCases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(seededKey);
      await ensureSeeded();
    } catch (_) {}
  }

  static Future<void> saveSignedNote(SignedConsultNote note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(notesKey);
      final List list = raw != null ? jsonDecode(raw) : [];
      list.insert(0, note.toJson());
      await prefs.setString(notesKey, jsonEncode(list));
    } catch (_) {}
  }
}
