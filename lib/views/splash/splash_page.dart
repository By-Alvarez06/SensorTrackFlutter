import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../config/app_routes.dart';
import '../../config/supabase_config.dart';

/// Pantalla de bienvenida (Splash) mostrada al iniciar SensorTrack.
///
/// Presenta la identidad visual de la aplicación con una transición suave
/// durante [autoNavigateDelay] antes de redirigir a [AppRoutes.home].
class SplashPage extends StatefulWidget {
  /// Duración de espera antes de navegar hacia la pantalla principal.
  final Duration autoNavigateDelay;

  /// Crea una instancia de [SplashPage].
  const SplashPage({
    super.key,
    this.autoNavigateDelay = const Duration(milliseconds: 1200),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  Timer? _navigationTimer;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    unawaited(_animationController.forward());

    // Se almacena la referencia del Timer para cancelarlo en dispose() si el
    // usuario o una prueba desmontan el widget antes de completar la espera.
    _navigationTimer = Timer(widget.autoNavigateDelay, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusLabel = SupabaseConfig.isInitialized
        ? 'Conexión con Supabase lista'
        : 'Preparando sensores...';

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sensors,
                    size: 52,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SensorTrack',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monitoreo de sensores y ubicación en tiempo real',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  statusLabel,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
