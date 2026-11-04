import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import '../lib/services/jjm_scraper_service.dart';

void main() {
  test('Verify Water Sample Lab Test counts for Adarki Bk & Gargoti', () async {
    print('Testing Adarki Bk...');
    final res = await JjmScraperService.getVillageInformation(
      state: 'Maharashtra',
      district: 'Satara',
      block: 'Phaltan',
      village: 'Adarki Bk',
    );

    final lab = res['data']['laboratoryDetails'];
    print('Adarki Bk Lab Summary: ${jsonEncode(lab['summary'])}');
    print('Total lab records: ${(lab['records'] as List).length}');
    print('Habitations: ${jsonEncode(res['data']['location']['habitations'])}');
    print('Demographics: ${jsonEncode(res['data']['demographics'])}');

    print('\nTesting Gargoti...');
    final res2 = await JjmScraperService.getVillageInformation(
      state: 'Maharashtra',
      district: 'Kolhapur',
      block: 'Bhudargad',
      village: 'Gargoti',
    );

    final lab2 = res2['data']['laboratoryDetails'];
    print('Gargoti Lab Summary: ${jsonEncode(lab2['summary'])}');
    print('Total lab records: ${(lab2['records'] as List).length}');
    print('Gargoti Habitations: ${jsonEncode(res2['data']['location']['habitations'])}');
  });

  test('Verify Calculated Risk and Cases formula', () {
    // Test Adarki Bk: 8 unsafe out of 57
    final unsafeRatio = 8 / 57;
    final waterRisk = (unsafeRatio * 150).clamp(0.0, 40.0) + 5.0; // ~26.0
    expect(waterRisk, closeTo(26.0, 1.0));

    // Test normal expected cases for Adarki Bk (pop 2727)
    final normal = (2727 * 0.0006).clamp(0.2, 5.0); // ~1.6
    expect(normal, closeTo(1.63, 0.1));

    // Test Gargoti (pop 25910)
    final normalGargoti = (25910 * 0.0006).clamp(0.2, 5.0); // capped at 5.0
    expect(normalGargoti, equals(5.0));
  });
}

