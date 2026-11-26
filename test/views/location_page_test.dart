import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensortrack_flutter/views/location/location_page.dart';

void main() {
  testWidgets('LocationPage renderiza vista de ubicación y controles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPage(),
      ),
    );

    // Verificar AppBar y encabezados
    expect(find.text('Ubicación GPS'), findsOneWidget);
    expect(find.text('Obtener mi ubicación actual'), findsOneWidget);
    expect(find.text('Coordenadas Geográficas'), findsOneWidget);
    expect(
        find.text('Aún no se ha capturado la ubicación GPS.'), findsOneWidget);

    // Verificar botones de acceso a ajustes
    expect(find.text('Ajustes GPS'), findsOneWidget);
    expect(find.text('Permisos App'), findsOneWidget);
  });
}
