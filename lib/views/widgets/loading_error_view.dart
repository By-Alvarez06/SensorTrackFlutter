import 'package:material_ui/material_ui.dart';

/// Modos de presentación internos soportados por [LoadingErrorView].
enum _LoadingErrorMode { loading, error, empty }

/// Vista centrada reutilizable para representar estados de carga, error o vacío.
///
/// Facilita que las pantallas de los distintos módulos mantengan una apariencia
/// uniforme al consultar sensores, ubicación o registros de Supabase.
class LoadingErrorView extends StatelessWidget {
  final _LoadingErrorMode _mode;

  /// Mensaje principal mostrado debajo del indicador o ícono.
  final String message;

  /// Ícono mostrado en los modos de error o lista vacía.
  final IconData icon;

  /// Acción opcional para reintentar o recargar cuando aplica.
  final VoidCallback? onRetry;

  /// Texto mostrado en el botón de acción cuando [onRetry] está definido.
  final String? actionLabel;

  /// Crea una vista centrada de estado de carga.
  const LoadingErrorView.loading({super.key, this.message = 'Cargando...'})
      : _mode = _LoadingErrorMode.loading,
        icon = Icons.hourglass_empty,
        onRetry = null,
        actionLabel = null;

  /// Crea una vista centrada para reportar un error con botón opcional de reintento.
  const LoadingErrorView.error({
    super.key,
    required this.message,
    this.onRetry,
    this.actionLabel = 'Reintentar',
  })  : _mode = _LoadingErrorMode.error,
        icon = Icons.error_outline;

  /// Crea una vista centrada para estados sin resultados disponibles.
  const LoadingErrorView.empty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.actionLabel,
  }) : _mode = _LoadingErrorMode.empty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mode == _LoadingErrorMode.loading)
              const CircularProgressIndicator()
            else
              Icon(
                icon,
                size: 56,
                color: _mode == _LoadingErrorMode.error
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel ?? 'Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
