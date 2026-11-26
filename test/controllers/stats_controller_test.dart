import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack_flutter/controllers/stats_controller.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';

class _FakeSupabaseService extends SupabaseService {
  Future<List<SensorReading>> Function(SensorType? sensorType, int limit)?
      onFetchReadings;

  @override
  Future<List<SensorReading>> fetchReadings({
    SensorType? sensorType,
    int limit = 100,
  }) async {
    if (onFetchReadings != null) {
      return onFetchReadings!(sensorType, limit);
    }
    return const [];
  }
}

void main() {
  group('StatsController', () {
    test('inicia con estadísticas vacías y acelerómetro seleccionado', () {
      final controller = StatsController(
        supabaseService: _FakeSupabaseService(),
      );
      addTearDown(controller.dispose);

      expect(controller.isEmpty, isTrue);
      expect(controller.stats.totalReadings, 0);
      expect(controller.selectedChartSensor, SensorType.accelerometer);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
    });

    test(
        'selecciona automáticamente un sensor con serie cuando no hay acelerómetro',
        () async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) async => const [
              SensorReading(
                id: 'gyro-1',
                sensorType: SensorType.gyroscope,
                x: 0.2,
                y: 0.3,
                z: 0.4,
              ),
              SensorReading(
                id: 'gps-1',
                sensorType: SensorType.gps,
                latitude: -0.2,
                longitude: -78.5,
                accuracy: 5.0,
              ),
            ];

      final controller = StatsController(supabaseService: service);
      addTearDown(controller.dispose);

      await controller.loadStats();

      expect(controller.stats.totalReadings, 2);
      expect(controller.selectedChartSensor, SensorType.gyroscope);
      expect(controller.activeChartSeries.length, 1);

      // La selección manual del usuario debe respetarse en futuras recargas.
      controller.selectChartSensor(SensorType.gps);
      expect(controller.selectedChartSensor, SensorType.gps);
      expect(controller.activeChartSeries.first.magnitude, 5.0);

      await controller.refresh();
      expect(controller.selectedChartSensor, SensorType.gps);
    });

    test('maneja errores de Supabase y errores genéricos', () async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) async {
          throw const SupabaseServiceException('Fallo de red en estadísticas.');
        };

      final controller = StatsController(supabaseService: service);
      addTearDown(controller.dispose);

      await controller.loadStats();
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, 'Fallo de red en estadísticas.');

      service.onFetchReadings = (_, __) async => throw Exception('boom');
      await controller.refresh();
      expect(controller.hasError, isTrue);
      expect(
        controller.errorMessage,
        contains('error inesperado al calcular las estadísticas'),
      );
    });

    test(
      'no notifica ni falla si dispose ocurre durante carga pendiente',
      () async {
        final completer = Completer<List<SensorReading>>();
        final service = _FakeSupabaseService()
          ..onFetchReadings = (_, __) => completer.future;

        final controller = StatsController(supabaseService: service);
        final pending = controller.loadStats();
        controller.dispose();

        completer.complete(const [
          SensorReading(sensorType: SensorType.accelerometer, x: 1, y: 2, z: 3),
        ]);
        await pending;

        expect(controller.stats.totalReadings, 0);
      },
    );
  });
}
