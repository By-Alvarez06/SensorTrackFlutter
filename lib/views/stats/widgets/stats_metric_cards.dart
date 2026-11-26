import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_reading.dart';
import '../../../models/sensor_stats.dart';
import '../../../models/sensor_type.dart';
import 'stats_formatters.dart';

/// Tarjeta que muestra la cantidad total de registros procesados.
class TotalReadingsCard extends StatelessWidget {
  /// Cantidad total de mediciones incluidas en el resumen estadístico.
  final int totalReadings;

  /// Hora de la última actualización exitosa, si existe.
  final DateTime? lastUpdatedAt;

  /// Crea una instancia de [TotalReadingsCard].
  const TotalReadingsCard({
    super.key,
    required this.totalReadings,
    this.lastUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.dataset_outlined,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de registros',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalReadings',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (lastUpdatedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Actualizado: ${StatsFormatters.formatDateTime(lastUpdatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta que desglosa el número de mediciones registradas por cada sensor.
class SensorBreakdownCard extends StatelessWidget {
  /// Estadísticas agregadas de las mediciones.
  final SensorStats stats;

  /// Crea una instancia de [SensorBreakdownCard].
  const SensorBreakdownCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Se muestran siempre los 3 sensores obligatorios y los opcionales si tienen datos.
    final visibleTypes = <SensorType>[
      SensorType.accelerometer,
      SensorType.gyroscope,
      SensorType.gps,
      if (stats.countFor(SensorType.magnetometer) > 0) SensorType.magnetometer,
      if (stats.countFor(SensorType.light) > 0) SensorType.light,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Mediciones por sensor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final type in visibleTypes)
              _SensorCountRow(
                type: type,
                count: stats.countFor(type),
                total: stats.totalReadings,
              ),
          ],
        ),
      ),
    );
  }
}

class _SensorCountRow extends StatelessWidget {
  final SensorType type;
  final int count;
  final int total;

  const _SensorCountRow({
    required this.type,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = StatsFormatters.sensorColor(type, colorScheme);
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(StatsFormatters.sensorIcon(type), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  type.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count ($percentage%)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con los valores máximos y mínimos registrados del acelerómetro.
class AccelerometerExtremesCard extends StatelessWidget {
  /// Extremos calculados del acelerómetro, o `null` si no existen muestras.
  final AccelerometerExtremes? extremes;

  /// Crea una instancia de [AccelerometerExtremesCard].
  const AccelerometerExtremesCard({super.key, required this.extremes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acelerómetro — Máximos y mínimos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (extremes == null)
              Text(
                'Aún no hay mediciones de acelerómetro para calcular extremos.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _HighlightValueBox(
                      label: 'Mínimo global',
                      value:
                          '${StatsFormatters.formatNumber(extremes!.overallMin)} m/s²',
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HighlightValueBox(
                      label: 'Máximo global',
                      value:
                          '${StatsFormatters.formatNumber(extremes!.overallMax)} m/s²',
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AxisExtremeRow(
                axisLabel: 'Eje X',
                minValue: extremes!.minX,
                maxValue: extremes!.maxX,
              ),
              _AxisExtremeRow(
                axisLabel: 'Eje Y',
                minValue: extremes!.minY,
                maxValue: extremes!.maxY,
              ),
              _AxisExtremeRow(
                axisLabel: 'Eje Z',
                minValue: extremes!.minZ,
                maxValue: extremes!.maxZ,
              ),
              if (extremes!.minMagnitude != null &&
                  extremes!.maxMagnitude != null)
                _AxisExtremeRow(
                  axisLabel: 'Magnitud',
                  minValue: extremes!.minMagnitude,
                  maxValue: extremes!.maxMagnitude,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightValueBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HighlightValueBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisExtremeRow extends StatelessWidget {
  final String axisLabel;
  final double? minValue;
  final double? maxValue;

  const _AxisExtremeRow({
    required this.axisLabel,
    required this.minValue,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minText = StatsFormatters.formatNumber(minValue);
    final maxText = StatsFormatters.formatNumber(maxValue);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              axisLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Mín: $minText m/s²',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Máx: $maxText m/s²',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que muestra la última ubicación GPS registrada en Supabase.
class LastLocationCard extends StatelessWidget {
  /// Lectura GPS más reciente, o `null` si no existe ninguna.
  final SensorReading? lastLocation;

  /// Crea una instancia de [LastLocationCard].
  const LastLocationCard({super.key, required this.lastLocation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Última ubicación registrada',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastLocation == null)
              Text(
                'Aún no se han guardado coordenadas GPS en Supabase.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _LocationRow(
                label: 'Latitud',
                value: StatsFormatters.formatCoordinate(lastLocation!.latitude),
              ),
              _LocationRow(
                label: 'Longitud',
                value: StatsFormatters.formatCoordinate(
                  lastLocation!.longitude,
                ),
              ),
              _LocationRow(
                label: 'Precisión',
                value: StatsFormatters.formatAccuracy(lastLocation!.accuracy),
              ),
              _LocationRow(
                label: 'Capturada el',
                value: StatsFormatters.formatDateTime(lastLocation!.recordedAt),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String label;
  final String value;

  const _LocationRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
