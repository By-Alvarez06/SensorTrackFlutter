import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../models/sensor_reading.dart';
import '../../services/supabase_service.dart';
import 'widgets/history_formatters.dart';

/// Pantalla de detalle completo para una medición seleccionada del historial.
///
/// Muestra los valores de ejes (con magnitud vectorial cuando aplica), las
/// coordenadas GPS y precisión si existen, y los metadatos del registro.
class ReadingDetailPage extends StatefulWidget {
  /// Medición inicial seleccionada desde el listado de historial.
  final SensorReading reading;

  /// Función opcional para recargar el registro desde Supabase por su ID.
  final Future<SensorReading?> Function()? onRefreshById;

  /// Crea una instancia de [ReadingDetailPage].
  const ReadingDetailPage({
    super.key,
    required this.reading,
    this.onRefreshById,
  });

  @override
  State<ReadingDetailPage> createState() => _ReadingDetailPageState();
}

class _ReadingDetailPageState extends State<ReadingDetailPage> {
  late SensorReading _currentReading;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentReading = widget.reading;
  }

  Future<void> _refreshDetail() async {
    final refreshCallback = widget.onRefreshById;
    if (refreshCallback == null || _isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final updated = await refreshCallback();
      if (!mounted) return;

      if (updated != null) {
        setState(() => _currentReading = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detalle actualizado desde Supabase.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El registro ya no se encuentra disponible.'),
          ),
        );
      }
    } on SupabaseServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el detalle de la medición.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sensorType = _currentReading.sensorType;
    final accentColor = HistoryFormatters.sensorColor(sensorType, colorScheme);

    final hasAnyAxis = _currentReading.x != null ||
        _currentReading.y != null ||
        _currentReading.z != null;
    final hasAnyLocation =
        _currentReading.hasLocation || _currentReading.accuracy != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de medición'),
        actions: [
          if (widget.onRefreshById != null && _currentReading.id != null)
            IconButton(
              tooltip: 'Actualizar registro',
              onPressed: _isRefreshing ? null : _refreshDetail,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      HistoryFormatters.sensorIcon(sensorType),
                      size: 28,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensorType.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          HistoryFormatters.formatDateTime(
                            _currentReading.recordedAt,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasAnyAxis) ...[
            const SizedBox(height: 12),
            _DetailSectionCard(
              title: 'Valores de ejes (${sensorType.unit})',
              icon: Icons.analytics_outlined,
              rows: [
                _DetailRowData(
                  label: 'Eje X',
                  value:
                      '${HistoryFormatters.formatAxis(_currentReading.x, decimals: 4)} ${sensorType.unit}',
                ),
                _DetailRowData(
                  label: 'Eje Y',
                  value:
                      '${HistoryFormatters.formatAxis(_currentReading.y, decimals: 4)} ${sensorType.unit}',
                ),
                _DetailRowData(
                  label: 'Eje Z',
                  value:
                      '${HistoryFormatters.formatAxis(_currentReading.z, decimals: 4)} ${sensorType.unit}',
                ),
                if (_currentReading.hasAxisValues)
                  _DetailRowData(
                    label: 'Magnitud vectorial',
                    value:
                        '${_computeMagnitude(_currentReading).toStringAsFixed(4)} ${sensorType.unit}',
                  ),
              ],
            ),
          ],
          if (hasAnyLocation) ...[
            const SizedBox(height: 12),
            _DetailSectionCard(
              title: 'Ubicación geográfica',
              icon: Icons.my_location,
              rows: [
                _DetailRowData(
                  label: 'Latitud',
                  value: HistoryFormatters.formatCoordinate(
                    _currentReading.latitude,
                  ),
                ),
                _DetailRowData(
                  label: 'Longitud',
                  value: HistoryFormatters.formatCoordinate(
                    _currentReading.longitude,
                  ),
                ),
                _DetailRowData(
                  label: 'Precisión GPS',
                  value: HistoryFormatters.formatAccuracy(
                    _currentReading.accuracy,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _DetailSectionCard(
            title: 'Metadatos del registro',
            icon: Icons.info_outline,
            rows: [
              _DetailRowData(
                label: 'ID en Supabase',
                value: _currentReading.id ?? 'Sin asignar',
              ),
              _DetailRowData(
                label: 'Tipo en BD (sensor_type)',
                value: sensorType.dbValue,
              ),
              _DetailRowData(
                label: 'Fecha local',
                value: HistoryFormatters.formatDateTime(
                  _currentReading.recordedAt,
                ),
              ),
              _DetailRowData(
                label: 'Fecha UTC (ISO-8601)',
                value: HistoryFormatters.formatUtcIso(
                  _currentReading.recordedAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _computeMagnitude(SensorReading reading) {
    final x = reading.x ?? 0;
    final y = reading.y ?? 0;
    final z = reading.z ?? 0;
    return math.sqrt(x * x + y * y + z * z);
  }
}

class _DetailRowData {
  final String label;
  final String value;

  const _DetailRowData({required this.label, required this.value});
}

class _DetailSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_DetailRowData> rows;

  const _DetailSectionCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

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
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            for (var i = 0; i < rows.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        rows[i].label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        rows[i].value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
