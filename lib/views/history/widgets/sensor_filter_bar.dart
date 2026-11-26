import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_type.dart';
import 'history_formatters.dart';

/// Barra horizontal de filtros por tipo de sensor para la pantalla de historial.
class SensorFilterBar extends StatelessWidget {
  /// Filtro actualmente seleccionado, o `null` cuando se muestran todos.
  final SensorType? selectedFilter;

  /// Callback invocado cuando el usuario selecciona un filtro distinto.
  final ValueChanged<SensorType?> onFilterChanged;

  /// Habilita o deshabilita la interacción mientras ocurre una carga.
  final bool isEnabled;

  /// Crea una instancia de [SensorFilterBar].
  const SensorFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Todos'),
              selected: selectedFilter == null,
              onSelected: isEnabled ? (_) => onFilterChanged(null) : null,
            ),
          ),
          for (final type in SensorType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(HistoryFormatters.sensorIcon(type), size: 18),
                label: Text(type.displayName),
                selected: selectedFilter == type,
                onSelected: isEnabled ? (_) => onFilterChanged(type) : null,
              ),
            ),
        ],
      ),
    );
  }
}
