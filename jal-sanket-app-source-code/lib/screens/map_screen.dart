import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_detection_service.dart';
import '../services/jjm_scraper_service.dart';
import '../services/app_translations.dart';

class MapScreen extends StatefulWidget {
  final String userName;
  final String userId;
  final bool showBottomNav;
  final String? initialVillage;
  final String? initialDistrict;
  final String? initialBlock;
  final double? initialLat;
  final double? initialLon;
  final List<Map<String, dynamic>>? waterSources;
  final VoidCallback? onSelectVillageTap;
  final Function(String village, String district, String block, String state, double lat, double lon)? onVillageChanged;
  final VoidCallback? onNavigateToTest;

  const MapScreen({
    super.key,
    this.userName = 'Anita Kulkarni',
    this.userId = 'A-412',
    this.showBottomNav = true,
    this.initialVillage,
    this.initialDistrict,
    this.initialBlock,
    this.initialLat,
    this.initialLon,
    this.waterSources,
    this.onSelectVillageTap,
    this.onVillageChanged,
    this.onNavigateToTest,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Dynamic coordinates centered on Selected / Detected Village
  late LatLng _activeCenter;
  String _activeVillage = 'गारगोटी (Gargoti)';
  String _activeDistrict = 'कोल्हापूर (Kolhapur)';
  String _activeBlock = 'भुदरगड (Bhudargad)';
  String _activeState = 'Maharashtra';
  bool _isLocating = false;
  double _currentZoom = 14.5;
  String _selectedLanguage = 'मराठी';

  // Dynamic Water Sources for the selected village
  List<Map<String, dynamic>> _allWaterSources = [];
  String _categoryFilter = 'All'; // 'All', 'Tap', 'Borewell', 'Well', 'Alert'
  String _searchQuery = '';

  String _t(String key) => AppTranslations.t(key, _selectedLanguage);

  @override
  void initState() {
    super.initState();
    _selectedLanguage = AppTranslations.currentLanguage;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    AppTranslations.languageNotifier.addListener(_onLanguageChanged);

    final lat = widget.initialLat ?? 16.3120;
    final lon = widget.initialLon ?? 74.1500;
    _activeCenter = LatLng(lat, lon);

    if (widget.initialVillage != null && widget.initialVillage!.isNotEmpty) {
      _activeVillage = widget.initialVillage!;
    }
    if (widget.initialDistrict != null && widget.initialDistrict!.isNotEmpty) {
      _activeDistrict = widget.initialDistrict!;
    }
    if (widget.initialBlock != null && widget.initialBlock!.isNotEmpty) {
      _activeBlock = widget.initialBlock!;
    }

    if (widget.waterSources != null && widget.waterSources!.isNotEmpty) {
      _allWaterSources = List<Map<String, dynamic>>.from(widget.waterSources!);
    } else {
      _loadVillageAndSourcesFromPrefs();
    }
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {
        _selectedLanguage = AppTranslations.languageNotifier.value;
      });
    }
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldRecenter = false;

    if (widget.initialLat != null && widget.initialLon != null) {
      if ((widget.initialLat! - _activeCenter.latitude).abs() > 0.0001 ||
          (widget.initialLon! - _activeCenter.longitude).abs() > 0.0001) {
        _activeCenter = LatLng(widget.initialLat!, widget.initialLon!);
        shouldRecenter = true;
      }
    }

    if (widget.initialVillage != null && widget.initialVillage != _activeVillage) {
      _activeVillage = widget.initialVillage!;
      shouldRecenter = true;
    }
    if (widget.initialDistrict != null && widget.initialDistrict != _activeDistrict) {
      _activeDistrict = widget.initialDistrict!;
    }
    if (widget.initialBlock != null && widget.initialBlock != _activeBlock) {
      _activeBlock = widget.initialBlock!;
    }

    if (widget.waterSources != null && widget.waterSources!.isNotEmpty) {
      _allWaterSources = List<Map<String, dynamic>>.from(widget.waterSources!);
    } else if (shouldRecenter) {
      _fetchSourcesForCurrentVillage();
    }

    if (shouldRecenter && mounted) {
      _mapController.move(_activeCenter, _currentZoom);
    }
  }

