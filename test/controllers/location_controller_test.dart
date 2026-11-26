import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensortrack_flutter/controllers/location_controller.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/location_service.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';

/// Implementación simulada de [LocationService] para pruebas unitarias.
class FakeLocationService extends LocationService {
  Position? positionToReturn;
  bool shouldThrow = false;
  String throwMessage = 'Error GPS';

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    if (shouldThrow) {
      throw LocationServiceException(throwMessage);
    }
    return positionToReturn ??
        Position(
          latitude: -0.180653,
          longitude: -78.467834,
          timestamp: DateTime(2026, 11, 25, 12, 0),
          accuracy: 4.5,
          altitude: 2850.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
  }
}

/// Implementación simulada de [SupabaseService] para pruebas de ubicación.
class FakeSupabaseServiceForLocation extends SupabaseService {
  final List<SensorReading> insertedReadings = [];
  bool shouldThrow = false;

  @override
  Future<void> insertReading(SensorReading reading) async {
    if (shouldThrow) {
      throw const SupabaseServiceException('Error al insertar ubicación');
    }
    insertedReadings.add(reading);
  }
}

void main() {
  group('LocationController', () {
    late FakeLocationService fakeLocationService;
    late FakeSupabaseServiceForLocation fakeSupabaseService;
    late LocationController controller;

    setUp(() {
      fakeLocationService = FakeLocationService();
      fakeSupabaseService = FakeSupabaseServiceForLocation();
      controller = LocationController(
        locationService: fakeLocationService,
        supabaseService: fakeSupabaseService,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Inicia con estado sin ubicación y no cargando', () {
      expect(controller.isLoading, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.currentPosition, isNull);
      expect(controller.hasLocation, isFalse);
    });

    test('fetchLocation obtiene coordenadas GPS exitosamente', () async {
      await controller.fetchLocation();

      expect(controller.isLoading, isFalse);
      expect(controller.hasLocation, isTrue);
      expect(controller.currentPosition?.latitude, closeTo(-0.180653, 0.0001));
      expect(
          controller.currentPosition?.longitude, closeTo(-78.467834, 0.0001));
      expect(controller.currentPosition?.accuracy, 4.5);
      expect(controller.successMessage, contains('éxito'));
      expect(controller.errorMessage, isNull);
    });

    test('fetchLocation captura LocationServiceException y notifica error',
        () async {
      fakeLocationService.shouldThrow = true;
      fakeLocationService.throwMessage = 'Permisos denegados';

      await controller.fetchLocation();

      expect(controller.isLoading, isFalse);
      expect(controller.hasLocation, isFalse);
      expect(controller.errorMessage, 'Permisos denegados');
    });

    test('saveLocationToSupabase guarda coordenadas en Supabase', () async {
      await controller.fetchLocation();

      final success = await controller.saveLocationToSupabase();

      expect(success, isTrue);
      expect(fakeSupabaseService.insertedReadings.length, 1);
      final reading = fakeSupabaseService.insertedReadings.first;
      expect(reading.sensorType, SensorType.gps);
      expect(reading.latitude, closeTo(-0.180653, 0.0001));
      expect(reading.longitude, closeTo(-78.467834, 0.0001));
      expect(reading.accuracy, 4.5);
      expect(controller.successMessage, contains('Supabase'));
    });

    test('saveLocationToSupabase falla si aún no se tiene ubicación', () async {
      final success = await controller.saveLocationToSupabase();

      expect(success, isFalse);
      expect(fakeSupabaseService.insertedReadings, isEmpty);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
