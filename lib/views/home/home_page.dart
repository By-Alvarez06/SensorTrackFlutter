import 'package:material_ui/material_ui.dart';

import '../../config/app_routes.dart';
import '../../config/supabase_config.dart';

/// Pantalla principal de inicio de SensorTrack (esquema base de Fase 0).
///
/// Presenta el menú de navegación hacia los 4 módulos funcionales de la app
/// y muestra el estado inicial de configuración con Supabase. En Fase 1 se
/// conectará con `HomeController` para el chequeo en vivo de conexión y sensores.
class HomePage extends StatelessWidget {
  /// Crea una instancia de [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isConfigured = SupabaseConfig.isConfigured;
    final isInitialized = SupabaseConfig.isInitialized;

    return Scaffold(
      appBar: AppBar(title: const Text('SensorTrack')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                isInitialized
                    ? Icons.cloud_done
                    : (isConfigured ? Icons.cloud_off : Icons.cloud_queue),
                color: isInitialized
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
              title: const Text('Estado de Supabase'),
              subtitle: Text(
                isInitialized
                    ? 'Cliente inicializado correctamente'
                    : (isConfigured
                          ? 'Error al inicializar conexión'
                          : 'Sin credenciales (--dart-define)'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Módulos disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _NavigationModuleTile(
            icon: Icons.speed,
            title: 'Sensores',
            subtitle: 'Acelerómetro y giroscopio en tiempo real',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.sensors),
          ),
          _NavigationModuleTile(
            icon: Icons.location_on,
            title: 'Ubicación',
            subtitle: 'Coordenadas GPS y precisión',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.location),
          ),
          _NavigationModuleTile(
            icon: Icons.history,
            title: 'Historial',
            subtitle: 'Registros almacenados en Supabase',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.history),
          ),
          _NavigationModuleTile(
            icon: Icons.bar_chart,
            title: 'Estadísticas',
            subtitle: 'Métricas y gráficos de evolución',
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.stats),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de acceso rápido a un módulo de navegación desde [HomePage].
class _NavigationModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
