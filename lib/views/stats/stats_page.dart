import 'package:material_ui/material_ui.dart';

/// Vista stub de Fase 0 para el módulo de estadísticas y gráficos.
///
/// Propiedad exclusiva en Fase 1: **Integrante 3** (`feature/int3-history-stats`).
class StatsPage extends StatelessWidget {
  /// Crea una instancia de [StatsPage].
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: const Center(
        child: Text('Módulo de Estadísticas (Fase 1 - Integrante 3)'),
      ),
    );
  }
}
