import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';

void main() {
  group('SensorType', () {
    test('expone dbValue, displayName y unit correctos para cada sensor', () {
      expect(SensorType.accelerometer.dbValue, 'accelerometer');
      expect(SensorType.accelerometer.displayName, 'Acelerómetro');
      expect(SensorType.accelerometer.unit, 'm/s²');

      expect(SensorType.gyroscope.dbValue, 'gyroscope');
      expect(SensorType.gyroscope.displayName, 'Giroscopio');

      expect(SensorType.gps.dbValue, 'gps');
      expect(SensorType.gps.displayName, 'GPS / Ubicación');

      expect(SensorType.magnetometer.dbValue, 'magnetometer');
      expect(SensorType.light.dbValue, 'light');
    });

    test(
      'fromDbValue normaliza mayúsculas/espacios y falla si es inválido',
      () {
        expect(
          SensorType.fromDbValue('  ACCELEROMETER '),
          SensorType.accelerometer,
        );
        expect(SensorType.fromDbValue('Gyroscope'), SensorType.gyroscope);
        expect(SensorType.fromDbValue('gps'), SensorType.gps);

        expect(
          () => SensorType.fromDbValue('unknown_sensor'),
          throwsArgumentError,
        );
      },
    );
  });

  group('SensorReading', () {
    test('fromJson convierte enteros, decimales y fecha ISO-8601', () {
      final reading = SensorReading.fromJson({
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'sensor_type': 'accelerometer',
        'x': 1,
        'y': -2.5,
        'z': 9.81,
        'recorded_at': '2026-11-25T18:00:00.000Z',
      });

      expect(reading.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(reading.sensorType, SensorType.accelerometer);
      expect(reading.x, 1.0);
      expect(reading.y, -2.5);
      expect(reading.z, 9.81);
      expect(reading.hasAxisValues, isTrue);
      expect(reading.hasLocation, isFalse);
      expect(reading.recordedAt, DateTime.utc(2026, 11, 25, 18));
    });

    test('fromJson soporta registro GPS con campos de ejes nulos', () {
      final reading = SensorReading.fromJson({
        'sensor_type': 'gps',
        'latitude': -0.180653,
        'longitude': -78.467834,
        'accuracy': 4.5,
      });

      expect(reading.sensorType, SensorType.gps);
      expect(reading.hasAxisValues, isFalse);
      expect(reading.hasLocation, isTrue);
      expect(reading.latitude, -0.180653);
      expect(reading.longitude, -78.467834);
      expect(reading.accuracy, 4.5);
      expect(reading.recordedAt, isNull);
    });

    test('fromJson lanza FormatException si falta sensor_type', () {
      expect(() => SensorReading.fromJson({'x': 1.0}), throwsFormatException);
    });

    test('toJson omite id y recorded_at cuando son null', () {
      const reading = SensorReading(
        sensorType: SensorType.gyroscope,
        x: 0.1,
        y: 0.2,
        z: 0.3,
      );

      final json = reading.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('recorded_at'), isFalse);
      expect(json.containsKey('latitude'), isFalse);
      expect(json, {'sensor_type': 'gyroscope', 'x': 0.1, 'y': 0.2, 'z': 0.3});
    });

    test('toJson incluye id y recorded_at en UTC cuando están presentes', () {
      final timestamp = DateTime.utc(2026, 11, 25, 20, 30);
      final reading = SensorReading(
        id: 'abc-123',
        sensorType: SensorType.gps,
        latitude: 1.5,
        longitude: -2.5,
        accuracy: 10.0,
        recordedAt: timestamp,
      );

      expect(reading.toJson(), {
        'id': 'abc-123',
        'sensor_type': 'gps',
        'latitude': 1.5,
        'longitude': -2.5,
        'accuracy': 10.0,
        'recorded_at': '2026-11-25T20:30:00.000Z',
      });
    });

    test('copyWith e igualdad funcionan correctamente', () {
      const original = SensorReading(
        sensorType: SensorType.accelerometer,
        x: 1.0,
        y: 2.0,
        z: 3.0,
      );

      final copy = original.copyWith(z: 9.8);

      expect(copy.x, 1.0);
      expect(copy.y, 2.0);
      expect(copy.z, 9.8);
      expect(copy, isNot(original));
      expect(original.copyWith(), original);
      expect(original.copyWith().hashCode, original.hashCode);
    });
  });
}
