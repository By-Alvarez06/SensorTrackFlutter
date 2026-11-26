import 'package:material_ui/material_ui.dart';

import '../../controllers/history_controller.dart';
import '../../models/sensor_reading.dart';
import '../../services/supabase_service.dart';
import 'reading_detail_page.dart';
import 'widgets/history_formatters.dart';
import 'widgets/history_status_view.dart';
import 'widgets/reading_list_card.dart';
import 'widgets/sensor_filter_bar.dart';

/// Pantalla principal del módulo de historial de mediciones almacenadas en Supabase.
///
/// Permite filtrar por tipo de sensor, actualizar mediante pull-to-refresh y
/// abrir el detalle completo de cualquier registro seleccionado.
class HistoryPage extends StatefulWidget {
  /// Servicio opcional inyectado para pruebas o configuraciones personalizadas.
  final SupabaseService? supabaseService;

  /// Crea una instancia de [HistoryPage].
  const HistoryPage({super.key, this.supabaseService});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(supabaseService: widget.supabaseService);
    _controller.loadReadings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetail(SensorReading reading) {
    final readingId = reading.id;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadingDetailPage(
          reading: reading,
          onRefreshById: readingId != null
              ? () => _controller.fetchReadingDetail(readingId)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historial'),
            actions: [
              IconButton(
                tooltip: 'Actualizar historial',
                onPressed: _controller.isLoading ? null : _controller.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: Column(
            children: [
              SensorFilterBar(
                selectedFilter: _controller.selectedFilter,
                isEnabled: !_controller.isLoading,
                onFilterChanged: _controller.setFilter,
              ),
              if (_controller.isLoading && !_controller.isEmpty)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _buildContent(context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_controller.isLoading && _controller.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Cargando historial desde Supabase...'),
          ],
        ),
      );
    }

    if (_controller.hasError && _controller.isEmpty) {
      return HistoryStatusView.error(
        message: _controller.errorMessage!,
        onRetry: _controller.loadReadings,
      );
    }

    if (_controller.isEmpty) {
      return HistoryStatusView.empty(
        activeFilter: _controller.selectedFilter,
        onAction: _controller.selectedFilter != null
            ? () => _controller.setFilter(null)
            : _controller.refresh,
      );
    }

    final readings = _controller.readings;
    final countLabel = readings.length == 1
        ? '1 registro encontrado'
        : '${readings.length} registros encontrados';

    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                countLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (_controller.lastUpdatedAt != null)
                Text(
                  'Act.: ${HistoryFormatters.formatDateTime(_controller.lastUpdatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: readings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final reading = readings[index];
                return ReadingListCard(
                  reading: reading,
                  onTap: () => _openDetail(reading),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
