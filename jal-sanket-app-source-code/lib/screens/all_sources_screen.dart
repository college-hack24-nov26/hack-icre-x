import 'package:flutter/material.dart';
import 'source_passport_dialog.dart';

class WaterSourceItem {
  final String id;
  final String name;
  final String village;
  final String cleanedAgo;
  final int riskScore;
  final String status; // 'At Risk', 'Safe', 'Contaminated'
  final String type; // 'Open Well', 'Borewell Handpump', 'Natural Spring', 'Piped Tap'
  final double ph;
  final double turbidity;
  final int tds;

  WaterSourceItem({
    required this.id,
    required this.name,
    required this.village,
    required this.cleanedAgo,
    required this.riskScore,
    required this.status,
    required this.type,
    required this.ph,
    required this.turbidity,
    required this.tds,
  });
}

class AllSourcesScreen extends StatefulWidget {
  final String userName;
  final String userId;

  const AllSourcesScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
  });

  @override
  State<AllSourcesScreen> createState() => _AllSourcesScreenState();
}

class _AllSourcesScreenState extends State<AllSourcesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'risk'; // 'risk' or 'alpha'

  final List<WaterSourceItem> _allSources = [
    WaterSourceItem(
      id: '1',
      name: 'Pimpri Well 1',
      village: 'Pimpri',
      cleanedAgo: 'Cleaned 45d ago',
      riskScore: 25,
      status: 'At Risk',
      type: 'Open Dug Well',
      ph: 7.9,
      turbidity: 4.8,
      tds: 520,
    ),
    WaterSourceItem(
      id: '2',
      name: 'Pimpri Handpump',
      village: 'Pimpri',
      cleanedAgo: 'Cleaned 12d ago',
      riskScore: 15,
      status: 'At Risk',
      type: 'Deep Borewell Handpump',
      ph: 7.6,
      turbidity: 3.2,
      tds: 410,
    ),
    WaterSourceItem(
      id: '3',
      name: 'Kasba Spring',
      village: 'Kasba',
      cleanedAgo: 'Cleaned 20d ago',
      riskScore: 0,
      status: 'Safe',
      type: 'Perennial Mountain Spring',
      ph: 7.2,
      turbidity: 0.8,
      tds: 210,
    ),
    WaterSourceItem(
      id: '4',
      name: 'Kasba Tap',
      village: 'Kasba',
      cleanedAgo: 'Cleaned 8d ago',
      riskScore: 0,
      status: 'Safe',
      type: 'Gram Panchayat Piped Standpost',
      ph: 7.1,
      turbidity: 0.6,
      tds: 240,
    ),
    WaterSourceItem(
      id: '5',
      name: 'Wadi Well',
      village: 'Wadi',
      cleanedAgo: 'Cleaned 15d ago',
      riskScore: 0,
      status: 'Safe',
      type: 'Community Concrete Well',
      ph: 7.3,
      turbidity: 1.1,
      tds: 290,
    ),
    WaterSourceItem(
      id: '6',
      name: 'Wadi Handpump',
      village: 'Wadi',
      cleanedAgo: 'Cleaned 10d ago',
      riskScore: 0,
      status: 'Safe',
      type: 'Solar Powered Submersible Tap',
      ph: 7.2,
      turbidity: 0.9,
      tds: 270,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WaterSourceItem> _getFilteredAndSortedSources() {
    final query = _searchController.text.trim().toLowerCase();

    List<WaterSourceItem> list = _allSources.where((source) {
      if (query.isEmpty) return true;
      return source.name.toLowerCase().contains(query) ||
          source.village.toLowerCase().contains(query) ||
          source.type.toLowerCase().contains(query);
    }).toList();

    if (_selectedSort == 'risk') {
      list.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    return list;
  }

  void _showSourceDetailsModal(WaterSourceItem source) {
    SourcePassportSheet.show(
      context,
      sourceName: source.name,
      village: source.village,
      nodeId: source.id,
      totalScore: source.riskScore,
      status: source.status,
      confidencePercent: source.riskScore > 0 ? 25 : 95,
      cleaningGapDays: int.tryParse(source.cleanedAgo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSources = _getFilteredAndSortedSources();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Radiant Header
            _buildTopHeaderCard(),

            const SizedBox(height: 12),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    // 2. Search & Filter Bar
                    _buildSearchBar(),

                    const SizedBox(height: 12),

                    // 3. Sorting Tabs (Highest Risk First / Alphabetical)
                    _buildSortingTabs(),

                    const SizedBox(height: 14),

                    // 4. List of Water Source Cards
                    ...filteredSources.map((source) => _buildSourceCard(source)),

                    if (filteredSources.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: const [
                            Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No matching water sources found',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(22),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
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
                  'All Sources',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '6 WATER POINTS CATALOG',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBAE6FD),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Water Droplet Art
          CustomPaint(
            size: const Size(44, 44),
            painter: HeaderWaterDropArtPainter(),
          ),
        ],
      ),
    );
  }

  // 2. Search & Filter Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Color(0xFF64748B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search sources by name or village...',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Icon(Icons.cancel, size: 18, color: Color(0xFF94A3B8)),
            ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Sorting Tabs
  Widget _buildSortingTabs() {
    return Row(
      children: [
        // Highest Risk First
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedSort = 'risk'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _selectedSort == 'risk'
                    ? const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      )
                    : null,
                color: _selectedSort == 'risk' ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSort == 'risk'
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: _selectedSort == 'risk'
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: _selectedSort == 'risk' ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Highest Risk First',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _selectedSort == 'risk' ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Alphabetical (A - Z)
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _selectedSort = 'alpha'),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _selectedSort == 'alpha'
                    ? const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                      )
                    : null,
                color: _selectedSort == 'alpha' ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSort == 'alpha'
                      ? const Color(0xFF0284C7)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: _selectedSort == 'alpha'
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sort_by_alpha_rounded,
                    size: 16,
                    color: _selectedSort == 'alpha' ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Alphabetical (A - Z)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _selectedSort == 'alpha' ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. Source Card Item
  Widget _buildSourceCard(WaterSourceItem source) {
    Color cardBg;
    Color borderColor;
    Color scoreColor;
    Color ringTrackColor;
    Color ringProgressColor;
    Color statusTagBg;
    Color statusTagText;
    Color statusDotColor;

    if (source.riskScore >= 20) {
      // High/At Risk Red-Pink tone
      cardBg = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      scoreColor = const Color(0xFFE11D48);
      ringTrackColor = const Color(0xFFFFE4E6);
      ringProgressColor = const Color(0xFFE11D48);
      statusTagBg = const Color(0xFFFFE4E6);
      statusTagText = const Color(0xFFBE123C);
      statusDotColor = const Color(0xFFE11D48);
    } else if (source.riskScore > 0) {
      // Warm Amber tone
      cardBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      scoreColor = const Color(0xFFD97706);
      ringTrackColor = const Color(0xFFFEF3C7);
      ringProgressColor = const Color(0xFFD97706);
      statusTagBg = const Color(0xFFFEF3C7);
      statusTagText = const Color(0xFFB45309);
      statusDotColor = const Color(0xFFF59E0B);
    } else {
      // Mint Safe tone
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      scoreColor = const Color(0xFF059669);
      ringTrackColor = const Color(0xFFDCFCE7);
      ringProgressColor = const Color(0xFF10B981);
      statusTagBg = const Color(0xFFDCFCE7);
      statusTagText = const Color(0xFF047857);
      statusDotColor = const Color(0xFF10B981);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSourceDetailsModal(source),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Left Circular Dial with Score
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CustomPaint(
                    painter: SourceScoreRingPainter(
                      score: source.riskScore,
                      trackColor: ringTrackColor,
                      progressColor: ringProgressColor,
                      textColor: scoreColor,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Middle Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source Name
                      Text(
                        source.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E36),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Village Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            source.village,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Cleaning History
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            source.cleanedAgo,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Tags & Chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status pill (At Risk / Safe)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusTagBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusDotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                source.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusTagText,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // DEMO pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.science_outlined, size: 11, color: Color(0xFF0284C7)),
                              SizedBox(width: 3),
                              Text(
                                'DEMO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Chevron >
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF0F1E36),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Circular Risk Dial
class SourceScoreRingPainter extends CustomPainter {
  final int score;
  final Color trackColor;
  final Color progressColor;
  final Color textColor;

  SourceScoreRingPainter({
    required this.score,
    required this.trackColor,
    required this.progressColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = score == 0 ? 1.5 : (score / 100) * 2 * 3.1415926535;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Score Text in center
    final textSpan = TextSpan(
      text: '$score',
      style: TextStyle(
        color: textColor,
        fontSize: 16.5,
        fontWeight: FontWeight.w800,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Header Water Droplet Artwork
class HeaderWaterDropArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ripple 1
    final ripplePaint1 = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, size.width * 0.44, ripplePaint1);

    // Ripple 2
    final ripplePaint2 = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, size.width * 0.32, ripplePaint2);

    // Water Droplet
    final dropPath = Path();
    dropPath.moveTo(center.dx, center.dy - 12);
    dropPath.quadraticBezierTo(
      center.dx + 8,
      center.dy + 4,
      center.dx,
      center.dy + 10,
    );
    dropPath.quadraticBezierTo(
      center.dx - 8,
      center.dy + 4,
      center.dx,
      center.dy - 12,
    );
    dropPath.close();

    final dropPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7DD3FC), Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 12));

    canvas.drawPath(dropPath, dropPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - 2, center.dy + 2), 2, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
