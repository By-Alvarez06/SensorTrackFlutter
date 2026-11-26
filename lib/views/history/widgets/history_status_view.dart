import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_type.dart';

/// Vista informativa para estados vacío y de error en el módulo de historial.
class HistoryStatusView extends StatelessWidget {
  /// Ícono principal mostrado sobre el mensaje de estado.
  final IconData icon;

  /// Título principal del estado vacío o de error.
  final String title;

  /// Descripción detallada que orienta al usuario sobre qué hacer.
  final String description;

  /// Texto del botón de acción principal.
  final String actionLabel;

  /// Acción ejecutada al pulsar el botón principal.
  final VoidCallback onAction;

  /// Indica si la vista representa un estado de error para estilizar el ícono.
  final bool isError;

  /// Crea una vista para el estado vacío del historial.
  ///
  /// Ajusta el mensaje y la acción sugerida según exista o no un [activeFilter].
  factory HistoryStatusView.empty({
    Key? key,
    SensorType? activeFilter,
    required VoidCallback onAction,
  }) {
    final hasFilter = activeFilter != null;
    return HistoryStatusView._(
      key: key,
      icon: Icons.inbox_outlined,
      title: hasFilter
          ? 'Sin registros de ${activeFilter.displayName}'
          : 'Aún no hay mediciones guardadas',
      description: hasFilter
          ? 'Prueba seleccionando otro filtro o visualizando todos los sensores.'
          : 'Captura y guarda lecturas desde Sensores o Ubicación para verlas aquí.',
      actionLabel: hasFilter ? 'Ver todos' : 'Actualizar',
      onAction: onAction,
      isError: false,
    );
  }

  /// Crea una vista para mostrar errores de red o consulta con opción de reintento.
  const HistoryStatusView.error({
    super.key,
    required String message,
    required VoidCallback onRetry,
  })  : icon = Icons.cloud_off_outlined,
        title = 'No se pudo cargar el historial',
        description = message,
        actionLabel = 'Reintentar',
        onAction = onRetry,
        isError = true;

  const HistoryStatusView._({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor =
        isError ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(isError ? Icons.refresh : Icons.filter_alt_off),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
