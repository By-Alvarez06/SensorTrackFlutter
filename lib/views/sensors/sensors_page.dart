import 'package:material_ui/material_ui.dart';

/// Vista stub de Fase 0 para el módulo de monitoreo de sensores.
///
/// Propiedad exclusiva en Fase 1: **Integrante 2** (`feature/int2-sensors-location`).
class SensorsPage extends StatelessWidget {
  /// Crea una instancia de [SensorsPage].
  const SensorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores')),
      body: const Center(
        child: Text('Módulo de Sensores (Fase 1 - Integrante 2)'),
      ),
    );
  }
}
