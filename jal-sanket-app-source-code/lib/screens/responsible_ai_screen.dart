import 'package:flutter/material.dart';

class ResponsibleAIScreen extends StatelessWidget {
  final String userName;
  final String userId;

  const ResponsibleAIScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildTopHeader(context),

            const SizedBox(height: 10),

            // 9 Guardrail Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _buildGuardrailCard(
                    number: '01',
                    title: 'Gemini 1.5 Flash Engine',
                    badgeText: 'REGEX FALLBACK MODE',
                    badgeBgColor: const Color(0xFF4C1D95),
                    badgeTextColor: const Color(0xFFDDD6FE),
                    description: 'Runs in rule-based regex mode. To activate Gemini AI, add your VITE_GEMINI_API_KEY in .env (get a free key at ai.google.dev).',
                    gradientColors: [const Color(0xFF6B21A8), const Color(0xFF4C1D95)],
                    watermarkIcon: Icons.auto_awesome,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '02',
                    title: 'What the app does',
                    description: 'Reads colours from your photo, scores risk from visible factors, finds unusual case counts, and extracts fields from what you said or typed using AI + rule-based fallback.',
                    gradientColors: [const Color(0xFF0369A1), const Color(0xFF075985)],
                    watermarkIcon: Icons.article_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '03',
                    title: 'Gemini AI extraction',
                    badgeText: 'ENABLED',
                    hasDot: true,
                    badgeBgColor: const Color(0xFF064E3B),
                    badgeTextColor: const Color(0xFF6EE7B7),
                    description: 'When enabled, Gemini 1.5 Flash (temperature=0) extracts structured patient data from Marathi/English transcripts, returning JSON with confidence per field. Rule-based regex is always the fallback.',
                    gradientColors: [const Color(0xFF047857), const Color(0xFF065F46)],
                    watermarkIcon: Icons.hub_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '04',
                    title: 'Doctor AI panel',
                    description: 'Generates "Ask next", differential suggestions, and draft notes from the transcript. All suggestions are framed as "for clinician consideration". Doctor decides all treatment.',
                    gradientColors: [const Color(0xFFC2410C), const Color(0xFF9A3412)],
                    watermarkIcon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '05',
                    title: 'What it does NOT do',
                    description: 'Never diagnoses, never prescribes, never says water is safe to drink without boiling. Sensors and strips are screening signals, not lab results.',
                    gradientColors: [const Color(0xFFBE123C), const Color(0xFF9F1239)],
                    watermarkIcon: Icons.block_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '06',
                    title: 'Human in the loop',
                    description: 'Nothing is saved until the health worker confirms. Every AI-extracted field shows confidence. Fallback to manual form is always available.',
                    gradientColors: [const Color(0xFF3730A3), const Color(0xFF312E81)],
                    watermarkIcon: Icons.groups_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '07',
                    title: 'Data minimisation',
                    description: 'No patient names in analytics or reports. Photos stay on the phone. Consent is asked before recording. Raw audio is not stored.',
                    gradientColors: [const Color(0xFF0F766E), const Color(0xFF115E59)],
                    watermarkIcon: Icons.storage_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '08',
                    title: 'Danger signs',
                    description: 'Fixed deterministic clinical rules (not generative AI) trigger the urgent referral card. Verifiable against standard IMNCI/WHO guidelines.',
                    gradientColors: [const Color(0xFFBE185D), const Color(0xFF9D174D)],
                    watermarkIcon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildGuardrailCard(
                    number: '09',
                    title: 'Offline-first',
                    description: 'All data is saved locally first. No loss if network is unavailable. Reports sync automatically when network returns.',
                    gradientColors: [const Color(0xFF5B21B6), const Color(0xFF4C1D95)],
                    watermarkIcon: Icons.cloud_sync_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF0369A1),
            Color(0xFF075985),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Responsible AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'RESPONSIBLE AI & ETHICS GUARDRAILS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBAE6FD),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Shield icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4A6E).withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardrailCard({
    required String number,
    required String title,
    String? badgeText,
    bool hasDot = false,
    Color? badgeBgColor,
    Color? badgeTextColor,
    required String description,
    required List<Color> gradientColors,
    required IconData watermarkIcon,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Right watermark icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Opacity(
                opacity: 0.16,
                child: Icon(
                  watermarkIcon,
                  size: 110,
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with step number
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBgColor ?? Colors.black.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasDot) ...[
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: badgeTextColor ?? Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: badgeTextColor ?? Colors.white,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
