import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';
import 'package:sensortrack_flutter/views/stats/stats_page.dart';

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
  testWidgets(
    'StatsPage muestra carga inicial y estado vacío sin excepciones',
    (tester) async {
      final completer = Completer<List<SensorReading>>();
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) => completer.future;

      await tester.pumpWidget(
        MaterialApp(home: StatsPage(supabaseService: service)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Calculando estadísticas...'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay estadísticas disponibles'), findsOneWidget);
    },
  );

  testWidgets('StatsPage maneja errores y permite reintentar', (tester) async {
    var shouldFail = true;
    final service = _FakeSupabaseService()
      ..onFetchReadings = (_, __) async {
        if (shouldFail) {
          throw const SupabaseServiceException('Fallo consultando Supabase.');
        }
        return [
          SensorReading(
            id: 'single-1',
            sensorType: SensorType.accelerometer,
            x: 2.0,
            y: 2.0,
            z: 2.0,
            recordedAt: DateTime.utc(2026, 11, 25, 16, 0),
          ),
        ];
      };

    await tester.pumpWidget(
      MaterialApp(home: StatsPage(supabaseService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar las estadísticas'), findsOneWidget);
    expect(find.text('Fallo consultando Supabase.'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Total de registros'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(LineChart),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets(
    'StatsPage renderiza todas las métricas y gráfico fl_chart con serie plana y cambio de sensor',
    (tester) async {
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) async => [
              SensorReading(
                id: 'gps-latest',
                sensorType: SensorType.gps,
                latitude: -0.180653,
                longitude: -78.467834,
                accuracy: 6.4,
                recordedAt: DateTime.utc(2026, 11, 25, 18, 30),
              ),
              SensorReading(
                id: 'gyro-1',
                sensorType: SensorType.gyroscope,
                x: 0.5,
                y: 0.5,
                z: 0.5,
                recordedAt: DateTime.utc(2026, 11, 25, 18, 25),
              ),
              SensorReading(
                id: 'gyro-2',
                sensorType: SensorType.gyroscope,
                x: 0.5,
                y: 0.5,
                z: 0.5,
                recordedAt: DateTime.utc(2026, 11, 25, 18, 20),
              ),
              SensorReading(
                id: 'acc-2',
                sensorType: SensorType.accelerometer,
                x: 1.5,
                y: -2.0,
                z: 9.8,
                recordedAt: DateTime.utc(2026, 11, 25, 18, 15),
              ),
              SensorReading(
                id: 'acc-1',
                sensorType: SensorType.accelerometer,
                x: -3.5,
                y: 0.5,
                z: 9.2,
                recordedAt: DateTime.utc(2026, 11, 25, 18, 10),
              ),
            ];

      await tester.pumpWidget(
        MaterialApp(home: StatsPage(supabaseService: service)),
      );
      await tester.pumpAndSettle();

      // Métricas solicitadas por el Módulo 5.
      expect(find.text('Total de registros'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Mediciones por sensor'), findsOneWidget);
      expect(find.text('Acelerómetro — Máximos y mínimos'), findsOneWidget);
      expect(find.text('-3.50 m/s²'), findsOneWidget);
      expect(find.text('9.80 m/s²'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Última ubicación registrada'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Última ubicación registrada'), findsOneWidget);
      expect(find.text('-0.180653°'), findsOneWidget);
      expect(find.text('-78.467834°'), findsOneWidget);
      expect(find.text('6.4 m'), findsOneWidget);

      // Desplazar hasta el gráfico y probar cambio a Giroscopio (serie plana) y GPS.
      await tester.scrollUntilVisible(
        find.byType(LineChart),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(LineChart), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Giroscopio'));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.textContaining('2 punto(s)'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'GPS / Ubicación'));
      await tester.pumpAndSettle();
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Precisión (m)'), findsOneWidget);
    },
  );
}
