import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/main.dart';

void main() {
  testWidgets(
    'SensorTrackApp muestra SplashPage y navega automáticamente a HomePage',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SensorTrackApp());

      // En el primer frame se renderiza SplashPage con el nombre de la app.
      expect(find.text('SensorTrack'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Avanzar el temporizador del Splash y completar la animación de ruta.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Una vez en HomePage deben mostrarse el estado y los 4 módulos.
      expect(find.text('Módulos disponibles'), findsOneWidget);
      expect(find.text('Sensores'), findsOneWidget);
      expect(find.text('Ubicación'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);
    },
  );
}
