import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack_flutter/controllers/history_controller.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';

class _FakeSupabaseService extends SupabaseService {
  Future<List<SensorReading>> Function(SensorType? sensorType, int limit)?
      onFetchReadings;
  Future<SensorReading?> Function(String id)? onFetchReadingById;

  final List<SensorType?> requestedFilters = [];

  @override
  Future<List<SensorReading>> fetchReadings({
    SensorType? sensorType,
    int limit = 100,
  }) async {
    requestedFilters.add(sensorType);
    if (onFetchReadings != null) {
      return onFetchReadings!(sensorType, limit);
    }
    return const [];
  }

  @override
  Future<SensorReading?> fetchReadingById(String id) async {
    if (onFetchReadingById != null) {
      return onFetchReadingById!(id);
    }
    return null;
  }
}

void main() {
  group('HistoryController', () {
    test('inicia vacío, sin carga activa ni errores', () {
      final controller = HistoryController(
        supabaseService: _FakeSupabaseService(),
      );
      addTearDown(controller.dispose);

      expect(controller.readings, isEmpty);
      expect(controller.selectedFilter, isNull);
      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.isEmpty, isTrue);
      expect(controller.lastUpdatedAt, isNull);
    });

    test('loadReadings carga registros y actualiza lastUpdatedAt', () async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) async => const [
              SensorReading(
                id: 'r-1',
                sensorType: SensorType.accelerometer,
                x: 1,
                y: 2,
                z: 9.8,
              ),
            ];

      final controller = HistoryController(supabaseService: service);
      addTearDown(controller.dispose);

      await controller.loadReadings();

      expect(controller.isLoading, isFalse);
      expect(controller.hasError, isFalse);
      expect(controller.readings.length, 1);
      expect(controller.readings.first.id, 'r-1');
      expect(controller.lastUpdatedAt, isNotNull);
    });

    test(
        'setFilter consulta con el sensor seleccionado y evita recarga redundante',
        () async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (sensorType, _) async {
          if (sensorType == SensorType.gps) {
            return const [
              SensorReading(
                id: 'gps-1',
                sensorType: SensorType.gps,
                latitude: 1.0,
                longitude: -2.0,
              ),
            ];
          }
          return const [];
        };

      final controller = HistoryController(supabaseService: service);
      addTearDown(controller.dispose);

      await controller.setFilter(SensorType.gps);
      expect(controller.selectedFilter, SensorType.gps);
      expect(controller.readings.length, 1);

      // Volver a seleccionar el mismo filtro sin error no debe disparar nueva petición.
      await controller.setFilter(SensorType.gps);
      expect(service.requestedFilters, [SensorType.gps]);

      await controller.setFilter(null);
      expect(controller.selectedFilter, isNull);
      expect(service.requestedFilters, [SensorType.gps, null]);
    });

    test('maneja SupabaseServiceException y errores genéricos', () async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) async {
          throw const SupabaseServiceException('Sin conexión con Supabase.');
        };

      final controller = HistoryController(supabaseService: service);
      addTearDown(controller.dispose);

      await controller.loadReadings();
      expect(controller.hasError, isTrue);
      expect(controller.errorMessage, 'Sin conexión con Supabase.');
      expect(controller.isLoading, isFalse);

      service.onFetchReadings = (_, __) async {
        throw StateError('fallo inesperado');
      };
      await controller.refresh();
      expect(controller.hasError, isTrue);
      expect(
        controller.errorMessage,
        contains('error inesperado al cargar el historial'),
      );
    });

    test(
      'descarta respuestas obsoletas al cambiar de filtro rápidamente',
      () async {
        final firstCompleter = Completer<List<SensorReading>>();
        final secondCompleter = Completer<List<SensorReading>>();
        var callCount = 0;

        final service = _FakeSupabaseService()
          ..onFetchReadings = (_, __) {
            callCount++;
            return callCount == 1
                ? firstCompleter.future
                : secondCompleter.future;
          };

        final controller = HistoryController(supabaseService: service);
        addTearDown(controller.dispose);

        final firstCall = controller.loadReadings();
        final secondCall = controller.setFilter(SensorType.gyroscope);

        secondCompleter.complete(const [
          SensorReading(
            id: 'gyro-latest',
            sensorType: SensorType.gyroscope,
            x: 0.5,
            y: 0.6,
            z: 0.7,
          ),
        ]);
        await secondCall;

        firstCompleter.complete(const [
          SensorReading(
            id: 'stale-accel',
            sensorType: SensorType.accelerometer,
            x: 9.0,
            y: 0.0,
            z: 0.0,
          ),
        ]);
        await firstCall;

        expect(controller.selectedFilter, SensorType.gyroscope);
        expect(controller.readings.map((r) => r.id), ['gyro-latest']);
      },
    );

    test('no falla si dispose se llama con una consulta pendiente', () async {
      final completer = Completer<List<SensorReading>>();
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) => completer.future;

      final controller = HistoryController(supabaseService: service);
      final pending = controller.loadReadings();
      controller.dispose();

      completer.complete(const [
        SensorReading(id: 'late', sensorType: SensorType.gps),
      ]);
      await pending;

      expect(controller.readings, isEmpty);
    });

    test('fetchReadingDetail delega la consulta por ID al servicio', () async {
      final service = _FakeSupabaseService()
        ..onFetchReadingById = (id) async => SensorReading(
              id: id,
              sensorType: SensorType.gps,
              latitude: 4.5,
              longitude: -74.0,
            );

      final controller = HistoryController(supabaseService: service);
      addTearDown(controller.dispose);

      final result = await controller.fetchReadingDetail('abc-99');
      expect(result?.id, 'abc-99');
      expect(result?.latitude, 4.5);
    });
  });
}
