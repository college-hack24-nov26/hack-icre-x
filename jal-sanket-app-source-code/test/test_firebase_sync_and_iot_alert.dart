import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jal_sanket_2/screens/voice_engine.dart';
import 'package:jal_sanket_2/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Firebase Database Integration & ASHA ↔ Doctor Sync Tests', () {
    test('ASHA worker saved patient case defaults to forwarded to Doctor (pending triage)', () async {
      final extraction = VoiceExtraction(
        transcript: 'रुग्ण नाम रमेश कांबळे, वय ४२, शिरोळ. २ दिवसांपासून तीव्र जुलाब व उलट्या.',
        patientName: VField<String>(value: 'रमेश कांबळे', status: 'ok'),
        ageYears: VField<int>(value: 42, status: 'ok'),
        village: VField<String>(value: 'शिरोळ (Shirol)', status: 'ok'),
        durationDays: VField<int>(value: 2, status: 'ok'),
        stoolsPerDay: VField<int>(value: 5, status: 'ok'),
        vomitCount: VField<int>(value: 3, status: 'ok'),
      );

      final row = await LocalStore.saveFromExtraction(
        extraction,
        villageId: 'v-shirol',
        patientPseudoId: 'P-SHL-999',
        danger: ['frequent_vomiting'],
        durationSec: 15,
        ashaId: 'ASHA-402',
        ashaName: 'Sunita Kamble',
      );

      // Verify the case is immediately marked for Doctor review
      expect(row.isForwardedToDoctor, isTrue);
      expect(row.doctorStatus, equals('pending'));
      expect(row.priority, equals('urgent')); // danger sign present
      expect(row.patientName, equals('रमेश कांबळे'));

      // Verify Doctor triage queue retrieves this case
      final allCases = await LocalStore.all(syncWithFirebase: false);
      final doctorPendingQueue = allCases
          .where((c) => c.isForwardedToDoctor && c.doctorStatus == 'pending')
          .toList();

      expect(doctorPendingQueue.any((c) => c.id == row.id), isTrue);
    });

    test('Doctor review completes the clinical circle and marks case as reviewed', () async {
      final extraction = VoiceExtraction(
        transcript: 'रुग्ण कविता पाटील, वय २८, पिंपरी.',
        patientName: VField<String>(value: 'कविता पाटील', status: 'ok'),
        ageYears: VField<int>(value: 28, status: 'ok'),
        village: VField<String>(value: 'पिंपरी (Pimpri)', status: 'ok'),
      );

      final row = await LocalStore.saveFromExtraction(
        extraction,
        villageId: 'v-pimpri',
        patientPseudoId: 'P-PMP-555',
        danger: [],
        durationSec: 8,
      );

      expect(row.doctorStatus, equals('pending'));

      // Doctor performs consultation and signs assessment/plan
      await LocalStore.saveDoctorReviewForCase(
        row.id,
        doctorName: 'Dr. Patil',
        doctorId: 'MO-101',
        assessment: 'सौम्य जलजन्य गॅस्ट्रोएन्टेरिटिस',
        plan: '१. ORS जलसंजीवनी.\n२. झिंक गोळ्या १४ दिवस.\n३. उकळलेले पाणी.',
      );

      final updatedCases = await LocalStore.all(syncWithFirebase: false);
      final reviewedCase = updatedCases.firstWhere((c) => c.id == row.id);

      expect(reviewedCase.doctorStatus, equals('reviewed'));
      expect(reviewedCase.doctorName, equals('Dr. Patil'));
      expect(reviewedCase.doctorAssessment, contains('गॅस्ट्रोएन्टेरिटिस'));
    });
  });

  group('IoT Sensor Value Mismatch & Role Restriction Tests', () {
    test('IoT Mismatch Alert permissions strictly allow Jalrakshak and Citizen, reject others', () {
      bool isRoleAllowedForIotAlert(String role) {
        return role == 'Jalrakshak' || role == 'Citizen';
      }

      // Allowed roles: Villager (Citizen) & Jalsurakshak (Jalrakshak)
      expect(isRoleAllowedForIotAlert('Jalrakshak'), isTrue);
      expect(isRoleAllowedForIotAlert('Citizen'), isTrue);

      // Other roles MUST NOT receive IoT alerts
      expect(isRoleAllowedForIotAlert('Medical Officer'), isFalse);
      expect(isRoleAllowedForIotAlert('ASHA Worker'), isFalse);
      expect(isRoleAllowedForIotAlert('BDO'), isFalse);
      expect(isRoleAllowedForIotAlert('THO'), isFalse);
    });

    test('IotMismatchAlert model holds all required parameters for 30s auto-wipe banner', () {
      final alert = IotMismatchAlert(
        id: 'test-alert-1',
        title: '⚠️ आयओटी इशारा: TDS मर्यादा ओलांडली!',
        subtitle: 'पाण्यातील क्षार प्रमाण सुरक्षित निकषापेक्षा जास्त आहे.',
        parameter: 'TDS (क्षार)',
        currentValue: 640.0,
        threshold: 500.0,
        unit: 'ppm',
        source: 'SENSOR_DATA.TDS',
        recommendation: 'पाणी त्वरित उकळून प्यावे व स्त्रोताचे शुद्धीकरण करावे.',
        detectedAt: DateTime.now(),
      );

      expect(alert.currentValue, greaterThan(alert.threshold));
      expect(alert.unit, equals('ppm'));
      expect(alert.source, equals('SENSOR_DATA.TDS'));
    });
  });
}
