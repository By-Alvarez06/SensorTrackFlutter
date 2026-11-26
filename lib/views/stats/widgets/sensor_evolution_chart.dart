import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_stats.dart';
import '../../../models/sensor_type.dart';
import 'stats_formatters.dart';

/// Tarjeta con el gráfico de evolución temporal de mediciones usando `fl_chart`.
///
/// Permite alternar entre Acelerómetro, Giroscopio y GPS, y protege el renderizado
/// frente a series vacías, de un único punto o con valores constantes (`minY == maxY`).
class SensorEvolutionChartCard extends StatelessWidget {
  /// Resumen estadístico con las series temporales por sensor.
  final SensorStats stats;

  /// Sensor seleccionado actualmente para graficar.
  final SensorType selectedSensor;

  /// Callback invocado cuando el usuario cambia de sensor en el selector.
  final ValueChanged<SensorType> onSensorSelected;

  /// Crea una instancia de [SensorEvolutionChartCard].
  const SensorEvolutionChartCard({
    super.key,
    required this.stats,
    required this.selectedSensor,
    required this.onSensorSelected,
  });

  static const List<SensorType> _chartSensors = [
    SensorType.accelerometer,
    SensorType.gyroscope,
    SensorType.gps,
  ];

  static const Color _xColor = Color(0xFF0F6CBD);
  static const Color _yColor = Color(0xFF107C10);
  static const Color _zColor = Color(0xFFD83B01);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final series = stats.seriesFor(selectedSensor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evolución de mediciones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final sensor in _chartSensors)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          StatsFormatters.sensorIcon(sensor),
                          size: 18,
                        ),
                        label: Text(sensor.displayName),
                        selected: selectedSensor == sensor,
                        onSelected: (_) => onSensorSelected(sensor),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (series.isEmpty)
              _EmptyChartPlaceholder(sensor: selectedSensor)
            else ...[
              _ChartLegend(
                selectedSensor: selectedSensor,
                gpsColor: colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: LineChart(_buildChartData(context, series)),
              ),
              const SizedBox(height: 6),
              Text(
                selectedSensor == SensorType.gps
                    ? 'Unidad: metros (precisión GPS) · ${series.length} punto(s)'
                    : 'Unidad: ${selectedSensor.unit} · ${series.length} punto(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(
    BuildContext context,
    List<SensorEvolutionPoint> series,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSinglePoint = series.length == 1;

    // Cuando hay un único punto se centra horizontalmente en [-0.5, 0.5] para
    // evitar que fl_chart intente dibujar un rango X de ancho cero.
    final double minX = isSinglePoint ? -0.5 : 0.0;
    final double maxX = isSinglePoint ? 0.5 : (series.length - 1).toDouble();

    final bounds = _computeYBounds(series, selectedSensor);
    final double verticalSpan = bounds.maxY - bounds.minY;
    final double horizontalInterval = verticalSpan > 0 ? verticalSpan / 4 : 1.0;

    final double bottomInterval =
        series.length <= 5 ? 1.0 : ((series.length - 1) / 4).ceilToDouble();

    final lineBars = _buildLineBars(
      series: series,
      selectedSensor: selectedSensor,
      gpsColor: colorScheme.secondary,
      showDots: isSinglePoint || series.length <= 20,
    );

    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: bounds.minY,
      maxY: bounds.maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        horizontalInterval: horizontalInterval,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: horizontalInterval,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              axisSide: meta.axisSide,
              space: 6,
              child: Text(
                value.toStringAsFixed(1),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: bottomInterval,
            getTitlesWidget: (value, meta) {
              // Solo se etiquetan índices enteros válidos dentro de la serie.
              if ((value - value.roundToDouble()).abs() > 0.01) {
                return const SizedBox.shrink();
              }
              final index = value.round();
              if (index < 0 || index >= series.length) {
                return const SizedBox.shrink();
              }
              final shortTime = StatsFormatters.formatShortTime(
                series[index].recordedAt,
              );
              final label = shortTime.isNotEmpty ? shortTime : '#${index + 1}';
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 6,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => colorScheme.inverseSurface,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final seriesName = _seriesNameForBar(
                selectedSensor,
                spot.barIndex,
              );
              return LineTooltipItem(
                '$seriesName: ${spot.y.toStringAsFixed(2)}',
                TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: lineBars,
    );
  }

  List<LineChartBarData> _buildLineBars({
    required List<SensorEvolutionPoint> series,
    required SensorType selectedSensor,
    required Color gpsColor,
    required bool showDots,
  }) {
    if (selectedSensor == SensorType.gps) {
      final spots = [
        for (final point in series)
          if (point.magnitude != null && point.magnitude!.isFinite)
            FlSpot(point.index.toDouble(), point.magnitude!),
      ];
      return [
        LineChartBarData(
          spots: spots,
          isCurved: spots.length > 2,
          preventCurveOverShooting: true,
          color: gpsColor,
          barWidth: 2.5,
          dotData: FlDotData(show: showDots),
          belowBarData: BarAreaData(
            show: true,
            color: gpsColor.withValues(alpha: 0.15),
          ),
        ),
      ];
    }

    final xSpots = <FlSpot>[];
    final ySpots = <FlSpot>[];
    final zSpots = <FlSpot>[];

    for (final point in series) {
      final xIndex = point.index.toDouble();
      if (point.x != null && point.x!.isFinite) {
        xSpots.add(FlSpot(xIndex, point.x!));
      }
      if (point.y != null && point.y!.isFinite) {
        ySpots.add(FlSpot(xIndex, point.y!));
      }
      if (point.z != null && point.z!.isFinite) {
        zSpots.add(FlSpot(xIndex, point.z!));
      }
    }

    return [
      if (xSpots.isNotEmpty) _axisLineBar(xSpots, _xColor, showDots),
      if (ySpots.isNotEmpty) _axisLineBar(ySpots, _yColor, showDots),
      if (zSpots.isNotEmpty) _axisLineBar(zSpots, _zColor, showDots),
    ];
  }

  LineChartBarData _axisLineBar(
    List<FlSpot> spots,
    Color color,
    bool showDots,
  ) {
    return LineChartBarData(
      spots: spots,
      isCurved: spots.length > 2,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.2,
      dotData: FlDotData(show: showDots),
    );
  }

  ({double minY, double maxY}) _computeYBounds(
    List<SensorEvolutionPoint> series,
    SensorType sensor,
  ) {
    final values = <double>[];
    for (final point in series) {
      if (sensor == SensorType.gps) {
        if (point.magnitude != null && point.magnitude!.isFinite) {
          values.add(point.magnitude!);
        }
      } else {
        if (point.x != null && point.x!.isFinite) values.add(point.x!);
        if (point.y != null && point.y!.isFinite) values.add(point.y!);
        if (point.z != null && point.z!.isFinite) values.add(point.z!);
      }
    }

    if (values.isEmpty) {
      return (minY: -1.0, maxY: 1.0);
    }

    var rawMin = values.first;
    var rawMax = values.first;
    for (final value in values.skip(1)) {
      if (value < rawMin) rawMin = value;
      if (value > rawMax) rawMax = value;
    }

    // Si todos los valores son idénticos (p. ej. 1 punto o serie plana),
    // se añade un margen seguro para impedir intervalos verticales iguales a 0.
    if ((rawMax - rawMin).abs() < 1e-6) {
      final padding = (rawMax.abs() * 0.1).clamp(1.0, double.infinity);
      return (minY: rawMin - padding, maxY: rawMax + padding);
    }

    final padding = (rawMax - rawMin) * 0.1;
    return (minY: rawMin - padding, maxY: rawMax + padding);
  }

  String _seriesNameForBar(SensorType sensor, int barIndex) {
    if (sensor == SensorType.gps) {
      return 'Precisión';
    }
    return switch (barIndex) {
      0 => 'Eje X',
      1 => 'Eje Y',
      2 => 'Eje Z',
      _ => 'Valor',
    };
  }
}

class _ChartLegend extends StatelessWidget {
  final SensorType selectedSensor;
  final Color gpsColor;

  const _ChartLegend({required this.selectedSensor, required this.gpsColor});

  @override
  Widget build(BuildContext context) {
    if (selectedSensor == SensorType.gps) {
      return Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [_LegendItem(label: 'Precisión (m)', color: gpsColor)],
      );
    }

    return const Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendItem(label: 'Eje X', color: SensorEvolutionChartCard._xColor),
        _LegendItem(label: 'Eje Y', color: SensorEvolutionChartCard._yColor),
        _LegendItem(label: 'Eje Z', color: SensorEvolutionChartCard._zColor),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  final SensorType sensor;

  const _EmptyChartPlaceholder({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin datos graficables para ${sensor.displayName}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Guarda nuevas mediciones o selecciona otro sensor.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
