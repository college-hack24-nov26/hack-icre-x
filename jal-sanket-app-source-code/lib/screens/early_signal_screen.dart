import 'package:flutter/material.dart';

class EarlySignalScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const EarlySignalScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  State<EarlySignalScreen> createState() => _EarlySignalScreenState();
}

class _EarlySignalScreenState extends State<EarlySignalScreen> {
  int? _selectedBarIndex;
  int? _selectedCurveIndex;

  // Rainfall data for 7 days
  final List<Map<String, dynamic>> _rainfallData = [
    {'day': 'Today', 'value': 0.2},
    {'day': '+1d', 'value': 1.1},
    {'day': '+2d', 'value': 0.0},
    {'day': '+3d', 'value': 0.0},
    {'day': '+4d', 'value': 2.0},
    {'day': '+5d', 'value': 1.1},
    {'day': '+6d', 'value': 1.1},
  ];

  // Risk projection data for 7 days
  final List<Map<String, dynamic>> _riskCurveData = [
    {'day': 'Today', 'score': 25},
    {'day': '+1d', 'score': 28},
    {'day': '+2d', 'score': 32},
    {'day': '+3d', 'score': 38},
    {'day': '+4d', 'score': 45},
    {'day': '+5d', 'score': 48},
    {'day': '+6d', 'score': 52},
  ];

