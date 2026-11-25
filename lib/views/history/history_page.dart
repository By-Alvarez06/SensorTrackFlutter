import 'package:material_ui/material_ui.dart';

/// Vista stub de Fase 0 para el módulo de historial de mediciones.
///
/// Propiedad exclusiva en Fase 1: **Integrante 3** (`feature/int3-history-stats`).
class HistoryPage extends StatelessWidget {
  /// Crea una instancia de [HistoryPage].
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: const Center(
        child: Text('Módulo de Historial (Fase 1 - Integrante 3)'),
      ),
    );
  }
}
