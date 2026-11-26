import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/config/app_routes.dart';
import 'package:sensortrack_flutter/controllers/home_controller.dart';
import 'package:sensortrack_flutter/main.dart';
import 'package:sensortrack_flutter/models/sensor_type.dart';
import 'package:sensortrack_flutter/views/home/home_page.dart';
import 'package:sensortrack_flutter/views/sensors/sensors_page.dart';
import 'package:sensortrack_flutter/views/widgets/connection_status_badge.dart';
import 'package:sensortrack_flutter/views/widgets/loading_error_view.dart';

void main() {
  testWidgets(
    'SensorTrackApp muestra SplashPage y navega automáticamente a HomePage',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SensorTrackApp());

      expect(find.text('SensorTrack'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Menú principal'), findsOneWidget);
      expect(find.text('Sensores'), findsOneWidget);
      expect(find.text('Ubicación'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);
    },
  );

  testWidgets(
    'HomePage muestra estado de Supabase, sensores disponibles y navega a módulos',
    (WidgetTester tester) async {
      // Ampliamos el viewport de prueba para renderizar toda la lista sin recortes.
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = HomeController(
        isConfiguredChecker: () => true,
        connectionChecker: () async => true,
        sensorProbe: (type) async =>
            type == SensorType.accelerometer || type == SensorType.gps,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.home: (_) => HomePage(controller: controller),
            AppRoutes.sensors: (_) => const SensorsPage(),
          },
          initialRoute: AppRoutes.home,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ConnectionStatusBadge), findsOneWidget);
      expect(find.text('Supabase conectado'), findsOneWidget);
      expect(find.text('2 de 5 disponibles'), findsOneWidget);
      expect(find.text('Disponible'), findsNWidgets(2));
      expect(find.text('No disponible'), findsNWidgets(3));

      await tester.tap(find.text('Sensores'));
      await tester.pumpAndSettle();

      expect(find.byType(SensorsPage), findsOneWidget);
    },
  );

  testWidgets('LoadingErrorView renderiza estados loading, error y empty', (
    WidgetTester tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingErrorView.loading(message: 'Cargando mediciones...'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando mediciones...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingErrorView.error(
            message: 'Error de conexión',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.text('Error de conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingErrorView.empty(message: 'Sin registros aún'),
        ),
      ),
    );
    expect(find.text('Sin registros aún'), findsOneWidget);
  });
}
