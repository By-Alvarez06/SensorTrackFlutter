import 'package:material_ui/material_ui.dart';

import '../../controllers/stats_controller.dart';
import '../../services/supabase_service.dart';
import 'widgets/sensor_evolution_chart.dart';
import 'widgets/stats_metric_cards.dart';

/// Pantalla principal del módulo de estadísticas y visualización de SensorTrack.
///
/// Presenta la cantidad total de registros, el desglose por tipo de sensor,
/// los máximos y mínimos del acelerómetro, la última ubicación GPS y un gráfico
/// interactivo de evolución temporal con `fl_chart`.
class StatsPage extends StatefulWidget {
  /// Servicio opcional inyectado para pruebas o configuraciones personalizadas.
  final SupabaseService? supabaseService;

  /// Crea una instancia de [StatsPage].
  const StatsPage({super.key, this.supabaseService});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final StatsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatsController(supabaseService: widget.supabaseService);
    _controller.loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Estadísticas'),
            actions: [
              IconButton(
                tooltip: 'Actualizar estadísticas',
                onPressed: _controller.isLoading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_controller.isLoading && _controller.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Calculando estadísticas...'),
          ],
        ),
      );
    }

    if (_controller.hasError && _controller.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 56,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se pudieron cargar las estadísticas',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _controller.errorMessage!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _controller.loadStats,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 56,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay estadísticas disponibles',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra mediciones de acelerómetro, giroscopio o GPS para visualizar métricas y gráficos.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _controller.stats;

    return Column(
      children: [
        if (_controller.isLoading) const LinearProgressIndicator(minHeight: 2),
        if (_controller.hasError)
          MaterialBanner(
            backgroundColor: colorScheme.errorContainer,
            content: Text(
              _controller.errorMessage!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
            actions: [
              TextButton(
                onPressed: _controller.refresh,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TotalReadingsCard(
                  totalReadings: stats.totalReadings,
                  lastUpdatedAt: _controller.lastUpdatedAt,
                ),
                const SizedBox(height: 12),
                SensorBreakdownCard(stats: stats),
                const SizedBox(height: 12),
                AccelerometerExtremesCard(
                  extremes: stats.accelerometerExtremes,
                ),
                const SizedBox(height: 12),
                LastLocationCard(lastLocation: stats.lastLocation),
                const SizedBox(height: 12),
                SensorEvolutionChartCard(
                  stats: stats,
                  selectedSensor: _controller.selectedChartSensor,
                  onSensorSelected: _controller.selectChartSensor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
