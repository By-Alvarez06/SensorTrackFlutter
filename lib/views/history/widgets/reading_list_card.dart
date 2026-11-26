import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_reading.dart';
import 'history_formatters.dart';

/// Tarjeta resumida de una medición individual dentro de la lista del historial.
class ReadingListCard extends StatelessWidget {
  /// Medición de sensor a mostrar en la tarjeta.
  final SensorReading reading;

  /// Acción ejecutada al pulsar la tarjeta para abrir su detalle completo.
  final VoidCallback onTap;

  /// Crea una instancia de [ReadingListCard].
  const ReadingListCard({
    super.key,
    required this.reading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = HistoryFormatters.sensorColor(
      reading.sensorType,
      colorScheme,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HistoryFormatters.sensorIcon(reading.sensorType),
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reading.sensorType.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildValuesSummary(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (reading.hasLocation &&
                        reading.accuracy != null &&
                        reading.accuracy!.isFinite) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Precisión: ${HistoryFormatters.formatAccuracy(reading.accuracy)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            HistoryFormatters.formatDateTime(
                              reading.recordedAt,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la línea resumida de valores según los campos presentes en [reading].
  String _buildValuesSummary() {
    if (reading.x != null || reading.y != null || reading.z != null) {
      final x = HistoryFormatters.formatAxis(reading.x);
      final y = HistoryFormatters.formatAxis(reading.y);
      final z = HistoryFormatters.formatAxis(reading.z);
      return 'X: $x · Y: $y · Z: $z (${reading.sensorType.unit})';
    }

    if (reading.hasLocation) {
      final lat = HistoryFormatters.formatCoordinate(reading.latitude);
      final lon = HistoryFormatters.formatCoordinate(reading.longitude);
      return 'Lat: $lat · Lon: $lon';
    }

    return 'Sin valores registrados';
  }
}
