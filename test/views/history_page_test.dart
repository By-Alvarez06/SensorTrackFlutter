import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/models/sensor_reading.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/services/supabase_service.dart';
import 'package:sensortrack_flutter/views/history/history_page.dart';
import 'package:sensortrack_flutter/views/history/reading_detail_page.dart';

class _FakeSupabaseService extends SupabaseService {
  Future<List<SensorReading>> Function(SensorType? sensorType, int limit)?
      onFetchReadings;
  Future<SensorReading?> Function(String id)? onFetchReadingById;

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

  @override
  Future<SensorReading?> fetchReadingById(String id) async {
    if (onFetchReadingById != null) {
      return onFetchReadingById!(id);
    }
    return null;
  }
}

void main() {
  testWidgets(
    'HistoryPage muestra indicador de carga mientras consulta datos',
    (tester) async {
      final completer = Completer<List<SensorReading>>();
      final service = _FakeSupabaseService()
        ..onFetchReadings = (_, __) => completer.future;

      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(supabaseService: service)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando historial desde Supabase...'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();

      expect(find.text('Aún no hay mediciones guardadas'), findsOneWidget);
    },
  );

  testWidgets('HistoryPage muestra error y permite reintentar con éxito', (
    tester,
  ) async {
    var shouldFail = true;
    final service = _FakeSupabaseService()
      ..onFetchReadings = (_, __) async {
        if (shouldFail) {
          throw const SupabaseServiceException('Error de conexión temporal.');
        }
        return [
          SensorReading(
            id: 'acc-1',
            sensorType: SensorType.accelerometer,
            x: 1.25,
            y: -0.5,
            z: 9.81,
            recordedAt: DateTime.utc(2026, 11, 25, 14, 0),
          ),
        ];
      };

    await tester.pumpWidget(
      MaterialApp(home: HistoryPage(supabaseService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el historial'), findsOneWidget);
    expect(find.text('Error de conexión temporal.'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('1 registro encontrado'), findsOneWidget);
    expect(find.textContaining('X: 1.25'), findsOneWidget);
  });

  testWidgets(
    'HistoryPage filtra por sensor y abre ReadingDetailPage con detalles completos',
    (tester) async {
      final allReadings = [
        SensorReading(
          id: 'uuid-accel-1',
          sensorType: SensorType.accelerometer,
          x: 3.0,
          y: 4.0,
          z: 0.0,
          recordedAt: DateTime.utc(2026, 11, 25, 15, 0),
        ),
        SensorReading(
          id: 'uuid-gps-1',
          sensorType: SensorType.gps,
          latitude: -0.180653,
          longitude: -78.467834,
          accuracy: 5.2,
          recordedAt: DateTime.utc(2026, 11, 25, 15, 5),
        ),
      ];

      final service = _FakeSupabaseService()
        ..onFetchReadings = (sensorType, _) async {
          if (sensorType == null) return allReadings;
          return allReadings
              .where((reading) => reading.sensorType == sensorType)
              .toList();
        };

      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(supabaseService: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 registros encontrados'), findsOneWidget);
      expect(find.textContaining('Lat: -0.180653°'), findsOneWidget);

      // Filtrar por GPS desde la barra de chips.
      await tester.tap(find.widgetWithText(ChoiceChip, 'GPS / Ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('1 registro encontrado'), findsOneWidget);
      expect(find.textContaining('Precisión: 5.2 m'), findsOneWidget);

      // Limpiar filtro y abrir el detalle del registro de acelerómetro.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('X: 3.00'));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingDetailPage), findsOneWidget);
      expect(find.text('Detalle de medición'), findsOneWidget);
      expect(find.text('uuid-accel-1'), findsOneWidget);
      expect(find.text('5.0000 m/s²'), findsOneWidget);
    },
  );
}
