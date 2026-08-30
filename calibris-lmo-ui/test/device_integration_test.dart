import 'package:flutter_test/flutter_test.dart';
import 'package:lmo_app/data/models/device_model.dart';
import 'package:lmo_app/data/models/tamper_event_model.dart';
import 'package:lmo_app/data/models/unlock_command_model.dart';
import 'package:lmo_app/data/models/instrument_model.dart';
import 'package:lmo_app/services/mock_device_service.dart';
import 'package:lmo_app/providers/device_provider.dart';

void main() {
  group('Backend Model Parsing & Behavior', () {
    test('DeviceModel parses 2025 backend JSON accurately', () {
      final backendJson = {
        'device_id': 1,
        'device_type': 'weighing-scale',
        'owner': 'Deepan (Retail Tech) - deepan@test.com',
        'location': 'Chennai, Tamil Nadu',
        'city': 'Chennai',
        'state': 'Tamil Nadu',
        'latitude': 13.0827,
        'longitude': 80.2707,
        'status': 'safe_mode',
        'tamper_type': 'unauthorized-access',
        'tamper_time': '2026-08-30T04:00:00.000Z',
        'tamper_details': 'Scale opened without calibration seal',
        'last_seen': DateTime.now().toIso8601String(),
        'current_weight': 15.42,
        'integrity_status': 'Compromised',
      };

      final device = DeviceModel.fromBackendJson(backendJson);

      expect(device.instrumentId, '1');
      expect(device.deviceId, 1);
      expect(device.isOnline, true);
      expect(device.isTampered, true);
      expect(device.safeMode, true);
      expect(device.health, DeviceHealth.critical);
      expect(device.city, 'Chennai');
      expect(device.state, 'Tamil Nadu');
      expect(device.latitude, 13.0827);
      expect(device.currentWeight, 15.42);
      expect(device.integrityStatus, 'Compromised');
    });

    test('TamperEventModel parses Luckfox tamper payload with crypto hashes', () {
      final tamperJson = {
        'id': 101,
        'device_id': '1',
        'tamper_type': 'enclosure-opened',
        'severity': 'high',
        'details': 'Scale cover removed',
        'event_time': '2026-08-30T04:15:00.000Z',
        'settling_time': 3.2,
        'renewal_cycle': 2,
        'drift': 0.42,
        'city': 'Mumbai',
        'state': 'Maharashtra',
        'prev_hash': 'a1b2c3d4e5f6',
        'curr_hash': 'f6e5d4c3b2a1',
        'luckfox_log_id': 'LF-LOG-99',
      };

      final tamper = TamperEventModel.fromBackendJson(tamperJson);

      expect(tamper.instrumentId, '1');
      expect(tamper.eventType, TamperEventType.enclosureOpened);
      expect(tamper.severity, TamperSeverity.high);
      expect(tamper.drift, 0.42);
      expect(tamper.settlingTime, 3.2);
      expect(tamper.prevHash, 'a1b2c3d4e5f6');
      expect(tamper.currHash, 'f6e5d4c3b2a1');
    });

    test('UnlockCommandModel parses unlock response and pending state', () {
      final unlockJson = {
        'id': 42,
        'device_id': 1,
        'officer_id': 'USR-001',
        'officer_name': 'Officer Sharma',
        'officer_email': 'sharma@calibris.gov.in',
        'officer_role': 'officer',
        'reason': 'Inspection verified',
        'status': 'pending',
        'created_at': '2026-08-30T04:20:00.000Z',
      };

      final cmd = UnlockCommandModel.fromJson(unlockJson);

      expect(cmd.id, 42);
      expect(cmd.deviceId, '1');
      expect(cmd.officerId, 'USR-001');
      expect(cmd.isPending, true);
      expect(cmd.isExecuted, false);
    });

    test('InstrumentInfo correctly identifies Weighing Machines vs Fuel Pumps', () {
      const scale = InstrumentInfo(
        instrumentId: 'DEV-001',
        type: InstrumentType.electronicWeighingScale,
        manufacturer: 'Essae',
        model: 'DS-215',
        serialNumber: 'SN-001',
        capacity: '30kg',
        accuracyClass: 'Class III',
        registeredLocationLat: 13.0827,
        registeredLocationLng: 80.2707,
        registeredAddress: 'Chennai',
        isDigitalCompatible: true,
      );

      const pump = InstrumentInfo(
        instrumentId: 'DEV-002',
        type: InstrumentType.petrolPumpDispenser,
        manufacturer: 'Tokheim',
        model: 'Quantium',
        serialNumber: 'SN-002',
        capacity: '50 L/min',
        accuracyClass: 'Class 0.5',
        registeredLocationLat: 13.0827,
        registeredLocationLng: 80.2707,
        registeredAddress: 'Salem',
        isDigitalCompatible: true,
      );

      expect(scale.isWeighingMachine, true);
      expect(scale.isFuelPump, false);

      expect(pump.isWeighingMachine, false);
      expect(pump.isFuelPump, true);
    });
  });

  group('DeviceProvider Remote Control & Targeted Verification Flow', () {
    late DeviceProvider provider;
    late MockDeviceService mockService;

    setUp(() {
      mockService = MockDeviceService();
      provider = DeviceProvider(mockService);
    });

    test('startLiveDeviceMonitoring and stopLiveDeviceMonitoring manage active device', () async {
      provider.startLiveDeviceMonitoring('DEV-001');
      expect(provider.activeMonitoredDeviceId, 'DEV-001');

      provider.stopLiveDeviceMonitoring();
      expect(provider.activeMonitoredDeviceId, isNull);
      expect(provider.device, isNull);
    });

    test('lockDeviceSafeMode creates safe-mode lock command and logs audit action', () async {
      final success = await provider.lockDeviceSafeMode(
        deviceId: '1',
        officerEmail: 'officer@calibris.gov.in',
        officerId: 'USR-001',
        reason: 'Seal tampered',
      );

      expect(success, true);
      expect(provider.isActionInProgress, false);
      expect(provider.errorMessage, isNull);
    });

    test('unlockDevice creates pending command and logs audit action', () async {
      final success = await provider.unlockDevice(
        deviceId: '1',
        officerEmail: 'officer@calibris.gov.in',
        officerId: 'USR-001',
        reason: 'Verification completed',
      );

      expect(success, true);
      expect(provider.isActionInProgress, false);
      expect(provider.errorMessage, isNull);
    });
  });
}
