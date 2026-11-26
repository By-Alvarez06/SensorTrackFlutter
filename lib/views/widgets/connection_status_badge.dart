import 'package:material_ui/material_ui.dart';

/// Estados visuales soportados por [ConnectionStatusBadge].
enum ConnectionBadgeState {
  /// Se está verificando la conectividad con Supabase en este momento.
  checking,

  /// La conexión con Supabase respondió satisfactoriamente.
  connected,

  /// Falló la verificación o no hay conexión disponible con Supabase.
  disconnected,

  /// Faltan variables `--dart-define` para inicializar Supabase.
  notConfigured,
}

/// Tarjeta reutilizable que muestra el estado actual de conexión con Supabase.
///
/// Presenta un ícono semántico, etiqueta de estado, mensaje descriptivo y un
/// botón opcional para reintentar la comprobación de conectividad.
class ConnectionStatusBadge extends StatelessWidget {
  /// Estado actual de la conexión a representar.
  final ConnectionBadgeState state;

  /// Mensaje descriptivo complementario del estado de conexión.
  final String subtitle;

  /// Acción opcional invocada al presionar el botón de reintento.
  final VoidCallback? onRetry;

  /// Crea una instancia de [ConnectionStatusBadge].
  const ConnectionStatusBadge({
    super.key,
    required this.state,
    required this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, String title, Color accentColor) = switch (state) {
      ConnectionBadgeState.checking => (
          Icons.cloud_sync,
          'Verificando Supabase...',
          colorScheme.primary,
        ),
      ConnectionBadgeState.connected => (
          Icons.cloud_done,
          'Supabase conectado',
          Colors.green.shade700,
        ),
      ConnectionBadgeState.disconnected => (
          Icons.cloud_off,
          'Supabase sin conexión',
          colorScheme.error,
        ),
      ConnectionBadgeState.notConfigured => (
          Icons.cloud_queue,
          'Supabase sin configurar',
          Colors.orange.shade800,
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (state == ConnectionBadgeState.checking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                tooltip: 'Reintentar conexión',
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      ),
    );
  }
}