  void _showActionWindowDetails() {
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Action Window Protocol',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      Text(
                        'Days +1 to +4 Pre-Emptive Chlorination',
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
            _buildDetailRow(
              'Forecast Trigger',
              'Day +4 heavy rain (2.0 mm) will cause runoff into Pimpri catchment area.',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Target Sources',
              'Pimpri Well 1 (Current Risk 25) & Pimpri Handpump (Risk 15).',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Required Bleaching Powder',
              '2.5 kg (33% available chlorine) per well before heavy rain on Day +4.',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              'Field ASHA Action',
              'Alert Gram Panchayat water operator. Distribute chlorine tablets to 220 households in Pimpri.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chlorination task dispatched to Jal Suraksha team!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                label: const Text(
                  'Dispatch Preventive Chlorination',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showStageDetails(String title, String status, String description, IconData icon, Color color) {
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
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: color,
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
            Text(
              description,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFFBAE6FD)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1E36),
            height: 1.35,
          ),
        ),
      ],
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
                    // 2. Rainfall Forecast (Open-Meteo)
                    _buildRainfallCard(),

                    const SizedBox(height: 14),

                    // 3. Projected Water Risk Curve (Dark Midnight Card)
                    _buildProjectedRiskCard(),

                    const SizedBox(height: 14),

                    // 4. Action Window Opportunity
                    _buildActionWindowCard(),

                    const SizedBox(height: 14),

                    // 5. Three Cascade Stages
                    _buildCascadeStagesCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Top Radiant Header Card
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
            borderRadius: BorderRadius.circular(20),
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
                  'Early Signal (7 Days)',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '7-DAY MULTI-SIGNAL RISK',
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

          // Droplet graphic
          Image.asset(
            'assets/images/water_drop_ripple.png',
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.water_drop,
              color: Color(0xFF38BDF8),
              size: 28,
            ),
          ),

          const SizedBox(width: 8),

          // LIVE pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6EE7B7),
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

  // 2. Rainfall Forecast (Open-Meteo)
  Widget _buildRainfallCard() {
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
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloudy_snowing,
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
                      'Rainfall Forecast (Open-Meteo)',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F1E36),
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Estimated rainfall for next 7 days',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'mm / 24h',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar Chart with custom layout
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-axis labels
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('2.2', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text('1.65', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text('1.1', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text('0.55', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Text('0', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Chart Columns Area with horizontal gridlines
                Expanded(
                  child: Stack(
                    children: [
                      // Gridlines
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (index) => Container(
                              height: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                          ),
                        ),
                      ),

                      // Bars Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_rainfallData.length, (idx) {
                          final item = _rainfallData[idx];
                          final double val = item['value'] as double;
                          final double maxVal = 2.2;
                          final double barHeightFraction = (val / maxVal).clamp(0.0, 1.0);
                          final double actualBarHeight = barHeightFraction * 95;
                          final bool isSelected = _selectedBarIndex == idx;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBarIndex = _selectedBarIndex == idx ? null : idx;
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Value label above bar
                                Text(
                                  val.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: val > 0.0 ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Bar
                                Container(
                                  width: 32,
                                  height: actualBarHeight < 5 && val > 0.0 ? 5 : actualBarHeight,
                                  decoration: BoxDecoration(
                                    gradient: val > 0.0
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF38BDF8),
                                              Color(0xFF0284C7),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                    color: val == 0.0 ? Colors.transparent : null,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                    border: isSelected
                                        ? Border.all(color: const Color(0xFF0369A1), width: 2)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // X-axis day labels
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _rainfallData.map((item) {
                return Text(
                  item['day'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Projected Water Risk Curve (Dark Midnight Card)
  Widget _buildProjectedRiskCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1A2E).withValues(alpha: 0.4),
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
                      'Projected Water Risk Curve',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      '7-day risk projection based on rainfall + sources',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF381A22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF632532)),
                ),
                child: const Text(
                  'Red Line ≥ 60',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFB7185),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Custom Line Chart Canvas
          SizedBox(
            height: 160,
            child: Row(
              children: [
                // Y-axis labels
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('100', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('75', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('50', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('25', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Text('0', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Line graph area
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: RiskCurveChartPainter(
                      data: _riskCurveData,
                      selectedIndex: _selectedCurveIndex,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // X-axis labels
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _riskCurveData.map((item) {
                return Text(
                  item['day'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Action Window Opportunity Card
  Widget _buildActionWindowCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Exclamation icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Action Window Opportunity',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Estimated risk could reach 2% around day +5. Action window: test and chlorinate sources before then.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // View Details Button
          InkWell(
            onTap: _showActionWindowDetails,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: Color(0xFF92400E),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Three Cascade Stages Card
  Widget _buildCascadeStagesCard() {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Three Cascade Stages',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F1E36),
                    ),
                  ),
                  Text(
                    'Current risk assessment based on multiple signals',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stage 1: Flood Detected
          _buildStageItem(
            stepNumber: '1',
            numberBgColor: const Color(0xFF0084FF),
            icon: Icons.water_drop_outlined,
            iconColor: const Color(0xFF0284C7),
            iconBgColor: const Color(0xFFDDF2FD),
            cardBgColor: const Color(0xFFE5F3FC),
            borderColor: const Color(0xFFBAE6FD),
            title: 'Flood Detected',
            subtitle: 'No flood flag currently active',
            statusText: 'Normal',
            statusDotColor: const Color(0xFF10B981),
            statusTextColor: const Color(0xFF059669),
            statusBgColor: const Color(0xFFDCFCE7),
            onTap: () {
              _showStageDetails(
                'Flood Detection Telemetry',
                'Normal',
                'Satellite river level gauges and runoff sensors in Koyana/Krishna basin report standard baseline discharge. No upstream overflow detected.',
                Icons.water_drop,
                const Color(0xFF0284C7),
              );
            },
          ),

          const SizedBox(height: 10),

          // Stage 2: Sources At Risk
          _buildStageItem(
            stepNumber: '2',
            numberBgColor: const Color(0xFFF59E0B),
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD97706),
            iconBgColor: const Color(0xFFFEF3C7),
            cardBgColor: const Color(0xFFFEF6EB),
            borderColor: const Color(0xFFFDE68A),
            title: 'Sources At Risk',
            subtitle: '0 of 6 sources amber or red',
            statusText: 'Watch',
            statusDotColor: const Color(0xFFF59E0B),
            statusTextColor: const Color(0xFFD97706),
            statusBgColor: const Color(0xFFFEF3C7),
            onTap: () {
              _showStageDetails(
                'Water Sources Status',
                'Watch (Safe for now)',
                'Telemetry from all 6 catalog points (Pimpri Well 1, Handpump, Kasba Spring, Kasba Tap, Wadi Well, Wadi Handpump) currently within safe limits, but Pimpri Well 1 is flagged for preventive pre-chlorination.',
                Icons.warning_amber_rounded,
                const Color(0xFFD97706),
              );
            },
          ),

          const SizedBox(height: 10),

          // Stage 3: Cases Likely
          _buildStageItem(
            stepNumber: '3',
            numberBgColor: const Color(0xFFF43F5E),
            icon: Icons.people_alt_outlined,
            iconColor: const Color(0xFFE11D48),
            iconBgColor: const Color(0xFFFEE2E2),
            cardBgColor: const Color(0xFFFEEBED),
            borderColor: const Color(0xFFFECDD3),
            title: 'Cases Likely',
            subtitle: 'No cluster yet: surveillance ongoing',
            statusText: 'Low',
            statusDotColor: const Color(0xFF10B981),
            statusTextColor: const Color(0xFF059669),
            statusBgColor: const Color(0xFFDCFCE7),
            onTap: () {
              _showStageDetails(
                'Syndromic Case Surveillance',
                'Low Risk',
                'ASHA portal syndromic reporting shows only 3 mild diarrhoea/fever cases in Pimpri over 3 days (normal threshold = 2.0 cases, p=0.325). No secondary outbreak clusters detected.',
                Icons.people_alt_rounded,
                const Color(0xFFE11D48),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required String stepNumber,
    required Color numberBgColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusDotColor,
    required Color statusTextColor,
    required Color statusBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Number pill
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: numberBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Icon circle
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 18),
            ),

            const SizedBox(width: 10),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F1E36),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: statusTextColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the Projected Water Risk Curve (Dark Midnight Card)
class RiskCurveChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final int? selectedIndex;

  RiskCurveChartPainter({
    required this.data,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Grid lines: 5 horizontal lines (100, 75, 50, 25, 0)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final y = height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Vertical grid lines
    final double stepX = width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // Dashed Threshold line at 60
    final double thresholdY = height * (1.0 - (60.0 / 100.0));
    final dashPaint = Paint()
      ..color = const Color(0xFFEF4444).withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double curX = 0;
    const double dashW = 6;
    const double spaceW = 4;
    while (curX < width) {
      canvas.drawLine(
        Offset(curX, thresholdY),
        Offset((curX + dashW).clamp(0, width), thresholdY),
        dashPaint,
      );
      curX += dashW + spaceW;
    }

    // Text "Red 60" label on the right side
    final redTextPainter = TextPainter(
      text: const TextSpan(
        text: 'Red 60',
        style: TextStyle(
          color: Color(0xFFF87171),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    redTextPainter.paint(
      canvas,
      Offset(width - redTextPainter.width - 2, thresholdY - 14),
    );

    // Calculate curve points
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final int score = data[i]['score'] as int;
      final double x = i * stepX;
      final double y = height * (1.0 - (score / 100.0));
      points.add(Offset(x, y));
    }

    // Gradient Area under the curve
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(points.last.dx, height);
    path.lineTo(points.first.dx, height);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFFEF4444).withValues(alpha: 0.35),
          const Color(0xFFEF4444).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, fillPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      strokePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(strokePath, linePaint);

    // Points and numerical labels
    final dotPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final int score = data[i]['score'] as int;

      // Draw dot
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 5.0, ringPaint);

      // Label above dot
      final tp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pt.dx - (tp.width / 2), pt.dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant RiskCurveChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.data != data;
  }
}