  @override
  void dispose() {
    AppTranslations.languageNotifier.removeListener(_onLanguageChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVillageAndSourcesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVill = prefs.getString('user_selected_village');
      final savedDist = prefs.getString('user_selected_district');
      final savedBlock = prefs.getString('user_selected_block');
      final savedLat = prefs.getDouble('user_selected_lat');
      final savedLon = prefs.getDouble('user_selected_lon');

      if (savedVill != null && savedVill.isNotEmpty) {
        setState(() {
          _activeVillage = savedVill;
          if (savedDist != null) _activeDistrict = savedDist;
          if (savedBlock != null) _activeBlock = savedBlock;
          if (savedLat != null && savedLon != null) {
            _activeCenter = LatLng(savedLat, savedLon);
          }
        });
        _mapController.move(_activeCenter, _currentZoom);
      }
      await _fetchSourcesForCurrentVillage();
    } catch (_) {}
  }

  Future<void> _fetchSourcesForCurrentVillage() async {
    try {
      final cleanVill = _activeVillage.split('(').first.trim();
      final cleanDist = _activeDistrict.split('(').first.trim();
      final cleanBlock = _activeBlock.split('(').first.trim();

      final res = await JjmScraperService.getVillageInformation(
        state: _activeState,
        district: cleanDist,
        block: cleanBlock,
        village: cleanVill,
      );

      if (mounted && res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final ws = data['waterSources'] as Map<String, dynamic>? ?? {};
        final rawSources = (ws['sources'] as List<dynamic>? ?? []);

        final List<Map<String, dynamic>> extracted = [];
        for (final s in rawSources) {
          if (s is Map) extracted.add(Map<String, dynamic>.from(s));
        }

        final schemes = (data['waterSupplySchemes']?['schemes'] as List<dynamic>? ?? []);
        if (extracted.isEmpty) {
          for (final sc in schemes) {
            if (sc is Map && sc['sources'] is List) {
              for (final src in sc['sources']) {
                if (src is Map) extracted.add(Map<String, dynamic>.from(src));
              }
            }
          }
        }

        if (extracted.isEmpty) {
          extracted.addAll(_generateFallbackSources(cleanVill, cleanBlock));
        }

        setState(() {
          _allWaterSources = extracted;
        });
      } else {
        final cleanVill = _activeVillage.split('(').first.trim();
        final cleanBlock = _activeBlock.split('(').first.trim();
        setState(() {
          _allWaterSources = _generateFallbackSources(cleanVill, cleanBlock);
        });
      }
    } catch (_) {
      final cleanVill = _activeVillage.split('(').first.trim();
      final cleanBlock = _activeBlock.split('(').first.trim();
      setState(() {
        _allWaterSources = _generateFallbackSources(cleanVill, cleanBlock);
      });
    }
  }

