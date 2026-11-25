import 'package:material_ui/material_ui.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';

/// Punto de entrada principal de la aplicación SensorTrack.
///
/// Inicializa los bindings de Flutter e intenta conectar con Supabase usando
/// las variables definidas vía `--dart-define` antes de montar el árbol de widgets.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const SensorTrackApp());
}

/// Widget raíz de SensorTrack que configura el tema Material 3 y las rutas.
class SensorTrackApp extends StatelessWidget {
  /// Crea la instancia raíz de [SensorTrackApp].
  const SensorTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SensorTrack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
