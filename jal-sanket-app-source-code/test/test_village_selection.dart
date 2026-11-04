import 'package:flutter_test/flutter_test.dart';
import '../lib/data/district_details.dart';
import '../lib/services/jjm_scraper_service.dart';
import '../lib/services/imd_weather_service.dart';

void main() {
  test('Verify Marathi District Resolution in DistrictRegistry', () {
    // 1. Marathi district names
    final kolhapur = DistrictRegistry.resolveDistrict('कोल्हापूर');
    expect(kolhapur, isNotNull);
    expect(kolhapur!.dtName, equals('Kolhapur'));

    final satara = DistrictRegistry.resolveDistrict('सातारा');
    expect(satara, isNotNull);
    expect(satara!.dtName, equals('Satara'));

    final pune = DistrictRegistry.resolveDistrict('पुणे');
    expect(pune, isNotNull);
    expect(pune!.dtName, equals('Pune'));

    final sangli = DistrictRegistry.resolveDistrict('सांगली');
    expect(sangli, isNotNull);
    expect(sangli!.dtName, equals('Sangli'));

    // 2. Bilingual string e.g. 'कोल्हापूर (Kolhapur)'
    final kolhapurBi = DistrictRegistry.resolveDistrict('कोल्हापूर (Kolhapur)');
    expect(kolhapurBi, isNotNull);
    expect(kolhapurBi!.dtName, equals('Kolhapur'));
  });

  test('Verify Talukas for Maharashtra Districts', () {
    final kolhapurTalukas = DistrictRegistry.maharashtraTalukasByDistrict['Kolhapur'];
    expect(kolhapurTalukas, isNotNull);
    expect(kolhapurTalukas!.length, equals(12));
    expect(kolhapurTalukas.any((t) => t.contains('Kagal')), isTrue);
    expect(kolhapurTalukas.any((t) => t.contains('Bhudargad')), isTrue);
    expect(kolhapurTalukas.any((t) => t.contains('Radhanagari')), isTrue);

    final sataraTalukas = DistrictRegistry.maharashtraTalukasByDistrict['Satara'];
    expect(sataraTalukas, isNotNull);
    expect(sataraTalukas!.length, equals(11));
    expect(sataraTalukas.any((t) => t.contains('Karad')), isTrue);
    expect(sataraTalukas.any((t) => t.contains('Phaltan')), isTrue);
  });

  test('Verify Devanagari Clean & Transliteration in JjmScraperService', () {
    expect(JjmScraperService.cleanVillageSearchQuery('कागल (Kagal)'), equals('Kagal'));
    expect(JjmScraperService.cleanVillageSearchQuery('कराड (Karad)'), equals('Karad'));
    expect(JjmScraperService.cleanVillageSearchQuery('कागल'), equals('Kagal'));
    expect(JjmScraperService.cleanVillageSearchQuery('कराड'), equals('Karad'));
    expect(JjmScraperService.cleanVillageSearchQuery('कोगनोळी'), equals('Kognoli'));
    expect(JjmScraperService.cleanVillageSearchQuery('Gargoti'), equals('Gargoti'));
  });

  test('Verify Geocoding and Weather for Non-Preset Village', () async {
    // Kagal coordinates resolution
    final coords = await ImdWeatherService.geocodeLocation('Kagal, Maharashtra, India');
    expect(coords, isNotNull);
    expect(coords!.length, equals(2));
    print('Kagal resolved coordinates: ${coords[0]}, ${coords[1]}');
    expect(coords[0], inInclusiveRange(16.0, 17.0));
    expect(coords[1], inInclusiveRange(74.0, 75.0));

    // Fetch weather for Kagal
    final wx = await ImdWeatherService.fetchLiveWeather(
      lat: coords[0],
      lon: coords[1],
      villageName: 'कागल (Kagal)',
      districtName: 'कोल्हापूर (Kolhapur)',
      blockName: 'कागल (Kagal)',
    );
    expect(wx, isNotNull);
    expect(wx.temperature, isNonZero);
    print('Kagal live weather: temp=${wx.temperature}C, summary=${wx.synopticObservation}');
  });
}