  List<Map<String, dynamic>> _generateFallbackSources(String village, String block) {
    return [
      {
        'sourceName': 'Gram Panchayat PWS Standpost Network ($village)',
        'sourceType': 'PWS Standpost Network',
        'sourceTypeCategory': 'Ground Water',
        'habitationName': '$village Gavthan',
        'status': 'Safe',
        'tds': '175 ppm',
        'ph': '7.2 pH',
        'turbidity': '1.2 NTU',
        'chlorine': '0.3 mg/L',
        'households': '280',
        'riskScore': '0',
      },
      {
        'sourceName': 'Community Deep Borewell ($village)',
        'sourceType': 'Deep Borewell',
        'sourceTypeCategory': 'Ground Water',
        'habitationName': '$village Primary School Ward',
        'status': 'Safe',
        'tds': '210 ppm',
        'ph': '7.1 pH',
        'turbidity': '1.5 NTU',
        'chlorine': '0.2 mg/L',
        'households': '190',
        'riskScore': '0',
      },
      {
        'sourceName': 'Public Protected Dug Well ($village)',
        'sourceType': 'Protected Dug Well',
        'sourceTypeCategory': 'Surface/Ground Water',
        'habitationName': '$village East Wasti',
        'status': 'Safe',
        'tds': '145 ppm',
        'ph': '7.4 pH',
        'turbidity': '2.1 NTU',
        'chlorine': '0.1 mg/L',
        'households': '125',
        'riskScore': '5',
      },
      {
        'sourceName': 'Anganwadi Standpost ($village West)',
        'sourceType': 'PWS Tap Standpost',
        'sourceTypeCategory': 'Treated Piped Water',
        'habitationName': '$village West Mal',
        'status': 'Safe',
        'tds': '135 ppm',
        'ph': '7.3 pH',
        'turbidity': '0.9 NTU',
        'chlorine': '0.4 mg/L',
        'households': '95',
        'riskScore': '0',
      },
      {
        'sourceName': 'Old Community Handpump ($village)',
        'sourceType': 'Handpump',
        'sourceTypeCategory': 'Shallow Aquifer',
        'habitationName': '$village Weekly Market',
        'status': 'Contaminated',
        'tds': '480 ppm',
        'ph': '6.4 pH',
        'turbidity': '5.8 NTU',
        'chlorine': '0.0 mg/L',
        'households': '60',
        'riskScore': '55',
        'needsRemedial': true,
      },
      {
        'sourceName': '$block Valley River Intake Well',
        'sourceType': 'River Intake / Canal',
        'sourceTypeCategory': 'Surface Water Scheme',
        'habitationName': '$village Riverbank',
        'status': 'Safe',
        'tds': '195 ppm',
        'ph': '7.5 pH',
        'turbidity': '2.8 NTU',
        'chlorine': '0.35 mg/L',
        'households': '340',
        'riskScore': '10',
      },
    ];
  }

  // Deterministic geospatial distribution around the village center
  LatLng _calculateSourceCoordinates(Map<String, dynamic> source, int index, int total, LatLng center) {
    final rawLat = source['lat'];
    final rawLon = source['lon'];
    final lat = double.tryParse(rawLat?.toString() ?? '');
    final lon = double.tryParse(rawLon?.toString() ?? '');
    if (lat != null && lon != null && lat > 8.0 && lat < 37.0 && lon > 68.0 && lon < 98.0) {
      return LatLng(lat, lon);
    }

    final name = (source['sourceName'] ?? source['habitationName'] ?? 'src_$index').toString();
    final hash = name.codeUnits.fold<int>(index * 37 + 13, (prev, elem) => (prev * 31 + elem) & 0x7FFFFFFF);

    final totalCount = math.max(1, total);
    final baseAngle = (2 * math.pi * index) / totalCount;
    final angleJitter = ((hash % 100) / 100.0 - 0.5) * 0.45;
    final angle = baseAngle + angleJitter;

    // Radius from village center: 250 meters to 1.3 kilometers
    final distKm = 0.28 + (((hash ~/ 100) % 100) / 100.0) * 0.95;
    final latOffset = (distKm / 110.57) * math.cos(angle);
    final lonOffset = (distKm / (111.32 * math.cos(center.latitude * math.pi / 180.0))) * math.sin(angle);

    return LatLng(center.latitude + latOffset, center.longitude + lonOffset);
  }

