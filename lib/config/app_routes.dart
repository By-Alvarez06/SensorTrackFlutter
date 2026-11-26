import 'package:material_ui/material_ui.dart';

import '../views/history/history_page.dart';
import '../views/home/home_page.dart';
import '../views/location/location_page.dart';
import '../views/sensors/sensors_page.dart';
import '../views/splash/splash_page.dart';
import '../views/stats/stats_page.dart';

/// Registro centralizado de rutas nombradas de SensorTrack.
///
/// Conecta cada ruta con el constructor de entrada congelado de su vista
/// correspondiente para evitar conflictos de edición entre módulos.
abstract final class AppRoutes {
  /// Ruta inicial de bienvenida (Splash Screen).
  static const String splash = '/';

  /// Ruta de la pantalla principal de inicio y menú de navegación.
  static const String home = '/home';

  /// Ruta del módulo de monitoreo en tiempo real (Acelerómetro y Giroscopio).
  static const String sensors = '/sensors';

  /// Ruta del módulo de ubicación geográfica (GPS).
  static const String location = '/location';

  /// Ruta del módulo de historial de mediciones en Supabase.
  static const String history = '/history';

  /// Ruta del módulo de estadísticas y gráficos de evolución.
  static const String stats = '/stats';

  /// Mapa de constructores de pantallas consumido por `MaterialApp.routes`.
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashPage(),
        home: (_) => const HomePage(),
        sensors: (_) => const SensorsPage(),
        location: (_) => const LocationPage(),
        history: (_) => const HistoryPage(),
        stats: (_) => const StatsPage(),
      };
}
