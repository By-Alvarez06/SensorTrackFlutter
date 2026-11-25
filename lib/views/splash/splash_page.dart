import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../config/app_routes.dart';

/// Pantalla de bienvenida (Splash) mostrada al iniciar SensorTrack.
///
/// Presenta la identidad de la aplicación durante [autoNavigateDelay] antes de
/// redirigir automáticamente a la pantalla principal ([AppRoutes.home]).
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

class _SplashPageState extends State<SplashPage> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // Se programa la transición automática y se guarda la referencia del Timer
    // para cancelarlo en dispose() si el widget se desmonta antes de tiempo.
    _navigationTimer = Timer(widget.autoNavigateDelay, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors, size: 72, color: colorScheme.primary),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
