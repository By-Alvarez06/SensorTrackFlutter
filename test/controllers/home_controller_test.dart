import 'package:flutter_test/flutter_test.dart';
import 'package:sensortrack_flutter/controllers/home_controller.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';

void main() {
  group('HomeController', () {
    test(
      'marca notConfigured cuando faltan credenciales de Supabase',
      () async {
        final controller = HomeController(
          isConfiguredChecker: () => false,
          sensorProbe: (_) async => false,
        );

        await controller.checkSupabaseConnection();

        expect(
          controller.connectionStatus,
          SupabaseConnectionStatus.notConfigured,
        );
        expect(controller.connectionMessage, contains('--dart-define'));

        controller.dispose();
      },
    );

    test('marca connected cuando connectionChecker devuelve true', () async {
      final controller = HomeController(
        isConfiguredChecker: () => true,
        connectionChecker: () async => true,
        sensorProbe: (_) async => true,
      );

      await controller.checkSupabaseConnection();

      expect(controller.connectionStatus, SupabaseConnectionStatus.connected);
      expect(controller.connectionMessage, contains('operativa'));

      controller.dispose();
    });

    test(
      'marca disconnected cuando connectionChecker falla o lanza error',
      () async {
        final failedController = HomeController(
          isConfiguredChecker: () => true,
          connectionChecker: () async => false,
          sensorProbe: (_) async => false,
        );
        await failedController.checkSupabaseConnection();
        expect(
          failedController.connectionStatus,
          SupabaseConnectionStatus.disconnected,
        );
        failedController.dispose();

        final throwingController = HomeController(
          isConfiguredChecker: () => true,
          connectionChecker: () async => throw Exception('Timeout'),
          sensorProbe: (_) async => false,
        );
        await throwingController.checkSupabaseConnection();
        expect(
          throwingController.connectionStatus,
          SupabaseConnectionStatus.disconnected,
        );
        throwingController.dispose();
      },
    );

    test(
      'refresh evalúa sensores disponibles, no disponibles y excepciones',
      () async {
        final controller = HomeController(
          isConfiguredChecker: () => true,
          connectionChecker: () async => true,
          sensorProbe: (type) async {
            return switch (type) {
              SensorType.accelerometer => true,
              SensorType.gyroscope => true,
              SensorType.gps => throw StateError('Error de plataforma'),
              SensorType.magnetometer => false,
              SensorType.light => false,
            };
          },
        );

        await controller.refresh();

        expect(controller.isRefreshing, isFalse);
        expect(controller.lastCheckedAt, isNotNull);
        expect(controller.sensors.length, SensorType.values.length);
        expect(controller.availableSensorsCount, 2);

        final gpsItem = controller.sensors.firstWhere(
          (item) => item.sensorType == SensorType.gps,
        );
        expect(gpsItem.status, SensorAvailabilityStatus.unavailable);

        controller.dispose();
      },
    );

    test(
      'dispose evita notificaciones posteriores sin lanzar errores',
      () async {
        var notifyCount = 0;
        final controller = HomeController(
          isConfiguredChecker: () => true,
          connectionChecker: () async => true,
          sensorProbe: (_) async => true,
        );
        controller.addListener(() => notifyCount++);

        controller.dispose();
        await controller.refresh();

        expect(notifyCount, 0);
      },
    );
  });
}
