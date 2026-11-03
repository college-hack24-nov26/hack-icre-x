/// ═════════════════════════════════════════════════════════════════════════════
///  JalSanket — Voice AI & Clinical Triage Module
///
///  Exportable, plug-and-play Flutter module for:
///   • Marathi & English Voice-to-Text recording (speech_to_text)
///   • Clinical symptom & patient entity extraction (Gemini 1.5/2.5/3.5 Flash AI)
///   • Offline-first rule-based regex fallback (LocalExtractor)
///   • Simulated Doctor consultation & triage prescription engine
///   • Local offline case history storage (LocalStore via SharedPreferences)
/// ═════════════════════════════════════════════════════════════════════════════

library voice_module;

export 'voice_screen.dart';
export 'voice_engine.dart';
export 'gemini_service.dart';

