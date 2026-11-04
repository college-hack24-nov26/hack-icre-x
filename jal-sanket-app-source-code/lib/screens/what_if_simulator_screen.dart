import 'package:flutter/material.dart';

class WhatIfSimulatorScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const WhatIfSimulatorScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  State<WhatIfSimulatorScreen> createState() => _WhatIfSimulatorScreenState();
}

class _WhatIfSimulatorScreenState extends State<WhatIfSimulatorScreen> {
  // Intervention efficacy: 0.0 to 1.0 (default 0.40)
  double _efficacy = 0.40;
  String _selectedMetric = 'Cases (SIR)';

  // Calculate dynamic values based on efficacy
  int get _noInterventionPeak => 118;

  int get _withInterventionPeak {
    // At efficacy 0.0 -> 118
    // At efficacy 0.40 -> 28
    // At efficacy 0.80 -> 14
    // At efficacy 1.0 -> 8
    final peak = 118 * (1.0 - (_efficacy * 0.763));
    return peak.round().clamp(5, 118);
  }

  int get _casesAvoided {
    return (_noInterventionPeak - _withInterventionPeak).clamp(0, 118);
  }

  int get _totalBaseCases => 109;

  void _showModelInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF0284C7),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SIR Epidemiological Model',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      Text(
                        'Differential equations for waterborne spread',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 14),
            const Text(
              'About the Simulation:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The SIR model divides the village population into three compartments:\n'
              '• Susceptible (S): 220 households (approx 1,100 individuals)\n'
              '• Infectious (I): Active acute diarrhoeal cases shedding pathogens\n'
              '• Recovered / Immune (R): Treated with ORS & zinc\n\n'
              'Intervention Efficacy directly lowers the effective transmission parameter (β) through well shock-chlorination, chlorine tablet distribution, and safe water boiling advisories.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Radiant Header
            _buildTopHeaderCard(),

            const SizedBox(height: 10),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // 2. Intervention Efficacy Slider Card
                    _buildSliderCard(),

                    const SizedBox(height: 14),

                    // 3. Projected Outbreak Curve (Dark Midnight Card)
                    _buildOutbreakCurveCard(),

                    const SizedBox(height: 14),

                    // 4. Estimated Cases Avoided Card
                    _buildCasesAvoidedCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top Header Card
  Widget _buildTopHeaderCard() {
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
          // Back button
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
          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'What-if simulator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'SIR EPIDEMIOLOGICAL SIMULATOR',
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

          // DEMO MODEL pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF38BDF8),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.science_rounded,
                  color: Color(0xFF38BDF8),
                  size: 15,
                ),
                SizedBox(width: 6),
                Text(
                  'DEMO MODEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Intervention Efficacy Slider Card
  Widget _buildSliderCard() {
    final int percentVal = (_efficacy * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with bar chart icon and info button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PIMPRI: 14-DAY SIR OUTBREAK ESTIMATE',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1E36),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Simulate the impact of chlorination and household ORS',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showModelInfoDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Intervention Efficacy Title + Current Value badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Intervention Efficacy',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1E36),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '(Chlorinate wells + ORS distribution + boiling notice)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$percentVal%',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const Text(
                      'Current value',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Custom styled slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF0284C7),
              inactiveTrackColor: const Color(0xFFE0F2FE),
              thumbColor: Colors.white,
              thumbShape: const _CustomRoundSliderThumb(radius: 12),
              overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: _efficacy,
              min: 0.0,
              max: 0.90,
              onChanged: (val) {
                setState(() {
                  _efficacy = val;
                });
              },
            ),
          ),

          // 3 Tick labels below slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _efficacy = 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('0%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                      Text('(No Action)', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _efficacy = 0.40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Text('40%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                      Text('(Standard)', style: TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _efficacy = 0.80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('80%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      Text('(Rapid Surge)', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Projected Outbreak Curve (Dark Midnight Card)
  Widget _buildOutbreakCurveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1A2E).withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B1D28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFF43F5E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Projected Outbreak Curve',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '14-day SIR model projection based on selected intervention',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Dropdown button for metric
              PopupMenuButton<String>(
                onSelected: (val) {
                  setState(() {
                    _selectedMetric = val;
                  });
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'Cases (SIR)', child: Text('Cases (SIR)')),
                  PopupMenuItem(value: 'Attack Rate (%)', child: Text('Attack Rate (%)')),
                  PopupMenuItem(value: 'R_eff (Repro. No.)', child: Text('R_eff (Repro. No.)')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedMetric,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart with Y-axis label, ticks, and dual curves
          SizedBox(
            height: 175,
            child: Row(
              children: [
                // Rotated "Estimated cases" label
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Estimated cases',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                // Y-axis ticks (120, 90, 60, 30, 0)
                SizedBox(
                  width: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('120', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('90', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('60', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('30', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('0', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Canvas Area
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: OutbreakCurvePainter(
                      efficacy: _efficacy,
                      noInterventionPeak: _noInterventionPeak,
                      withInterventionPeak: _withInterventionPeak,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // X-axis Day labels (Day 0, Day 7, Day 14)
          Padding(
            padding: const EdgeInsets.only(left: 48, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Day 0',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Day 7',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Day 14',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 14),

          // Legend row
          Row(
            children: [
              // No Intervention
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'No Intervention',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF87171),
                          ),
                        ),
                        Text(
                          'Rapid increase in cases',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 28,
                color: const Color(0xFF1E293B),
              ),

              const SizedBox(width: 12),

              // With Intervention
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'With Intervention',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        Text(
                          'Flattened outbreak curve',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Estimated Cases Avoided Card
  Widget _buildCasesAvoidedCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background droplet art on bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(22)),
              child: Opacity(
                opacity: 0.85,
                child: Image.asset(
                  'assets/images/water_drop_ripple.png',
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Green circular checkmark
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Estimated Cases Avoided',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                    ),

                    // Pill badge: e.g. "88 of 109"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$_casesAvoided ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            TextSpan(
                              text: 'OF $_totalBaseCases',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: const Text(
                    'Early chlorination and household ORS distribution drastically flatten the outbreak transmission curve. (SIR mathematical parameters are demo estimates).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Slider Thumb with cyan center dot
class _CustomRoundSliderThumb extends SliderComponentShape {
  final double radius;

  const _CustomRoundSliderThumb({this.radius = 12});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer white circle
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center, radius, shadowPaint);

    canvas.drawCircle(center, radius, whitePaint);

    // Inner bright cyan-blue dot
    final cyanPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, cyanPaint);
  }
}

// Custom Painter for Outbreak Curve (2 lines: Red exponential and Green flattened)
class OutbreakCurvePainter extends CustomPainter {
  final double efficacy;
  final int noInterventionPeak;
  final int withInterventionPeak;

  OutbreakCurvePainter({
    required this.efficacy,
    required this.noInterventionPeak,
    required this.withInterventionPeak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 1. Gridlines (5 horizontal lines for 120, 90, 60, 30, 0)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final y = height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Vertical grid lines
    const int numVerticals = 5;
    for (int i = 0; i < numVerticals; i++) {
      final x = width * (i / (numVerticals - 1));
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // Max cases on Y-axis = 120
    const double maxCases = 120.0;

    // 2. Data points for No Intervention (Red curve)
    // 7 sample points from Day 0 to Day 14
    final List<double> redScores = [3, 8, 16, 28, 46, 82, noInterventionPeak.toDouble()];
    final List<Offset> redPoints = [];
    for (int i = 0; i < redScores.length; i++) {
      final double x = width * (i / (redScores.length - 1));
      final double y = height * (1.0 - (redScores[i] / maxCases)).clamp(0.0, height);
      redPoints.add(Offset(x, y));
    }

    // Red Gradient Fill
    final redPath = Path();
    redPath.moveTo(redPoints.first.dx, redPoints.first.dy);
    for (int i = 1; i < redPoints.length; i++) {
      final prev = redPoints[i - 1];
      final cur = redPoints[i];
      final midX = (prev.dx + cur.dx) / 2;
      redPath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    redPath.lineTo(redPoints.last.dx, height);
    redPath.lineTo(redPoints.first.dx, height);
    redPath.close();

    final redFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.35),
          const Color(0xFFEF4444).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(redPath, redFillPaint);

    // Red Stroke Path
    final redStrokePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final redStrokePath = Path();
    redStrokePath.moveTo(redPoints.first.dx, redPoints.first.dy);
    for (int i = 1; i < redPoints.length; i++) {
      final prev = redPoints[i - 1];
      final cur = redPoints[i];
      final midX = (prev.dx + cur.dx) / 2;
      redStrokePath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    canvas.drawPath(redStrokePath, redStrokePaint);

    // Draw Red Dots
    final redDotPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    final whiteRingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in redPoints) {
      canvas.drawCircle(pt, 4.5, redDotPaint);
      canvas.drawCircle(pt, 4.5, whiteRingPaint);
    }

    // Red Peak Badge at Day 14
    final redPeakPt = redPoints.last;
    final redBadgeBgPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    final redBadgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(redPeakPt.dx - 12, redPeakPt.dy - 16), width: 28, height: 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(redBadgeRect, redBadgeBgPaint);

    final redTextPainter = TextPainter(
      text: TextSpan(
        text: '$noInterventionPeak',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    redTextPainter.paint(
      canvas,
      Offset(redBadgeRect.center.dx - (redTextPainter.width / 2), redBadgeRect.center.dy - (redTextPainter.height / 2)),
    );

    // 3. Data points for With Intervention (Green curve)
    final double gPeak = withInterventionPeak.toDouble();
    final List<double> greenScores = [
      3,
      4 + (gPeak * 0.05),
      6 + (gPeak * 0.15),
      10 + (gPeak * 0.30),
      14 + (gPeak * 0.50),
      20 + (gPeak * 0.75),
      gPeak,
    ];
    final List<Offset> greenPoints = [];
    for (int i = 0; i < greenScores.length; i++) {
      final double x = width * (i / (greenScores.length - 1));
      final double y = height * (1.0 - (greenScores[i] / maxCases)).clamp(0.0, height);
      greenPoints.add(Offset(x, y));
    }

    // Green Gradient Fill
    final greenPath = Path();
    greenPath.moveTo(greenPoints.first.dx, greenPoints.first.dy);
    for (int i = 1; i < greenPoints.length; i++) {
      final prev = greenPoints[i - 1];
      final cur = greenPoints[i];
      final midX = (prev.dx + cur.dx) / 2;
      greenPath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    greenPath.lineTo(greenPoints.last.dx, height);
    greenPath.lineTo(greenPoints.first.dx, height);
    greenPath.close();

    final greenFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.35),
          const Color(0xFF10B981).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(greenPath, greenFillPaint);

    // Green Stroke Path
    final greenStrokePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final greenStrokePath = Path();
    greenStrokePath.moveTo(greenPoints.first.dx, greenPoints.first.dy);
    for (int i = 1; i < greenPoints.length; i++) {
      final prev = greenPoints[i - 1];
      final cur = greenPoints[i];
      final midX = (prev.dx + cur.dx) / 2;
      greenStrokePath.cubicTo(midX, prev.dy, midX, cur.dy, cur.dx, cur.dy);
    }
    canvas.drawPath(greenStrokePath, greenStrokePaint);

    // Draw Green Dots
    final greenDotPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    for (final pt in greenPoints) {
      canvas.drawCircle(pt, 4.5, greenDotPaint);
      canvas.drawCircle(pt, 4.5, whiteRingPaint);
    }

    // Green Peak Badge at Day 14
    final greenPeakPt = greenPoints.last;
    final greenBadgeBgPaint = Paint()
      ..color = const Color(0xFF059669)
      ..style = PaintingStyle.fill;
    final greenBadgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(greenPeakPt.dx - 12, greenPeakPt.dy - 16), width: 28, height: 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(greenBadgeRect, greenBadgeBgPaint);

    final greenTextPainter = TextPainter(
      text: TextSpan(
        text: '$withInterventionPeak',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    greenTextPainter.paint(
      canvas,
      Offset(greenBadgeRect.center.dx - (greenTextPainter.width / 2), greenBadgeRect.center.dy - (greenTextPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant OutbreakCurvePainter oldDelegate) {
    return oldDelegate.efficacy != efficacy ||
        oldDelegate.withInterventionPeak != withInterventionPeak ||
        oldDelegate.noInterventionPeak != noInterventionPeak;
  }
}
