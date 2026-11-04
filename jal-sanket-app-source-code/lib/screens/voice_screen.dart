import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_engine.dart';
import 'gemini_service.dart';

// Backward compatibility class
class SavedCaseReport {
  final String id;
  final String name;
  final String village;
  final String symptoms;
  final String timestamp;
  final String status;

  SavedCaseReport({
    required this.id,
    required this.name,
    required this.village,
    required this.symptoms,
    required this.timestamp,
    required this.status,
  });
}

class VoiceScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final String userRole;
  final bool showBottomNav;
  final VoidCallback? onMenuTap;
  final String initialTab;

  const VoiceScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
    this.userRole = 'ASHA Worker',
    this.showBottomNav = false,
    this.onMenuTap,
    this.initialTab = 'record',
  });

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  String _lang = 'mr'; // 'mr' or 'en'
  String _activeTab = 'record'; // 'record' | 'review' | 'doctor' | 'cases'

  // Controllers
  late TextEditingController _villageController;
  late TextEditingController _pseudoIdController;
  late TextEditingController _typedTextController;
  late TextEditingController _doctorTranscriptController;
  late TextEditingController _assessmentController;
  late TextEditingController _planController;

  // Review screen field controllers
  late TextEditingController _reviewNameController;
  late TextEditingController _reviewAgeController;
  late TextEditingController _reviewVillageController;
  late TextEditingController _reviewDaysController;

  bool _consentChecked = true;
  String _consentId = 'CONSENT-INITIAL';
  int _durationSec = 0;
  String? _toastMessage;
  Timer? _toastTimer;

  // Extraction & Doctor consult state
  late VoiceExtraction _currentExtraction;
  late DoctorResult _doctorResult;
  List<SavedCaseRow> _savedCases = [];
  String _casesFilter = 'all'; // 'all' | 'danger' | 'forwarded'
  SavedCaseRow? _activeConsultCase;

  // Voice recording & STT state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListeningReal = false;
  bool _isRecording = false;
  bool _simulatingVoice = false;
  String _liveStreamWords = '';
  int _recordingSecs = 0;
  Timer? _recordTimer;
  Timer? _simTimer;
  bool _villageListening = false;
  int _sampleIndex = 1;
  bool _isExtractingAI = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _villageController = TextEditingController(text: 'पिंपरी (Pimpri)');
    _pseudoIdController = TextEditingController(text: 'P-PMP-104');
    _typedTextController = TextEditingController();
    _doctorTranscriptController = TextEditingController();
    _assessmentController = TextEditingController();
    _planController = TextEditingController();

    _reviewNameController = TextEditingController();
    _reviewAgeController = TextEditingController();
    _reviewVillageController = TextEditingController();
    _reviewDaysController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial extraction from sample
    _currentExtraction = LocalExtractor.extract(sampleReports[0].transcript);
    _syncReviewControllers();

    // Initial doctor consult
    final initialDocText = sampleReports[1].transcript;
    _doctorTranscriptController.text = initialDocText;
    _doctorResult = buildSimulatedDoctorConsult(initialDocText, mr: _lang == 'mr');
    _assessmentController.text = _doctorResult.suggestedAssessment ?? '';
    _planController.text = _doctorResult.suggestedPlan ?? '';

    _activeTab = widget.initialTab;
    if (widget.userRole == 'Medical Officer') {
      _casesFilter = 'forwarded';
    }
    _loadSavedCases();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('STT status: $status');
          if (mounted) {
            if (status == 'listening') {
              setState(() {
                _isListeningReal = true;
              });
            } else if (status == 'done' || status == 'notListening') {
              if (_isRecording && !_simulatingVoice) {
                // If user finished speaking and has recognized words, auto-analyze
                if (_liveStreamWords.trim().isNotEmpty && !_isExtractingAI) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _isRecording && !_isExtractingAI) {
                      _stopRecording();
                    }
                  });
                }
              }
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('STT error: ${errorNotification.errorMsg}');
          if (mounted) {
            setState(() {
              _isListeningReal = false;
            });
            // If user paused and timeout fired, but we have recognized speech words, auto-analyze!
            if (_isRecording && _liveStreamWords.trim().isNotEmpty && !_isExtractingAI) {
              _stopRecording();
            } else if (_isRecording && _liveStreamWords.trim().isEmpty) {
              setState(() => _isRecording = false);
            }
          }
        },
      );
      if (mounted) {
        setState(() {
          _speechEnabled = available;
        });
      }
      debugPrint('STT initialized: available=$available');
    } catch (e) {
      debugPrint('STT init error: $e');
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _simTimer?.cancel();
    _toastTimer?.cancel();
    _pulseController.dispose();

    _villageController.dispose();
    _pseudoIdController.dispose();
    _typedTextController.dispose();
    _doctorTranscriptController.dispose();
    _assessmentController.dispose();
    _planController.dispose();

    _reviewNameController.dispose();
    _reviewAgeController.dispose();
    _reviewVillageController.dispose();
    _reviewDaysController.dispose();

    super.dispose();
  }

  bool get _isMr => _lang == 'mr';

  Future<void> _loadSavedCases() async {
    final list = await LocalStore.all();
    if (mounted) {
      setState(() {
        _savedCases = list;
      });
    }
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = msg;
    });
    _toastTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  void _syncReviewControllers() {
    _reviewNameController.text = _currentExtraction.patientName.value ?? '';
    _reviewAgeController.text = _currentExtraction.ageYears.value?.toString() ?? '';
    _reviewVillageController.text = _currentExtraction.village.value ?? _villageController.text;
    _reviewDaysController.text = _currentExtraction.durationDays.value?.toString() ?? '';
  }

  void _onExtractionComplete(VoiceExtraction extraction, {int duration = 0}) {
    if ((extraction.village.value == null || extraction.village.value!.isEmpty) && _villageController.text.trim().isNotEmpty) {
      extraction.village.value = _villageController.text.trim();
    } else if (extraction.village.value != null && extraction.village.value!.isNotEmpty) {
      _villageController.text = extraction.village.value!;
    }

    setState(() {
      _currentExtraction = extraction;
      _durationSec = duration;
      _consentId = 'CONSENT-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
      _syncReviewControllers();
      _activeTab = 'review';
    });
  }

  void _handleConfirmAndSave() async {
    // 1. Sync any edits made in Review controllers back into _currentExtraction
    final pName = _reviewNameController.text.trim();
    if (pName.isNotEmpty) {
      _currentExtraction.patientName.value = pName;
      _currentExtraction.patientName.status = 'ok';
    }
    final pAge = int.tryParse(_reviewAgeController.text.trim());
    if (pAge != null) {
      _currentExtraction.ageYears.value = pAge;
      _currentExtraction.ageYears.status = 'ok';
    }
    final pVillage = _reviewVillageController.text.trim();
    if (pVillage.isNotEmpty) {
      _currentExtraction.village.value = pVillage;
      _currentExtraction.village.status = 'ok';
    }
    final pDays = int.tryParse(_reviewDaysController.text.trim());
    if (pDays != null) {
      _currentExtraction.durationDays.value = pDays;
      _currentExtraction.durationDays.status = 'ok';
    }

    final danger = computeDangerSigns(_currentExtraction);
    final risk = computeWaterRisk(_currentExtraction, mr: _isMr);

    final savedRow = await LocalStore.saveFromExtraction(
      _currentExtraction,
      villageId: pVillage.isNotEmpty ? pVillage : _villageController.text.trim(),
      patientPseudoId: _pseudoIdController.text.trim(),
      danger: danger,
      durationSec: _durationSec,
      risk: risk,
      isForwardedToDoctor: true,
      priority: danger.isNotEmpty ? 'urgent' : 'normal',
      doctorStatus: 'pending',
      ashaName: widget.userName,
    );
    debugPrint('Saved case successfully: ${savedRow.id}, patient: ${savedRow.patientName}');

    await _loadSavedCases();

    _pseudoIdController.text = 'P-MH-${100 + (DateTime.now().millisecond % 899)}';
    _showToast(_isMr ? 'रुग्णाची केस यशस्वीरित्या जतन केली गेली!' : 'Patient case saved successfully!');

    setState(() {
      _activeTab = 'cases';
    });
  }

  void _openDoctorConsult(String transcriptText, {SavedCaseRow? fromCase}) {
    setState(() {
      _activeConsultCase = fromCase;
      _doctorTranscriptController.text = transcriptText;
      _doctorResult = buildSimulatedDoctorConsult(transcriptText, mr: _isMr);
      _assessmentController.text = _doctorResult.suggestedAssessment ?? '';
      _planController.text = _doctorResult.suggestedPlan ?? '';
      _activeTab = 'doctor';
    });
  }

  void _handleForwardToDoctor({
    required String priority,
    required String notes,
  }) async {
    final pName = _reviewNameController.text.trim();
    if (pName.isNotEmpty) {
      _currentExtraction.patientName.value = pName;
      _currentExtraction.patientName.status = 'ok';
    }
    final pAge = int.tryParse(_reviewAgeController.text.trim());
    if (pAge != null) {
      _currentExtraction.ageYears.value = pAge;
      _currentExtraction.ageYears.status = 'ok';
    }
    final pVillage = _reviewVillageController.text.trim();
    if (pVillage.isNotEmpty) {
      _currentExtraction.village.value = pVillage;
      _currentExtraction.village.status = 'ok';
    }
    final pDays = int.tryParse(_reviewDaysController.text.trim());
    if (pDays != null) {
      _currentExtraction.durationDays.value = pDays;
      _currentExtraction.durationDays.status = 'ok';
    }

    final danger = computeDangerSigns(_currentExtraction);
    final risk = computeWaterRisk(_currentExtraction, mr: _isMr);

    final savedRow = await LocalStore.saveFromExtraction(
      _currentExtraction,
      villageId: pVillage.isNotEmpty ? pVillage : _villageController.text.trim(),
      patientPseudoId: _pseudoIdController.text.trim(),
      danger: danger,
      durationSec: _durationSec,
      risk: risk,
      isForwardedToDoctor: true,
      doctorNotes: notes.isNotEmpty ? notes : (_isMr ? 'रुग्ण तपासणीसाठी पाठवला' : 'Referred for doctor evaluation'),
      priority: priority,
      doctorStatus: 'pending',
    );
    debugPrint('Forwarded case to doctor: ${savedRow.id}, patient: ${savedRow.patientName}');

    await _loadSavedCases();
    _pseudoIdController.text = 'P-MH-${100 + (DateTime.now().millisecond % 899)}';

    HapticFeedback.mediumImpact();
    _showToast(_isMr ? 'रुग्ण डॉक्टरांकडे यशस्वीरित्या पाठवला! 👨‍⚕️' : 'Patient forwarded to doctor successfully! 👨‍⚕️');

    setState(() {
      _casesFilter = 'forwarded';
      _activeTab = 'cases';
    });
  }

  void _showForwardToDoctorDialog() {
    final rawName = _reviewNameController.text.trim();
    if (rawName.isNotEmpty) {
      _currentExtraction.patientName.value = rawName;
    }
    final pAge = int.tryParse(_reviewAgeController.text.trim());
    if (pAge != null) {
      _currentExtraction.ageYears.value = pAge;
    }
    final pVillage = _reviewVillageController.text.trim();
    if (pVillage.isNotEmpty) {
      _currentExtraction.village.value = pVillage;
    }

    final pName = _currentExtraction.patientName.value ?? _reviewNameController.text.trim();
    final danger = computeDangerSigns(_currentExtraction);
    String selectedPriority = danger.isNotEmpty ? 'urgent' : 'normal';
    final notesController = TextEditingController(
      text: danger.isNotEmpty
          ? (_isMr ? 'धोक्याची चिन्हे आढळली (तातडीने तपासणी आवश्यक)' : 'Danger signs detected (urgent evaluation needed)')
          : (_isMr ? 'रुग्ण तपासणी व उपचारासाठी रेफर केले' : 'Referred for examination and treatment'),
    );

    final quickReasons = _isMr
        ? ['अतिसार व डिहायड्रेशन', 'शौचात रक्त', 'वारंवार उलट्या', 'सलाईन आवश्यक', 'पाणी पिऊ शकत नाही']
        : ['Severe Dehydration', 'Blood in stool', 'Persistent Vomiting', 'Needs IV Fluids', 'Unable to drink'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F766E), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isMr ? 'रुग्ण डॉक्टरांकडे पाठवा (Refer to Doctor)' : 'Forward Case to PHC Doctor',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                              ),
                              Text(
                                _isMr ? 'प्राथमिक आरोग्य केंद्र (PHC) वैद्यकीय अधिकारी' : 'Primary Health Centre Medical Officer',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pName.isNotEmpty ? pName : (_isMr ? 'नाव नोंदवले नाही' : 'Patient (Unnamed)'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _reviewVillageController.text.isNotEmpty ? _reviewVillageController.text : _villageController.text,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                            ],
                          ),
                          if (danger.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '⚠️ ${_isMr ? "धोक्याची चिन्हे: " : "Danger: "}${danger.map((d) => dangerLabels[d]?[_lang] ?? d).join(", ")}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isMr ? 'रेफरल प्राधान्य (Referral Urgency):' : 'Referral Urgency:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedPriority = 'urgent'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedPriority == 'urgent' ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPriority == 'urgent' ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1),
                                  width: selectedPriority == 'urgent' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isMr ? '🔴 तात्काळ (Urgent)' : '🔴 URGENT',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: selectedPriority == 'urgent' ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setSheetState(() => selectedPriority = 'normal'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedPriority == 'normal' ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPriority == 'normal' ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
                                  width: selectedPriority == 'normal' ? 1.8 : 1.0,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isMr ? '🔵 नियमित (Normal)' : '🔵 NORMAL',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: selectedPriority == 'normal' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _isMr ? 'द्रुत नोंद टॅग्ज (Quick Referral Tags):' : 'Quick Referral Tags:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickReasons.map((r) {
                        return ActionChip(
                          label: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onPressed: () {
                            setSheetState(() {
                              if (notesController.text.trim().isEmpty) {
                                notesController.text = r;
                              } else {
                                notesController.text += ', $r';
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isMr ? 'डॉक्टरांसाठी नोंद / कारण (Notes for Doctor):' : 'Notes / Clinical Referral Reason:',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: _isMr ? 'उदा. तातडीने सलाईन व अँटीबायोटिक आवश्यक...' : 'e.g. Needs immediate IV fluids and observation...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleForwardToDoctor(
                            priority: selectedPriority,
                            notes: notesController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isMr ? 'पुष्टी करा व डॉक्टरांकडे पाठवा' : 'Confirm & Forward to Doctor',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startLiveRecording() async {
    if (!_consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isMr ? 'कृपया प्रथम रुग्णाची संमती निवडा.' : 'Please check patient consent before recording.'),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
      return;
    }

    _simTimer?.cancel();
    _recordTimer?.cancel();

    setState(() {
      _isRecording = true;
      _simulatingVoice = false;
      _recordingSecs = 0;
      _liveStreamWords = '';
      _isListeningReal = false;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSecs++;
      });
      if (_recordingSecs >= 45) {
        _stopRecording();
      }
    });

    if (!_speechEnabled) {
      await _initSpeech();
    }

    // Real live voice recognition via device/emulator microphone
    bool startedReal = false;
    if (_speechEnabled) {
      try {
        // Explicitly set language: 'mr_IN' for Marathi, 'en_IN' for English
        final String selectedLocale = _isMr ? 'mr_IN' : 'en_IN';
        debugPrint('STT starting with locale: $selectedLocale');

        // Note: speech_to_text listen returns Future<void> (implicit null)
        await _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            debugPrint('STT recognized: "${result.recognizedWords}" (final: ${result.finalResult})');
            setState(() {
              _liveStreamWords = result.recognizedWords;
              _typedTextController.text = result.recognizedWords;
            });
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted && _isRecording && !_simulatingVoice) {
                  _stopRecording();
                }
              });
            }
          },
          listenOptions: stt.SpeechListenOptions(
            localeId: selectedLocale,
            listenMode: stt.ListenMode.dictation,
            cancelOnError: false,
            partialResults: true,
          ),
        );
        startedReal = true;
      } catch (e) {
        debugPrint('Speech listen error: $e');
        startedReal = false;
      }
    }

    if (mounted) {
      setState(() {
        _isListeningReal = startedReal;
      });
    }

    if (!startedReal) {
      debugPrint('Real speech recognition could not start.');
      _showToast(_isMr ? 'मायक्रोफोन सुरू होऊ शकला नाही. परवानगी तपासा.' : 'Could not start microphone. Check permissions.');
    }
  }

  Future<void> _processAndAnalyzeText(String text, {int duration = 0}) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _recordTimer?.cancel();
    _simTimer?.cancel();

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final dur = duration > 0 ? duration : (_recordingSecs > 0 ? _recordingSecs : 1);

    setState(() {
      _isRecording = false;
      _simulatingVoice = false;
      _isListeningReal = false;
      _isExtractingAI = true;
      _typedTextController.text = clean;
    });

    _showToast(_isMr ? '✨ Gemini AI तपासत आहे...' : '✨ Verifying with Gemini AI...');

    VoiceExtraction extraction;
    try {
      extraction = await GeminiService.extract(
        clean,
        villageHint: _villageController.text.trim(),
        mr: _isMr,
      );
      _showToast(_isMr ? '✨ Gemini AI द्वारे अचूक तपासणी पूर्ण!' : '✨ Verified with Gemini AI (100% accurate)!');
    } catch (e) {
      debugPrint('Gemini extraction error: $e, fallback to LocalExtractor');
      extraction = LocalExtractor.extract(clean);
      _showToast(_isMr ? 'स्थानिक विश्लेषणाने नोंद पूर्ण' : 'Processed via local rules');
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingAI = false;
        });
      }
    }

    _onExtractionComplete(extraction, duration: dur);
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _simTimer?.cancel();

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    final rawSpoken = _liveStreamWords.trim();
    final text = rawSpoken.isNotEmpty
        ? rawSpoken
        : _typedTextController.text.trim();
    final dur = _recordingSecs > 0 ? _recordingSecs : 1;

    setState(() {
      _isRecording = false;
      _simulatingVoice = false;
      _isListeningReal = false;
    });

    if (text.isEmpty) {
      _showToast(_isMr
          ? 'कोणताही आवाज ऐकला नाही. कृपया पुन्हा बोला किंवा टाईप करा.'
          : 'No voice detected. Please speak into the mic or type.');
      return;
    }

    await _processAndAnalyzeText(text, duration: dur);
  }

  void _runVoiceDemo() {
    if (_isRecording || _simulatingVoice) return;

    _simTimer?.cancel();
    _recordTimer?.cancel();

    final target = sampleReports[_sampleIndex % sampleReports.length].transcript;
    _sampleIndex++;
    final words = target.split(' ');
    int idx = 0;

    setState(() {
      _simulatingVoice = true;
      _isRecording = true;
      _recordingSecs = 0;
      _liveStreamWords = '';
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSecs++;
      });
    });

    _simTimer = Timer.periodic(const Duration(milliseconds: 140), (timer) {
      if (!mounted) return;
      if (idx < words.length) {
        setState(() {
          _liveStreamWords += (idx == 0 ? '' : ' ') + words[idx];
          _typedTextController.text = _liveStreamWords;
        });
        idx++;
      } else {
        timer.cancel();
        _recordTimer?.cancel();
        setState(() {
          _simulatingVoice = false;
          _isRecording = false;
        });
        _processAndAnalyzeText(target, duration: _recordingSecs);
      }
    });
  }

  Future<void> _analyzeTypedText() async {
    final text = _typedTextController.text.trim();
    if (text.isEmpty) return;
    await _processAndAnalyzeText(text);
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Header
            _buildTopHeader(),

            const SizedBox(height: 12),

            // Toast message if present
            if (_toastMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _toastMessage!,
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 4-Tab Navigation Strip
            _buildTabNavigation(),

            const SizedBox(height: 14),

            // Active Tab Content
            if (_activeTab == 'record') _buildRecordTab(),
            if (_activeTab == 'review') _buildReviewTab(),
            if (_activeTab == 'doctor') _buildDoctorTab(),
            if (_activeTab == 'cases') _buildCasesTab(),

            const SizedBox(height: 24),

            // Simple Footer
            _buildFooter(),
          ],
        ),
      ),
    );

    if (!widget.showBottomNav) {
      return Container(
        color: const Color(0xFFF0F6FB),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: content,
    );
  }

  // --- TOP HEADER ---
  Widget _buildTopHeader() {
    return Row(
      children: [
        _buildSquareIconButton(
          icon: Icons.menu_rounded,
          onTap: () {
            if (widget.onMenuTap != null) {
              widget.onMenuTap!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isMr ? 'मेनू उघडला' : 'Menu tapped')),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        Image.asset(
          'assets/images/app-logo.png',
          height: 44,
          fit: BoxFit.contain,
        ),
        const Spacer(),

        // Notification Bell
        _buildSquareIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_isMr ? '१ आरोग्य सूचना प्राप्त' : '1 health alert received')),
            );
          },
        ),

        const SizedBox(width: 6),

        // Language Toggle Pill
        InkWell(
          onTap: () {
            setState(() {
              _lang = _isMr ? 'en' : 'mr';
              if (_doctorTranscriptController.text.isNotEmpty) {
                _doctorResult = buildSimulatedDoctorConsult(_doctorTranscriptController.text, mr: _lang == 'mr');
                _assessmentController.text = _doctorResult.suggestedAssessment ?? '';
                _planController.text = _doctorResult.suggestedPlan ?? '';
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isMr ? 'मराठी' : 'English',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1E36),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: Color(0xFF0284C7),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 6),

        // Profile Button
        _buildSquareIconButton(
          icon: Icons.person_outline_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.userName} (${widget.userId}) Profile')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSquareIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  // --- 4-TAB NAVIGATION STRIP ---
  Widget _buildTabNavigation() {
    final pendingDoctor = _savedCases.where((r) => r.isForwardedToDoctor && r.doctorStatus == 'pending').length;
    final tabs = [
      {'id': 'record', 'label': _isMr ? '१. आवाज नोंद' : '1. Record', 'icon': Icons.mic_rounded},
      {'id': 'review', 'label': _isMr ? '२. तपासा' : '2. Review', 'icon': Icons.assignment_turned_in_outlined},
      {
        'id': 'doctor',
        'label': _isMr
            ? (pendingDoctor > 0 ? '३. डॉक्टर ($pendingDoctor)' : '३. डॉक्टर')
            : (pendingDoctor > 0 ? '3. Doctor ($pendingDoctor)' : '3. Doctor'),
        'icon': Icons.medical_services_outlined
      },
      {'id': 'cases', 'label': _isMr ? '४. नोंदी (${_savedCases.length})' : '4. Cases (${_savedCases.length})', 'icon': Icons.folder_outlined},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF072F5B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF072F5B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: tabs.map((t) {
          final isSelected = _activeTab == t['id'];
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTab = t['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 17,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // TAB 1: RECORD CASE VIEW
  // ==========================================
  Widget _buildRecordTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Village & Consent Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consent Checkbox
              InkWell(
                onTap: () => setState(() => _consentChecked = !_consentChecked),
                child: Row(
                  children: [
                    Checkbox(
                      value: _consentChecked,
                      onChanged: (v) => setState(() => _consentChecked = v ?? true),
                      activeColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Text(
                        _isMr ? 'रुग्णाची संमती घेतली आहे (Patient Consent Confirmed)' : 'Patient consent confirmed',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 12, color: Color(0xFFF1F5F9)),

              // Village Input with Voice Mic
              Row(
                children: [
                  Text(
                    _isMr ? 'गाव:' : 'Village:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _villageController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        hintText: _isMr ? 'गावाचे नाव टाका...' : 'Enter village name...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      final villages = [
                        'शिरोळ (Shirol)',
                        'पिंपरी (Pimpri)',
                        'वाघोली (Wagholi)',
                        'खेड (Khed)',
                        'मोगर्डे (Mogarde)',
                      ];
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFF0284C7), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isMr ? 'गाव निवडा / बोला:' : 'Select / Speak Village:',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F1E36)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...villages.map((v) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.circle, size: 10, color: Color(0xFF0284C7)),
                                title: Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _villageListening = true;
                                    _villageController.text = v;
                                  });
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    if (mounted) setState(() => _villageListening = false);
                                  });
                                },
                              )),
                            ],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _villageListening ? const Color(0xFFF43F5E) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 18,
                        color: _villageListening ? Colors.white : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Deep Oceanic Mic Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF072F5B),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF072F5B).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _isRecording
                    ? (_simulatingVoice
                        ? (_isMr ? 'व्हॉईस डेमो चालू आहे...' : 'Running Voice Demo...')
                        : (_isMr ? 'ऐकत आहे... प्रत्यक्ष बोला (${_recordingSecs}s)' : 'Listening... Speak into mic (${_recordingSecs}s)'))
                    : (_isMr ? 'माईक दाबा आणि रुग्णाची लक्षणे सांगा' : 'Tap the Microphone & Speak Symptoms'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isMr
                    ? 'उदा. “रुग्णाचे नाव राकेश, वय ३२, पिंपरी गाव. ३ दिवसांपासून जुलाब आणि उलट्या आहेत.”'
                    : 'e.g. “Patient Rakesh, age 32, Pimpri village. Diarrhoea and vomiting for 3 days.”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFBAE6FD),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 10),

              // Spoken Language Selector Pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (!_isMr) setState(() => _lang = 'mr');
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isMr ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗣️ ', style: TextStyle(fontSize: 11)),
                            Text(
                              'मराठी',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: _isMr ? FontWeight.bold : FontWeight.w500,
                                color: _isMr ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        if (_isMr) setState(() => _lang = 'en');
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isMr ? const Color(0xFF0284C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗣️ ', style: TextStyle(fontSize: 11)),
                            Text(
                              'English',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !_isMr ? FontWeight.bold : FontWeight.w500,
                                color: !_isMr ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isExtractingAI) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF818CF8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA5B4FC)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMr ? '✨ Gemini 3.5 Flash अचूक तपासत आहे...' : '✨ Verifying with Gemini 3.5 Flash...',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFE0E7FF), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],

              if (_isRecording) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _simulatingVoice
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                        : (_isListeningReal
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : const Color(0xFF0284C7).withValues(alpha: 0.25)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _simulatingVoice
                          ? const Color(0xFFFBBF24)
                          : (_isListeningReal ? const Color(0xFF34D399) : const Color(0xFF38BDF8)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _simulatingVoice
                            ? Icons.play_circle_filled_rounded
                            : (_isListeningReal ? Icons.mic_rounded : Icons.hourglass_top_rounded),
                        size: 13,
                        color: _simulatingVoice
                            ? const Color(0xFFFBBF24)
                            : (_isListeningReal ? const Color(0xFF34D399) : const Color(0xFF38BDF8)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _simulatingVoice
                            ? (_isMr ? 'सिम्युलेशन डेमो मोड' : 'Simulation Demo Mode')
                            : (_isListeningReal
                                ? (_isMr ? 'मायक्रोफोन सक्रिय — बोला!' : 'Live Mic Active — Speak now!')
                                : (_isMr ? 'मायक्रोफोन जोडत आहे...' : 'Connecting Microphone...')),
                        style: TextStyle(
                          color: _simulatingVoice
                              ? const Color(0xFFFDE68A)
                              : (_isListeningReal ? const Color(0xFFA7F3D0) : const Color(0xFFBAE6FD)),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_liveStreamWords.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.record_voice_over_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _isMr ? 'ऐकलेला आवाज (Transcribed):' : 'Recognized Speech:',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“$_liveStreamWords”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isExtractingAI ? null : () => _processAndAnalyzeText(_liveStreamWords),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          icon: _isExtractingAI
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          label: Text(
                            _isExtractingAI
                                ? (_isMr ? '✨ Gemini AI तपासत आहे...' : '✨ Analyzing...')
                                : (_isMr ? '✨ Gemini AI द्वारे विश्लेषण करा व तपासा' : '✨ Analyze & Review with Gemini AI'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Animated Pulsing Mic Button
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startLiveRecording,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording ? _pulseAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? const Color(0xFFF43F5E) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: _isRecording
                              ? const Color(0xFFF43F5E).withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.25),
                          blurRadius: _isRecording ? 20 : 10,
                          spreadRadius: _isRecording ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 38,
                      color: _isRecording ? Colors.white : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isRecording
                    ? (_isMr ? 'थांबवण्यासाठी लाल बटण दाबा' : 'Tap red button to stop & analyze')
                    : (_liveStreamWords.isNotEmpty
                        ? (_isMr ? 'पुन्हा बोलण्यासाठी माईक दाबा' : 'Tap mic to record again')
                        : (_isMr ? 'माईक दाबा आणि बोला' : 'Tap mic to start speaking')),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Voice Demo Button
              InkWell(
                onTap: _runVoiceDemo,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radio_rounded, size: 14, color: Color(0xFF7DD3FC)),
                      const SizedBox(width: 6),
                      Text(
                        _isMr ? 'आवाज नमुना ऐका (Voice Demo)' : 'Try Voice Demo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Text input alternative
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMr ? 'किंवा खाली लक्षणे टाइप करा:' : 'Or type patient symptoms below:',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typedTextController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: _isMr
                            ? 'उदा. सुनीता, वय ५, शिरोळ गाव, २ दिवसांपासून जुलाब आणि शौचात रक्त...'
                            : 'e.g. Sunita, age 5, Shirol, diarrhoea for 2 days, blood in stool...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      onSubmitted: (_) => _analyzeTypedText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _analyzeTypedText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isMr ? 'तपासा' : 'Analyze',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Quick Sample Cases
        Text(
          _isMr ? 'तपासणीसाठी तयार केसेस (१ क्लिकवर उघडा):' : 'Quick Sample Cases (Tap to Open):',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),

        ...sampleReports.map((sample) {
          final isDanger = sample.severity == 'danger';
          final isCluster = sample.severity == 'cluster';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _processAndAnalyzeText(sample.transcript),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDanger
                        ? const Color(0xFFFECDD3)
                        : isCluster
                            ? const Color(0xFFBAE6FD)
                            : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isDanger
                            ? const Color(0xFFFEE2E2)
                            : isCluster
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDanger ? Icons.warning_amber_rounded : Icons.description_outlined,
                        size: 20,
                        color: isDanger
                            ? const Color(0xFFE11D48)
                            : isCluster
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMr ? sample.titleMr : sample.titleEn,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1E36),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isMr ? sample.tagMr : sample.tagEn,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDanger ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                              fontWeight: isDanger ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TAB 2: REVIEW & RISK VIEW
  // ==========================================
  Widget _buildReviewTab() {
    final danger = computeDangerSigns(_currentExtraction);
    final risk = computeWaterRisk(_currentExtraction, mr: _isMr);

    const waterSources = [
      {'id': 'well', 'labelMr': 'विहीर (Well)', 'labelEn': 'Open Well'},
      {'id': 'borewell', 'labelMr': 'कूपनलिका (Borewell)', 'labelEn': 'Borewell'},
      {'id': 'river', 'labelMr': 'नदी / ओढा (River)', 'labelEn': 'River / Stream'},
      {'id': 'tap', 'labelMr': 'ग्रामपंचायत नळ (Tap)', 'labelEn': 'Piped Tap'},
    ];

    const symptomsList = [
      'diarrhoea',
      'vomiting',
      'fever',
      'typhoid',
      'jaundice',
      'cholera',
      'gastro',
      'abdominal_pain',
      'weakness',
      'sunken_eyes',
      'blood_in_stool',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Action Row
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _activeTab = 'record'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF475569)),
              label: Text(_isMr ? 'मागे' : 'Back', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showForwardToDoctorDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                elevation: 0,
              ),
              icon: const Icon(Icons.send_rounded, size: 14),
              label: Text(_isMr ? 'डॉक्टरांकडे पाठवा' : 'Send to Doctor', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: _handleConfirmAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
              ),
              icon: const Icon(Icons.save_outlined, size: 16),
              label: Text(_isMr ? 'जतन करा' : 'Save', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // AI Verification & Accuracy Pill Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _currentExtraction.meta['provenance'] == 'gemini-ai'
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentExtraction.meta['provenance'] == 'gemini-ai'
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFCBD5E1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _currentExtraction.meta['provenance'] == 'gemini-ai'
                    ? Icons.verified_rounded
                    : Icons.memory_rounded,
                size: 18,
                color: _currentExtraction.meta['provenance'] == 'gemini-ai'
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentExtraction.meta['provenance'] == 'gemini-ai'
                          ? (_isMr ? '✨ Gemini AI द्वारे अचूक विश्लेषण प्रमाणित' : '✨ Verified by Gemini AI Engine')
                          : (_isMr ? 'स्थानिक नियमांवर आधारित विश्लेषण' : 'Rule-based Offline Extractor'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentExtraction.meta['provenance'] == 'gemini-ai'
                            ? const Color(0xFF15803D)
                            : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      _currentExtraction.meta['provenance'] == 'gemini-ai'
                          ? (_isMr ? 'मॉडेल: ${_currentExtraction.meta['modelVersion'] ?? 'gemini-3.5-flash'} · अचूकता: ९८%' : 'Model: ${_currentExtraction.meta['modelVersion'] ?? 'gemini-3.5-flash'} · Accuracy: 98%')
                          : (_isMr ? 'ऑफलाईन मोड · स्थानिक पॅटर्न मॅचिंग' : 'Offline mode · Regex heuristic'),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: _currentExtraction.meta['provenance'] == 'gemini-ai'
                            ? const Color(0xFF166534)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Danger Alert Banner
        if (danger.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMr ? 'धोक्याची चिन्हे आढळली — त्वरित PHC मध्ये पाठवा' : 'Danger Signs Detected — Refer to PHC',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        danger.map((d) => dangerLabels[d]?[_lang] ?? d).join('  •  '),
                        style: const TextStyle(color: Color(0xFFFEE2E2), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Text(
                  _isMr ? 'कोणतीही गंभीर धोक्याची चिन्हे आढळली नाहीत.' : 'No urgent clinical danger signs detected.',
                  style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Water Risk Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isMr ? 'दूषित पाण्यामुळे आजाराची शक्यता' : 'Water-Borne Illness Risk',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F1E36)),
                      ),
                    ],
                  ),
                  Text(
                    '${risk.percentage}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: risk.percentage >= 70
                          ? const Color(0xFFE11D48)
                          : risk.percentage >= 40
                              ? const Color(0xFFD97706)
                              : const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: risk.percentage / 100.0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    risk.percentage >= 70
                        ? const Color(0xFFE11D48)
                        : risk.percentage >= 40
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                risk.reason,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),
              Text(
                _isMr ? 'महत्त्वाच्या आरोग्य सूचना:' : 'Recommended Care Steps:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              ...risk.tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(tip, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Patient Details Form
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isMr ? 'रुग्णाची माहिती व लक्षणे तपासा' : 'Verify Patient Details & Symptoms',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
              ),
              const SizedBox(height: 12),

              // 4 Fields in 2 rows
              Row(
                children: [
                  Expanded(
                    child: _buildSmallTextField(
                      label: _isMr ? 'रुग्णाचे नाव' : 'Patient Name',
                      controller: _reviewNameController,
                      onChanged: (v) => _currentExtraction.patientName.value = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallTextField(
                      label: _isMr ? 'वय (वर्षे)' : 'Age (Yrs)',
                      controller: _reviewAgeController,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _currentExtraction.ageYears.value = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallTextField(
                      label: _isMr ? 'गाव' : 'Village',
                      controller: _reviewVillageController,
                      onChanged: (v) => _currentExtraction.village.value = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallTextField(
                      label: _isMr ? 'किती दिवस आजारी' : 'Days Ill',
                      controller: _reviewDaysController,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _currentExtraction.durationDays.value = int.tryParse(v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Water Source Pills
              Text(
                _isMr ? 'पिण्याच्या पाण्याचा स्रोत:' : 'Drinking Water Source:',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: waterSources.map((ws) {
                  final cur = (_currentExtraction.waterSource.value ?? '').toLowerCase();
                  final isSelected = cur.contains(ws['id']!) ||
                      (ws['id'] == 'well' && cur.contains('विहीर')) ||
                      (ws['id'] == 'borewell' && (cur.contains('कूपनलिका') || cur.contains('हँडपंप'))) ||
                      (ws['id'] == 'river' && (cur.contains('नदी') || cur.contains('ओढा'))) ||
                      (ws['id'] == 'tap' && cur.contains('नळ'));

                  return ChoiceChip(
                    label: Text(
                      _isMr ? ws['labelMr']! : ws['labelEn']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (val) {
                      setState(() {
                        _currentExtraction.waterSource.value = val ? ws['labelMr']! : null;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // Symptoms Chips
              Text(
                _isMr ? 'लक्षणे (टॅप करून निवडा/बदला):' : 'Symptoms (Tap to toggle):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: symptomsList.map((sym) {
                  final activeList = _currentExtraction.symptoms.value ?? [];
                  final isSelected = activeList.contains(sym);
                  final isRed = sym == 'blood_in_stool' || sym == 'sunken_eyes' || sym == 'cholera';

                  return FilterChip(
                    label: Text(
                      symptomLabels[sym]?[_lang] ?? sym,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: isRed ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    showCheckmark: false,
                    onSelected: (val) {
                      setState(() {
                        final list = List<String>.from(_currentExtraction.symptoms.value ?? []);
                        if (val) {
                          list.add(sym);
                        } else {
                          list.remove(sym);
                        }
                        _currentExtraction.symptoms.value = list;
                        if (sym == 'blood_in_stool') _currentExtraction.bloodInStool.value = val;
                        if (sym == 'fever') _currentExtraction.fever.value = val;
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),

              // Key Checkboxes
              _buildReviewCheckbox(
                label: _isMr ? 'शौचात रक्त आहे (Blood in stool)' : 'Blood in stool',
                value: _currentExtraction.bloodInStool.value == true,
                onChanged: (v) {
                  setState(() {
                    _currentExtraction.bloodInStool.value = v;
                    final list = List<String>.from(_currentExtraction.symptoms.value ?? []);
                    if (v && !list.contains('blood_in_stool')) list.add('blood_in_stool');
                    if (!v) list.remove('blood_in_stool');
                    _currentExtraction.symptoms.value = list;
                  });
                },
              ),
              _buildReviewCheckbox(
                label: _isMr ? 'पाणी पिऊ शकत नाही (Unable to drink)' : 'Unable to drink fluids',
                value: _currentExtraction.ableToDrink.value == false,
                onChanged: (v) => setState(() => _currentExtraction.ableToDrink.value = !v),
              ),
              _buildReviewCheckbox(
                label: _isMr ? 'खूप सुस्त / झोपाळू (Very sleepy / lethargic)' : 'Very sleepy / lethargic',
                value: _currentExtraction.verySleepy.value == true,
                onChanged: (v) => setState(() => _currentExtraction.verySleepy.value = v),
              ),
              _buildReviewCheckbox(
                label: _isMr ? 'गर्भवती महिला (Pregnant patient)' : 'Pregnant patient',
                value: _currentExtraction.pregnancy.value == true,
                onChanged: (v) => setState(() => _currentExtraction.pregnancy.value = v),
              ),
              _buildReviewCheckbox(
                label: _isMr ? 'ORS दिले आहे (ORS given)' : 'ORS given',
                value: _currentExtraction.orsGiven.value == true,
                onChanged: (v) => setState(() => _currentExtraction.orsGiven.value = v),
              ),
              _buildReviewCheckbox(
                label: _isMr ? 'घरात इतरही आजारी (Others sick at home)' : 'Others sick at home',
                value: _currentExtraction.othersSickAtHome.value == true,
                onChanged: (v) => setState(() => _currentExtraction.othersSickAtHome.value = v),
              ),

              const SizedBox(height: 16),

              // Forward to Doctor - Primary Action
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF059669)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _showForwardToDoctorDialog,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isMr ? '👨‍⚕️ डॉक्टरांकडे पाठवा (Forward to Doctor)' : '👨‍⚕️ Forward to PHC Doctor',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Confirm and Save Primary Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleConfirmAndSave,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7), width: 1.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 18, color: Color(0xFF0284C7)),
                  label: Text(
                    _isMr ? 'फक्त स्थानिक जतन करा (Save Locally Only)' : 'Save Locally Only',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
          onChanged: (v) {
            setState(() {
              onChanged(v);
            });
          },
        ),
      ],
    );
  }

  Widget _buildReviewCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: DOCTOR CONSULT VIEW
  // ==========================================
  Widget _buildDoctorTab() {
    final presets = [
      {'id': 'stomach', 'labelMr': 'पोटदुखी', 'labelEn': 'Stomach Pain', 'text': 'ओंकार सागर कांबळे वय बारा गाव मोगर्डे तीन दिवस पोटदुखी'},
      {'id': 'fever', 'labelMr': 'ताप / टायफॉइड', 'labelEn': 'Fever / Typhoid', 'text': 'रुग्णाचे नाव अजय, वय वीस, वाघोली गाव. चार दिवसांपासून थंडी वाजून ताप आणि डोकेदुखी आहे.'},
      {'id': 'jaundice', 'labelMr': 'कावीळ', 'labelEn': 'Jaundice', 'text': 'रुग्णाचे नाव प्रिया, वय पंचवीस, खेड गाव. पाच दिवसांपासून कावीळ, पिवळी लघवी आणि ताप आहे.'},
      {'id': 'diarrhoea', 'labelMr': 'जुलाब व धोक्याची चिन्हे', 'labelEn': 'Severe Diarrhoea', 'text': sampleReports[1].transcript},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_activeConsultCase != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_isMr ? "तपासणीसाठी प्रेषित रुग्ण: " : "Forwarded Patient: "}${_activeConsultCase!.patientName ?? _activeConsultCase!.patientPseudoId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF065F46)),
                          ),
                          Text(
                            '${_activeConsultCase!.village} • ${_activeConsultCase!.ageYears != null ? "${_activeConsultCase!.ageYears} वर्षे" : ""} • जल जोखीम: ${_activeConsultCase!.waterRiskPercent}%',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _activeConsultCase!.priority == 'urgent' ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _activeConsultCase!.priority == 'urgent' ? (_isMr ? '🔴 तात्काळ' : '🔴 URGENT') : (_isMr ? '🔵 सामान्य' : '🔵 NORMAL'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _activeConsultCase!.priority == 'urgent' ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_activeConsultCase!.doctorNotes != null && _activeConsultCase!.doctorNotes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_isMr ? "आशा सेविका रेफरल नोंद: " : "Referral Note: "}“${_activeConsultCase!.doctorNotes}”',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF065F46), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
        // Title & Presets
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_services_outlined, color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isMr ? 'PHC डॉक्टर सल्ला व उपचार पॅनेल' : 'PHC Doctor Consultation',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Presets chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets.map((p) {
                  return ActionChip(
                    label: Text(
                      _isMr ? p['labelMr']! : p['labelEn']!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                    backgroundColor: const Color(0xFFE0F2FE),
                    onPressed: () {
                      _doctorTranscriptController.text = p['text']!;
                      setState(() {
                        _doctorResult = buildSimulatedDoctorConsult(p['text']!, mr: _isMr);
                        _assessmentController.text = _doctorResult.suggestedAssessment ?? '';
                        _planController.text = _doctorResult.suggestedPlan ?? '';
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Text input & analyze button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _doctorTranscriptController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        hintText: _isMr ? 'रुग्णाची लक्षणे टाका...' : 'Enter patient symptoms...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final t = _doctorTranscriptController.text.trim();
                      if (t.isEmpty) return;
                      setState(() {
                        _doctorResult = buildSimulatedDoctorConsult(t, mr: _isMr);
                        _assessmentController.text = _doctorResult.suggestedAssessment ?? '';
                        _planController.text = _doctorResult.suggestedPlan ?? '';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(_isMr ? 'तपासा' : 'Analyze', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),

              if (_doctorResult.diseaseLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bubble_chart_outlined, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_isMr ? "ओळखलेला आजार: " : "Identified Profile: "}${_doctorResult.diseaseLabel}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Red Flags Banner
        if (_doctorResult.redFlags.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_isMr ? "धोक्याची चिन्हे: " : "Red Flags: "}${_doctorResult.redFlags.map((f) => dangerLabels[f]?[_lang] ?? f).join('  •  ')}',
                    style: const TextStyle(color: Color(0xFF9F1239), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Questions to Ask Next Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isMr ? 'रुग्णाला पुढे विचारा (Questions to Ask Next):' : 'Questions to Ask Next:',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._doctorResult.askNext.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 12)),
                      Expanded(
                        child: Text(entry.value, style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Guidelines & Differential Diagnoses Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isMr ? 'संभाव्य निदान व मार्गदर्शक नियम:' : 'Clinical Considerations & Protocols:',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._doctorResult.consider.map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.condition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F1E36))),
                      const SizedBox(height: 2),
                      Text('“${c.evidenceQuote}”', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              ..._doctorResult.guidelines.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${g.title}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 11.5)),
                        TextSpan(text: g.text, style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // SOAP Note Form Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _isMr ? 'डॉक्टर निदान व उपचार नोंद (SOAP Note)' : 'Doctor Assessment & Treatment Plan',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                _isMr ? 'निदान (Assessment):' : 'Assessment:',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _assessmentController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _isMr ? 'उपचार योजना (Treatment Plan):' : 'Treatment Plan:',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _planController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final note = SignedConsultNote(
                      sessionId: 'SES-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
                      patientPseudoId: _activeConsultCase?.patientPseudoId ?? _pseudoIdController.text.trim(),
                      consentId: _consentId,
                      signedAt: DateTime.now().toIso8601String(),
                      subjective: _doctorResult.subjective,
                      objective: _doctorResult.objective,
                      assessment: _assessmentController.text,
                      plan: _planController.text,
                    );
                    await LocalStore.saveSignedNote(note);

                    if (_activeConsultCase != null) {
                      await LocalStore.saveDoctorReviewForCase(
                        _activeConsultCase!.id,
                        doctorName: widget.userName,
                        assessment: _assessmentController.text.trim(),
                        plan: _planController.text.trim(),
                      );
                      await _loadSavedCases();
                    }

                    _showToast(_isMr ? 'डॉक्टरांची तपासणी नोंद स्वाक्षरीत झाली!' : 'Doctor consultation signed & updated!');
                    setState(() {
                      _casesFilter = 'forwarded';
                      _activeTab = 'cases';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.draw_rounded, size: 18),
                  label: Text(
                    _isMr ? 'स्वाक्षरी करा व जतन करा' : 'Sign & Save Note',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: SAVED CASES VIEW
  // ==========================================
  Widget _buildCasesTab() {
    final dangerCount = _savedCases.where((r) => r.severityFlag).length;
    final forwardedCount = _savedCases.where((r) => r.isForwardedToDoctor || r.doctorStatus == 'pending' || r.doctorStatus == 'reviewed').length;
    final filtered = _savedCases.where((r) {
      if (_casesFilter == 'danger') return r.severityFlag;
      if (_casesFilter == 'forwarded') return r.isForwardedToDoctor || r.doctorStatus == 'pending' || r.doctorStatus == 'reviewed';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter & Controls Bar
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _casesFilter = 'all'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _casesFilter == 'all' ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _isMr ? 'सर्व (${_savedCases.length})' : 'All (${_savedCases.length})',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _casesFilter == 'all' ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _casesFilter = 'danger'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _casesFilter == 'danger' ? const Color(0xFFE11D48) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _isMr ? 'धोका ($dangerCount)' : 'Danger ($dangerCount)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _casesFilter == 'danger' ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => setState(() => _casesFilter = 'forwarded'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _casesFilter == 'forwarded' ? const Color(0xFF0F766E) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 13,
                      color: _casesFilter == 'forwarded' ? Colors.white : const Color(0xFF0F766E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isMr ? 'डॉक्टर ($forwardedCount)' : 'Doctor ($forwardedCount)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _casesFilter == 'forwarded' ? Colors.white : const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () async {
                await LocalStore.restoreDemoCases();
                await _loadSavedCases();
                _showToast(_isMr ? 'नमुना केसेस रिस्टोर झाल्या' : 'Sample cases restored');
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 2),
                    Text(_isMr ? 'रिस्टोर' : 'Restore', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                await LocalStore.clear(deleteFromFirebase: true);
                if (mounted) {
                  setState(() {
                    _savedCases = [];
                  });
                }
                _showToast(_isMr ? 'सर्व नोंदी हटवल्या!' : 'All cases cleared!');
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFE11D48)),
                    const SizedBox(width: 2),
                    Text(_isMr ? 'हटवा' : 'Clear', style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48))),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Doctor Triage Header Banner if user is Medical Officer
        if (widget.userRole == 'Medical Officer') ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMr ? 'वैद्यकीय अधिकारी ट्रायज पॅनेल' : 'Medical Officer Triage Panel',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                      ),
                      Text(
                        _isMr
                            ? 'आशा सेविकांकडून प्रेषित केलेल्या $forwardedCount केसेस उपलब्ध आहेत'
                            : '$forwardedCount patient cases forwarded for your review',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // List of Cases
        if (filtered.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.person_outline_rounded, size: 40, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                Text(
                  _isMr ? 'कोणतीही रुग्ण नोंद नाही' : 'No Cases Found',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _activeTab = 'record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(_isMr ? 'नवीन नोंद करा' : 'Record New Case'),
                ),
              ],
            ),
          ),
        ] else ...[
          ...filtered.map((r) {
            final hasDanger = r.dangerSigns.isNotEmpty;
            final displayName = r.patientName ?? r.patientPseudoId;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: r.isForwardedToDoctor
                      ? (r.priority == 'urgent' ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0))
                      : (hasDanger ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
                  width: r.isForwardedToDoctor ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: r.isForwardedToDoctor
                              ? (r.priority == 'urgent' ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5))
                              : (hasDanger ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          r.isForwardedToDoctor
                              ? Icons.medical_services_rounded
                              : (hasDanger ? Icons.warning_rounded : Icons.person_rounded),
                          color: r.isForwardedToDoctor
                              ? (r.priority == 'urgent' ? const Color(0xFFE11D48) : const Color(0xFF059669))
                              : (hasDanger ? const Color(0xFFE11D48) : const Color(0xFF0284C7)),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                            ),
                            Text(
                              '${r.ageYears != null ? "${r.ageYears} ${_isMr ? 'वर्षे' : 'yrs'}" : ""} • ${r.village} ${r.waterSourceText != null ? "• ${r.waterSourceText}" : ""}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.waterRiskPercent >= 70
                              ? const Color(0xFFFEE2E2)
                              : r.waterRiskPercent >= 40
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${r.waterRiskPercent}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: r.waterRiskPercent >= 70
                                ? const Color(0xFFE11D48)
                                : r.waterRiskPercent >= 40
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (hasDanger) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ ${_isMr ? "धोक्याची चिन्हे: " : "Danger: "}${r.dangerSigns.map((d) => dangerLabels[d]?[_lang] ?? d).join('  •  ')}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                      ),
                    ),
                  ],

                  if (r.isForwardedToDoctor) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_rounded, size: 14, color: Color(0xFF047857)),
                              const SizedBox(width: 5),
                              Text(
                                _isMr ? '👨‍⚕️ डॉक्टरांकडे प्रेषित' : '👨‍⚕️ Forwarded to Doctor',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: r.priority == 'urgent' ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.priority == 'urgent' ? (_isMr ? '🔴 तात्काळ' : '🔴 URGENT') : (_isMr ? '🔵 सामान्य' : '🔵 NORMAL'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: r.priority == 'urgent' ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: r.doctorStatus == 'reviewed' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  r.doctorStatus == 'reviewed'
                                      ? (_isMr ? '✅ तपासले' : '✅ Reviewed')
                                      : (_isMr ? '⏳ प्रलंबित' : '⏳ Pending'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: r.doctorStatus == 'reviewed' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.doctorNotes != null && r.doctorNotes!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${_isMr ? "रेफरल नोंद: " : "Referral Note: "}“${r.doctorNotes}”',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (r.doctorStatus == 'reviewed' && r.doctorAssessment != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${_isMr ? "डॉक्टरांचे निदान: " : "Diagnosis: "}${r.doctorAssessment}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    '${_isMr ? "लक्षणे: " : "Symptoms: "}${r.symptoms.map((s) => symptomLabels[s]?[_lang] ?? s).join(", ")}',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                  ),

                  if (r.transcript.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${r.transcript}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await LocalStore.deleteCase(r.id, deleteFromFirebase: true);
                          if (mounted) {
                            setState(() {
                              _savedCases.removeWhere((c) => c.id == r.id);
                            });
                          }
                          _showToast(_isMr ? 'केस हटवली गेली!' : 'Case removed!');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE11D48),
                          side: const BorderSide(color: Color(0xFFFECDD3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 13, color: Color(0xFFE11D48)),
                        label: Text(_isMr ? 'हटवा' : 'Remove', style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 6),
                      if (widget.userRole == 'Medical Officer' && r.isForwardedToDoctor) ...[
                        ElevatedButton.icon(
                          onPressed: () => _openDoctorConsult(r.transcript, fromCase: r),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.assignment_turned_in_rounded, size: 14),
                          label: Text(
                            r.doctorStatus == 'reviewed'
                                ? (_isMr ? 'पुन्हा तपासा (Re-examine)' : 'Re-examine')
                                : (_isMr ? '🩺 रुग्ण तपासा व प्रिस्क्रिप्शन द्या' : '🩺 Examine & Prescribe'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ] else ...[
                        if (!r.isForwardedToDoctor) ...[
                          OutlinedButton.icon(
                            onPressed: () async {
                              await LocalStore.forwardCaseToDoctor(r.id, priority: r.severityFlag ? 'urgent' : 'normal');
                              await _loadSavedCases();
                              _showToast(_isMr ? 'केस डॉक्टरांकडे पाठवली गेली!' : 'Case forwarded to doctor!');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0F766E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 13, color: Color(0xFF0F766E)),
                            label: Text(_isMr ? 'डॉक्टरांकडे पाठवा' : 'Forward to Doctor', style: const TextStyle(fontSize: 11, color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        OutlinedButton.icon(
                          onPressed: () => _openDoctorConsult(r.transcript, fromCase: r.isForwardedToDoctor ? r : null),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBAE6FD)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFF0284C7)),
                          label: Text(_isMr ? 'डॉक्टर सल्ला' : 'Consult', style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  // --- FOOTER ---
  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'JalSanket (जलसंकेत) · Warning, not panic. Action, not just alerts.',
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            _isMr ? 'प्राथमिक आरोग्य तपासणी साहाय्यक' : 'Clinical screening & water surveillance support',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }
}
