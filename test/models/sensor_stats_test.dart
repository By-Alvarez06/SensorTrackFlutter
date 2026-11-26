import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_stats.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';

void main() {
  group('SensorStats', () {
    test('retorna resumen vacío para una lista vacía', () {
      final stats = SensorStats.fromReadings(const []);

      expect(stats.totalReadings, 0);
      expect(stats.hasData, isFalse);
      expect(stats.accelerometerExtremes, isNull);
      expect(stats.lastLocation, isNull);
      expect(stats.accelerometerSeries, isEmpty);
      expect(stats.gyroscopeSeries, isEmpty);
      expect(stats.gpsAccuracySeries, isEmpty);

      for (final type in SensorType.values) {
        expect(stats.countFor(type), 0);
      }
    });

    test(
        'calcula conteos mixtos, extremos negativos del acelerómetro y series ascendentes',
        () {
      final t1 = DateTime.utc(2026, 11, 25, 10, 0);
      final t2 = DateTime.utc(2026, 11, 25, 10, 5);
      final t3 = DateTime.utc(2026, 11, 25, 10, 10);

      // Orden descendente simulando respuesta de SupabaseService.fetchReadings.
      final readings = [
        SensorReading(
          id: 'gps-1',
          sensorType: SensorType.gps,
          latitude: -0.180653,
          longitude: -78.467834,
          accuracy: 4.5,
          recordedAt: t3,
        ),
        SensorReading(
          id: 'accel-2',
          sensorType: SensorType.accelerometer,
          x: -8.5,
          y: -1.2,
          z: -3.0,
          recordedAt: t2,
        ),
        SensorReading(
          id: 'gyro-1',
          sensorType: SensorType.gyroscope,
          x: 0.4,
          y: -0.2,
          z: 0.1,
          recordedAt: t2,
        ),
        SensorReading(
          id: 'accel-1',
          sensorType: SensorType.accelerometer,
          x: -2.0,
          y: -4.0,
          z: -1.5,
          recordedAt: t1,
        ),
        SensorReading(
          id: 'light-1',
          sensorType: SensorType.light,
          x: 320.0,
          recordedAt: t1,
        ),
      ];

      final stats = SensorStats.fromReadings(readings);

      expect(stats.totalReadings, 5);
      expect(stats.hasData, isTrue);
      expect(stats.countFor(SensorType.accelerometer), 2);
      expect(stats.countFor(SensorType.gyroscope), 1);
      expect(stats.countFor(SensorType.gps), 1);
      expect(stats.countFor(SensorType.light), 1);
      expect(stats.countFor(SensorType.magnetometer), 0);

      final extremes = stats.accelerometerExtremes!;
      expect(extremes.sampleCount, 2);
      expect(extremes.minX, -8.5);
      expect(extremes.maxX, -2.0);
      expect(extremes.minY, -4.0);
      expect(extremes.maxY, -1.2);
      expect(extremes.minZ, -3.0);
      expect(extremes.maxZ, -1.5);
      // Todos los valores fueron negativos; overallMax no debe ser 0.0.
      expect(extremes.overallMin, -8.5);
      expect(extremes.overallMax, -1.2);
      expect(
        extremes.minMagnitude,
        closeTo(math.sqrt(2.0 * 2.0 + 4.0 * 4.0 + 1.5 * 1.5), 1e-9),
      );
      expect(
        extremes.maxMagnitude,
        closeTo(math.sqrt(8.5 * 8.5 + 1.2 * 1.2 + 3.0 * 3.0), 1e-9),
      );

      // Las series deben quedar ordenadas cronológicamente ascendentes.
      expect(stats.accelerometerSeries.length, 2);
      expect(stats.accelerometerSeries.first.index, 0);
      expect(stats.accelerometerSeries.first.x, -2.0);
      expect(stats.accelerometerSeries.last.index, 1);
      expect(stats.accelerometerSeries.last.x, -8.5);

      expect(stats.gyroscopeSeries.length, 1);
      expect(stats.gpsAccuracySeries.length, 1);
      expect(stats.gpsAccuracySeries.first.magnitude, 4.5);
    });

    test('ignora valores NaN, infinitos y ejes parciales sin fallar', () {
      final readings = [
        const SensorReading(
          sensorType: SensorType.accelerometer,
          x: double.nan,
          y: double.infinity,
          z: 5.0,
        ),
        const SensorReading(
          sensorType: SensorType.accelerometer,
          x: double.nan,
          y: double.nan,
          z: double.nan,
        ),
        const SensorReading(
          sensorType: SensorType.gps,
          latitude: 1.0,
          longitude: 2.0,
          accuracy: double.nan,
        ),
      ];

      final stats = SensorStats.fromReadings(readings);

      expect(stats.totalReadings, 3);
      expect(stats.accelerometerExtremes, isNotNull);
      expect(stats.accelerometerExtremes!.sampleCount, 1);
      expect(stats.accelerometerExtremes!.minX, isNull);
      expect(stats.accelerometerExtremes!.minZ, 5.0);
      expect(stats.accelerometerExtremes!.maxZ, 5.0);
      expect(stats.accelerometerExtremes!.overallMin, 5.0);
      expect(stats.accelerometerExtremes!.overallMax, 5.0);
      expect(stats.accelerometerExtremes!.minMagnitude, isNull);
      expect(stats.accelerometerSeries.length, 1);
      expect(stats.gpsAccuracySeries, isEmpty);
      expect(stats.lastLocation, isNotNull);
    });

    test(
      'selecciona la última ubicación según recordedAt sin asumir orden',
      () {
        final oldest = SensorReading(
          id: 'gps-old',
          sensorType: SensorType.gps,
          latitude: 10.0,
          longitude: -70.0,
          accuracy: 12.0,
          recordedAt: DateTime.utc(2026, 11, 25, 8, 0),
        );
        final newest = SensorReading(
          id: 'gps-new',
          sensorType: SensorType.gps,
          latitude: 11.0,
          longitude: -71.0,
          accuracy: 3.0,
          recordedAt: DateTime.utc(2026, 11, 25, 12, 30),
        );
        final middle = SensorReading(
          id: 'gps-mid',
          sensorType: SensorType.gps,
          latitude: 10.5,
          longitude: -70.5,
          accuracy: 6.0,
          recordedAt: DateTime.utc(2026, 11, 25, 10, 0),
        );

        final stats = SensorStats.fromReadings([oldest, newest, middle]);

        expect(stats.lastLocation?.id, 'gps-new');
        expect(stats.gpsAccuracySeries.map((p) => p.magnitude), [
          12.0,
          6.0,
          3.0,
        ]);
      },
    );
  });
}
