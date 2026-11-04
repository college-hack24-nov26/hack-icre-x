import 'package:flutter_test/flutter_test.dart';
import '../lib/services/jjm_scraper_service.dart';

void main() {
  test('Pan-India JJM Live Scraper validation across 4 states', () async {
    print('\n================================================================');
    print('  PAN-INDIA JJM LIVE SCRAPER VALIDATION');
    print('  Testing across 4 diverse states: MH, GA, UP, RJ');
    print('================================================================\n');

    final testCases = [
      {
        'state': 'Maharashtra',
        'district': 'Kolhapur',
        'village': 'Gargoti',
        'block': 'Bhudargad',
      },
      {
        'state': 'Goa',
        'district': 'North Goa',
        'village': 'Anjuna',
        'block': 'Bardez',
      },
      {
        'state': 'Uttar Pradesh',
        'district': 'Varanasi',
        'village': 'Shivrampur',
        'block': 'Arajiline',
      },
      {
        'state': 'Rajasthan',
        'district': 'Jaipur Gramin',
        'village': 'Andhi',
        'block': 'Aandhi',
      },
    ];

    for (final tc in testCases) {
      final st = tc['state']!;
      final dt = tc['district']!;
      final vg = tc['village']!;
      final bl = tc['block']!;

      print('Testing: $vg ($bl, $dt, $st)...');
      try {
        final res = await JjmScraperService.getVillageInformation(
          state: st,
          district: dt,
          village: vg,
          block: bl,
        );

        final d = res['data'] as Map<String, dynamic>;
        final loc = d['location'] as Map<String, dynamic>;
        final demo = d['demographics'] as Map<String, dynamic>;
        final pop = demo['population'] as Map<String, dynamic>;
        final hh = demo['households'] as Map<String, dynamic>;
        final ws = d['waterSupplySchemes'] as Map<String, dynamic>;
        final wq = d['waterQuality'] as Map<String, dynamic>;
        final lab = wq['laboratorySampleDetails'] as Map<String, dynamic>;
        final labSum = lab['summary'] as Map<String, dynamic>;
        final inst = d['institutions'] as Map<String, dynamic>;
        final sch = inst['schools'] as Map<String, dynamic>;
        final awc = inst['anganwadis'] as Map<String, dynamic>;

        print('  SUCCESS! [100% Genuine JJM Live Data]');
        print('  - JJM Village ID: ${loc['villageId']} (LGD: ${loc['villageLgdCode']})');
        print('  - Certification: ${d['status']['harGharJalCertified']}');
        print('  - Total Population: ${pop['total']}');
        print('  - Total Households: ${hh['total']} (With Tap: ${hh['withTapConnections']}, Pct: ${hh['tapConnectionsPercentage']})');
        print('  - PWS Schemes: ${ws['totalSchemes']} scheme(s)');
        print('  - Lab Tests: Total=${labSum['totalTested']}, Safe=${labSum['samplesSafe']}, Unsafe=${labSum['samplesUnsafe']}');
        print('  - Schools: ${sch['total']} (Tap: ${sch['withTapConnections']}), Anganwadis: ${awc['total']} (Tap: ${awc['withTapConnections']})');
        print('');

        expect(loc['villageId'], isNotNull);
        expect(pop['total'], isNotNull);
      } catch (e, stck) {
        print('  FAILED for $vg: $e\n$stck\n');
        fail('Failed to fetch data for $vg: $e');
      }
    }

    print('================================================================');
    print('  ALL STATES & VILLAGES VALIDATED SUCCESSFULLY!');
    print('================================================================');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
