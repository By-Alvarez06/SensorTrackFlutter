import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sensortrack_flutter/controllers/sensor_controller.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/sensor_service.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';

/// Implementación simulada de [SupabaseService] para pruebas unitarias.
class FakeSupabaseService extends SupabaseService {
  final List<SensorReading> insertedReadings = [];
  bool shouldThrow = false;

  @override
  Future<void> insertReading(SensorReading reading) async {
    if (shouldThrow) {
      throw const SupabaseServiceException('Error simulado en Supabase');
    }
    insertedReadings.add(reading);
  }
}

void main() {
  group('SensorController', () {
    late StreamController<AccelerometerEvent> accelStreamController;
    late StreamController<GyroscopeEvent> gyroStreamController;
    late SensorService fakeSensorService;
    late FakeSupabaseService fakeSupabaseService;
    late SensorController controller;

    setUp(() {
      accelStreamController = StreamController<AccelerometerEvent>.broadcast();
      gyroStreamController = StreamController<GyroscopeEvent>.broadcast();

      fakeSensorService = SensorService(
        accelerometerStream: accelStreamController.stream,
        gyroscopeStream: gyroStreamController.stream,
      );
      fakeSupabaseService = FakeSupabaseService();

      controller = SensorController(
        sensorService: fakeSensorService,
        supabaseService: fakeSupabaseService,
      );
    });

    tearDown(() {
      controller.dispose();
      accelStreamController.close();
      gyroStreamController.close();
    });

    test('Inicia con estado detenido y valores nulos', () {
      expect(controller.isMonitoring, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.accelX, isNull);
      expect(controller.gyroX, isNull);
      expect(controller.errorMessage, isNull);
    });

    test('startMonitoring escucha streams y actualiza valores en tiempo real',
        () async {
      controller.startMonitoring();
      expect(controller.isMonitoring, isTrue);

      accelStreamController
          .add(AccelerometerEvent(1.2, -3.4, 9.8, DateTime.now()));
      gyroStreamController.add(GyroscopeEvent(0.1, -0.2, 0.3, DateTime.now()));

      // Permitir procesamiento asíncrono del stream
      await pumpEventQueue();

      expect(controller.accelX, closeTo(1.2, 0.01));
      expect(controller.accelY, closeTo(-3.4, 0.01));
      expect(controller.accelZ, closeTo(9.8, 0.01));

      expect(controller.gyroX, closeTo(0.1, 0.01));
      expect(controller.gyroY, closeTo(-0.2, 0.01));
      expect(controller.gyroZ, closeTo(0.3, 0.01));
    });

    test('stopMonitoring detiene la escucha y actualiza isMonitoring a false',
        () {
      controller.startMonitoring();
      expect(controller.isMonitoring, isTrue);

      controller.stopMonitoring();
      expect(controller.isMonitoring, isFalse);
    });

    test('saveReading guarda medición puntual del acelerómetro en Supabase',
        () async {
      controller.startMonitoring();
      accelStreamController
          .add(AccelerometerEvent(2.0, 4.0, 8.0, DateTime.now()));
      await pumpEventQueue();

      final success = await controller.saveReading(SensorType.accelerometer);

      expect(success, isTrue);
      expect(fakeSupabaseService.insertedReadings.length, 1);
      final saved = fakeSupabaseService.insertedReadings.first;
      expect(saved.sensorType, SensorType.accelerometer);
      expect(saved.x, 2.0);
      expect(saved.y, 4.0);
      expect(saved.z, 8.0);
      expect(controller.successMessage, contains('Acelerómetro'));
    });

    test('saveReading retorna false y setea error si no hay lecturas previas',
        () async {
      // Sin emitir eventos previos
      final success = await controller.saveReading(SensorType.accelerometer);

      expect(success, isFalse);
      expect(fakeSupabaseService.insertedReadings, isEmpty);
      expect(controller.errorMessage, isNotNull);
    });

    test('saveReading maneja excepciones de Supabase correctamente', () async {
      controller.startMonitoring();
      gyroStreamController.add(GyroscopeEvent(1.0, 2.0, 3.0, DateTime.now()));
      await pumpEventQueue();

      fakeSupabaseService.shouldThrow = true;
      final success = await controller.saveReading(SensorType.gyroscope);

      expect(success, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.errorMessage, contains('Error simulado'));
    });
  });
}
