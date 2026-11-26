import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../config/app_routes.dart';
import '../../controllers/home_controller.dart';
import '../../models/sensor_type.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/sensor_card.dart';

/// Pantalla principal de inicio de SensorTrack (Módulo 1).
///
/// Implementa la capa Vista del patrón MVC escuchando a [HomeController]:
/// muestra el estado de conexión con Supabase, el menú de navegación hacia los
/// 4 módulos de la app y los sensores disponibles en el dispositivo.
class HomePage extends StatefulWidget {
  /// Controlador opcional inyectable (útil para pruebas unitarias/de widgets).
  final HomeController? controller;

  /// Crea una instancia de [HomePage].
  const HomePage({super.key, this.controller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? HomeController();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SensorTrack'),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                tooltip: 'Actualizar estado',
                onPressed:
                    _controller.isRefreshing ? null : _controller.refresh,
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                ConnectionStatusBadge(
                  state: _mapConnectionState(_controller.connectionStatus),
                  subtitle: _controller.connectionMessage,
                  onRetry: _controller.checkSupabaseConnection,
                ),
                const SizedBox(height: 20),
                Text(
                  'Menú principal',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SensorCard(
                  icon: Icons.speed,
                  title: 'Sensores',
                  subtitle: 'Acelerómetro y giroscopio en tiempo real',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.sensors),
                ),
                const SizedBox(height: 8),
                SensorCard(
                  icon: Icons.location_on,
                  title: 'Ubicación',
                  subtitle: 'Coordenadas GPS y precisión',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.location),
                ),
                const SizedBox(height: 8),
                SensorCard(
                  icon: Icons.history,
                  title: 'Historial',
                  subtitle: 'Registros almacenados en Supabase',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.history),
                ),
                const SizedBox(height: 8),
                SensorCard(
                  icon: Icons.bar_chart,
                  title: 'Estadísticas',
                  subtitle: 'Métricas y gráficos de evolución',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.stats),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sensores del dispositivo',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_controller.availableSensorsCount} de '
                      '${_controller.sensors.length} disponibles',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._controller.sensors.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildSensorAvailabilityCard(context, item),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construye la tarjeta informativa para un sensor evaluado del dispositivo.
  Widget _buildSensorAvailabilityCard(
    BuildContext context,
    SensorAvailabilityItem item,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final (String label, Color color) = switch (item.status) {
      SensorAvailabilityStatus.checking => ('Verificando', colorScheme.primary),
      SensorAvailabilityStatus.available => (
          'Disponible',
          Colors.green.shade700,
        ),
      SensorAvailabilityStatus.unavailable => (
          'No disponible',
          Colors.orange.shade800,
        ),
    };

    return SensorCard(
      icon: _iconForSensor(item.sensorType),
      title: item.sensorType.displayName,
      subtitle: '${item.statusMessage} (${item.sensorType.unit})',
      statusLabel: label,
      statusColor: color,
    );
  }

  /// Mapea el estado de conexión del controlador al estado del badge visual.
  ConnectionBadgeState _mapConnectionState(SupabaseConnectionStatus status) {
    return switch (status) {
      SupabaseConnectionStatus.checking => ConnectionBadgeState.checking,
      SupabaseConnectionStatus.connected => ConnectionBadgeState.connected,
      SupabaseConnectionStatus.disconnected =>
        ConnectionBadgeState.disconnected,
      SupabaseConnectionStatus.notConfigured =>
        ConnectionBadgeState.notConfigured,
    };
  }

  /// Devuelve un ícono representativo para cada tipo de sensor soportado.
  IconData _iconForSensor(SensorType type) {
    return switch (type) {
      SensorType.accelerometer => Icons.vibration,
      SensorType.gyroscope => Icons.screen_rotation,
      SensorType.gps => Icons.gps_fixed,
      SensorType.magnetometer => Icons.explore,
      SensorType.light => Icons.light_mode,
    };
  }
}
