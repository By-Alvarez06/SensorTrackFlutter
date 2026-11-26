import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/views/sensors/sensors_page.dart';

void main() {
  testWidgets('SensorsPage renderiza títulos, tarjetas de sensores y controles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SensorsPage(),
      ),
    );

    // Verificar AppBar
    expect(find.text('Monitoreo de Sensores'), findsOneWidget);

    // Verificar tarjeta de estado de monitoreo
    expect(find.text('Monitoreo detenido'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);

    // Verificar tarjetas de Acelerómetro y Giroscopio
    expect(find.text('Acelerómetro'), findsOneWidget);
    expect(find.text('Giroscopio'), findsOneWidget);
    expect(find.text('(m/s²)'), findsOneWidget);
    expect(find.text('(rad/s)'), findsOneWidget);

    // Verificar botones de guardar medición
    expect(find.text('Guardar medición'), findsNWidgets(2));
  });
}