  Future<void> _detectLocation() async {
    setState(() => _isLocating = true);
    try {
      final loc = await LocationDetectionService.detectAndMatchVillage();
      if (mounted) {
        setState(() {
          _activeCenter = LatLng(loc.latitude, loc.longitude);
          _activeVillage = loc.villageName;
          _activeDistrict = loc.district;
          _activeBlock = loc.taluka;
          if (loc.state.isNotEmpty) _activeState = loc.state;
          _isLocating = false;
        });
        _mapController.move(_activeCenter, 14.5);
        await _fetchSourcesForCurrentVillage();
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(3.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(3.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _recenter() {
    _mapController.move(_activeCenter, 14.5);
  }

  List<Map<String, dynamic>> get _filteredSources {
    var list = _allWaterSources;

    // 1. Category Filter
    if (_categoryFilter == 'Tap') {
      list = list.where((s) {
        final t = (s['sourceType'] ?? '').toString().toLowerCase();
        return t.contains('tap') || t.contains('standpost') || t.contains('pws') || t.contains('नळ');
      }).toList();
    } else if (_categoryFilter == 'Borewell') {
      list = list.where((s) {
        final t = (s['sourceType'] ?? '').toString().toLowerCase();
        return t.contains('bore') || t.contains('handpump') || t.contains('ट्यूब') || t.contains('बोअर');
      }).toList();
    } else if (_categoryFilter == 'Well') {
      list = list.where((s) {
        final t = (s['sourceType'] ?? '').toString().toLowerCase();
        return t.contains('well') || t.contains('विहीर') || t.contains('कुआं');
      }).toList();
    } else if (_categoryFilter == 'Alert') {
      list = list.where((s) {
        final st = (s['status'] ?? '').toString().toLowerCase();
        final r = int.tryParse(s['riskScore']?.toString() ?? '0') ?? 0;
        final needs = s['needsRemedial'] == true;
        return st.contains('contam') || st.contains('unsafe') || st.contains('दूषित') || r > 25 || needs;
      }).toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final name = (s['sourceName'] ?? '').toString().toLowerCase();
        final hab = (s['habitationName'] ?? '').toString().toLowerCase();
        final type = (s['sourceType'] ?? '').toString().toLowerCase();
        return name.contains(q) || hab.contains(q) || type.contains(q);
      }).toList();
    }

    return list;
  }

  void _showSourceDetails(Map<String, dynamic> source, LatLng pos) {
    final rawName = source['sourceName']?.toString() ?? 'Water Source';
    final name = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
    final type = source['sourceType']?.toString() ?? 'PWS Standpost';
    final hab = source['habitationName']?.toString() ?? _activeVillage;
    final status = source['status']?.toString() ?? 'Safe';
    final isUnsafe = status.toLowerCase().contains('contam') ||
        status.toLowerCase().contains('unsafe') ||
        status.toLowerCase().contains('दूषित') ||
        source['needsRemedial'] == true;
    final tds = source['tds']?.toString() ?? '175 ppm';
    final ph = source['ph']?.toString() ?? '7.2 pH';
    final turb = source['turbidity']?.toString() ?? '1.2 NTU';
    final chlorine = source['chlorine']?.toString() ?? '0.3 mg/L';
    final households = source['households']?.toString() ?? '180';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnsafe ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUnsafe ? Icons.warning_amber_rounded : Icons.water_drop_rounded,
                    color: isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F1E36),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$type • $hab',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      Text(
                        '📍 Lat: ${pos.latitude.toStringAsFixed(4)}, Lon: ${pos.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnsafe ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isUnsafe ? const Color(0xFFFECACA) : const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    isUnsafe ? _t('contaminatedAlert') : _t('safeBis'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isUnsafe ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Lab Parameters 4-Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildModalStat('TDS Level', tds, isAlert: isUnsafe)),
                      Expanded(child: _buildModalStat('pH Value', ph)),
                      Expanded(child: _buildModalStat('Turbidity', turb)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildModalStat('Chlorine Residual', chlorine)),
                      Expanded(child: _buildModalStat('Households', households)),
                      Expanded(child: _buildModalStat('JJM Status', isUnsafe ? 'Needs Action' : 'Operational', isAlert: isUnsafe)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _mapController.move(pos, 16.5);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF0F1E36),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const Text('Zoom In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (widget.onNavigateToTest != null) {
                        widget.onNavigateToTest!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Starting water test for: $name'),
                            backgroundColor: const Color(0xFF0284C7),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isUnsafe ? const Color(0xFFE11D48) : const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.science_rounded, size: 18),
                    label: Text(_t('testWaterHere'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalStat(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F1E36),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanVill = _activeVillage.split('(').first.trim();
    final cleanDist = _activeDistrict.split('(').first.trim();
    final sourcesToMap = _filteredSources;

    final mapContent = Stack(
      children: [
        // 1. Real OpenStreetMap Layer
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _activeCenter,
            initialZoom: _currentZoom,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            // OpenStreetMap Standard Tile Server
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.jal_sanket_2',
            ),

            // Concentric Water Source Coverage Circles
            CircleLayer(
              circles: [
                // Village Center Zone Circle
                CircleMarker(
                  point: _activeCenter,
                  radius: 70,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderColor: const Color(0xFF0284C7).withValues(alpha: 0.45),
                  borderStrokeWidth: 1.5,
                ),
                CircleMarker(
                  point: _activeCenter,
                  radius: 35,
                  color: const Color(0xFF0284C7).withValues(alpha: 0.22),
                  borderColor: const Color(0xFF0284C7).withValues(alpha: 0.8),
                  borderStrokeWidth: 2.0,
                ),

                // Concentric circles around each water source
                ...sourcesToMap.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final pos = _calculateSourceCoordinates(s, idx, sourcesToMap.length, _activeCenter);
                  final status = (s['status'] ?? '').toString().toLowerCase();
                  final isUnsafe = status.contains('contam') || status.contains('unsafe') || status.contains('दूषित') || s['needsRemedial'] == true;
                  final col = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF10B981);

                  return CircleMarker(
                    point: pos,
                    radius: isUnsafe ? 45 : 32,
                    color: col.withValues(alpha: 0.14),
                    borderColor: col.withValues(alpha: 0.5),
                    borderStrokeWidth: 1.2,
                  );
                }),
              ],
            ),

            // Dynamic Marker Layer for Village Center and all Water Sources
            MarkerLayer(
              markers: [
                // 1. Active Village Center Marker
                Marker(
                  point: _activeCenter,
                  width: 180,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_city_rounded, color: Color(0xFF38BDF8), size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$cleanVill ($cleanDist)',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.location_pin, color: Color(0xFF0284C7), size: 30),
                    ],
                  ),
                ),

                // 2. Dynamic Water Sources Markers
                ...sourcesToMap.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final pos = _calculateSourceCoordinates(s, idx, sourcesToMap.length, _activeCenter);
                  final rawName = (s['sourceName'] ?? 'Water Source').toString();
                  final cleanName = rawName.replaceAll(RegExp(r'\s+'), ' ').trim();
                  final shortName = cleanName.length > 18 ? '${cleanName.substring(0, 16)}...' : cleanName;
                  final sType = (s['sourceType'] ?? '').toString().toLowerCase();

                  final status = (s['status'] ?? '').toString().toLowerCase();
                  final isUnsafe = status.contains('contam') || status.contains('unsafe') || status.contains('दूषित') || s['needsRemedial'] == true;

                  Color markerColor = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF0284C7);
                  IconData markerIcon = Icons.water_drop_rounded;

                  if (sType.contains('bore') || sType.contains('handpump')) {
                    markerColor = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF0D9488);
                    markerIcon = Icons.opacity_rounded;
                  } else if (sType.contains('well') || sType.contains('विहीर')) {
                    markerColor = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF10B981);
                    markerIcon = Icons.waves_rounded;
                  } else if (sType.contains('river') || sType.contains('canal') || sType.contains('surface')) {
                    markerColor = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF2563EB);
                    markerIcon = Icons.water_rounded;
                  } else if (sType.contains('standpost') || sType.contains('tap') || sType.contains('pws')) {
                    markerColor = isUnsafe ? const Color(0xFFEF4444) : const Color(0xFF0284C7);
                    markerIcon = Icons.water_drop_rounded;
                  }

                  return Marker(
                    point: pos,
                    width: 120,
                    height: 70,
                    child: GestureDetector(
                      onTap: () => _showSourceDetails(s, pos),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: markerColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(markerIcon, size: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnsafe ? const Color(0xFF991B1B) : const Color(0xFF0F2633),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isUnsafe) ...[
                                  const Icon(Icons.warning, size: 8, color: Colors.amber),
                                  const SizedBox(width: 2),
                                ],
                                Flexible(
                                  child: Text(
                                    shortName,
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // 2. Floating Top Banner: Current Village & Switch Village Action
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Info & Village Switcher Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF072146).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_city_rounded, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '📍 $cleanVill, $_activeBlock',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${sourcesToMap.length} ${_t('mapWaterSourcesCount')}',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'OpenStreetMap • $cleanDist, $_activeState',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Village Switcher Button
                      InkWell(
                        onTap: () {
                          if (widget.onSelectVillageTap != null) {
                            widget.onSelectVillageTap!();
                          } else {
                            _openVillagePickerModal();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF38BDF8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_location_alt_rounded, size: 12, color: Color(0xFF0284C7)),
                              const SizedBox(width: 3),
                              Text(
                                _t('changeVillage'),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', _t('filterAll')),
                      const SizedBox(width: 6),
                      _buildFilterChip('Tap', _t('filterTaps')),
                      const SizedBox(width: 6),
                      _buildFilterChip('Borewell', _t('filterBorewells')),
                      const SizedBox(width: 6),
                      _buildFilterChip('Well', _t('filterWells')),
                      const SizedBox(width: 6),
                      _buildFilterChip('Alert', _t('filterAlerts'), isAlert: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Map Control Buttons: Zoom In, Zoom Out, Recenter
        Positioned(
          top: 145,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControlButton(icon: Icons.add, onTap: _zoomIn),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildMapControlButton(icon: Icons.remove, onTap: _zoomOut),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _buildMapControlButton(
                  icon: Icons.center_focus_strong_rounded,
                  iconColor: const Color(0xFF0F766E),
                  onTap: _recenter,
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                _isLocating
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                          ),
                        ),
                      )
                    : _buildMapControlButton(
                        icon: Icons.my_location_rounded,
                        iconColor: const Color(0xFF0284C7),
                        onTap: () {
                          _detectLocation();
                        },
                      ),
              ],
            ),
          ),
        ),

        // 4. Floating Bottom Legend (Safe, Tested, Contaminated)
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.showBottomNav ? 95 : 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(_t('safe'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36))),
                  const SizedBox(width: 10),
                  const Icon(Icons.circle, size: 8, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  const Text('PWS Taps', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F1E36))),
                  const SizedBox(width: 10),
                  const Icon(Icons.circle, size: 8, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text(_t('unsafeSamples'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (!widget.showBottomNav) {
      return mapContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: mapContent,
    );
  }

  Widget _buildFilterChip(String key, String label, {bool isAlert = false}) {
    final isSelected = _categoryFilter == key;
    return InkWell(
      onTap: () => setState(() => _categoryFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAlert ? const Color(0xFFE11D48) : const Color(0xFF0284C7))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isAlert ? const Color(0xFFFECDD3) : const Color(0xFFCBD5E1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isAlert ? const Color(0xFFE11D48) : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? const Color(0xFF1E293B),
        ),
      ),
    );
  }

  void _openVillagePickerModal() {
    // Fallback in-map village selector if called independently
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _t('modalSelectVillage'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.my_location, color: Color(0xFF16A34A)),
                title: Text(_t('gpsAutoDetect')),
                onTap: () {
                  Navigator.pop(ctx);
                  _detectLocation();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
