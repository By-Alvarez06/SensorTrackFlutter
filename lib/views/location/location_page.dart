import 'package:material_ui/material_ui.dart';

/// Vista stub de Fase 0 para el módulo de ubicación GPS.
///
/// Propiedad exclusiva en Fase 1: **Integrante 2** (`feature/int2-sensors-location`).
class LocationPage extends StatelessWidget {
  /// Crea una instancia de [LocationPage].
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación')),
      body: const Center(
        child: Text('Módulo de Ubicación GPS (Fase 1 - Integrante 2)'),
      ),
    );
  }
}
