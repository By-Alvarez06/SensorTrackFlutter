import 'package:material_ui/material_ui.dart';

/// Tarjeta Material 3 reutilizable para mostrar módulos o sensores.
///
/// Soporta un ícono principal dentro de un contenedor redondeado, título,
/// subtítulo, una etiqueta opcional de estado y una acción al tocarla.
class SensorCard extends StatelessWidget {
  /// Ícono representativo del sensor o módulo.
  final IconData icon;

  /// Título principal mostrado en la tarjeta.
  final String title;

  /// Descripción o subtítulo informativo.
  final String subtitle;

  /// Etiqueta breve opcional para indicar estado (ej. `"Disponible"`).
  final String? statusLabel;

  /// Color semántico aplicado al chip [statusLabel] y al ícono si se indica.
  final Color? statusColor;

  /// Widget opcional al final de la tarjeta; si se omite y [onTap] existe,
  /// se muestra una flecha de navegación.
  final Widget? trailing;

  /// Callback ejecutado al pulsar la tarjeta.
  final VoidCallback? onTap;

  /// Crea una instancia de [SensorCard].
  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statusLabel,
    this.statusColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final effectiveColor = statusColor ?? colorScheme.primary;
    final effectiveTrailing =
        trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveColor),
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
              if (statusLabel != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel!,
                    style: textTheme.labelSmall?.copyWith(
                      color: effectiveColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (effectiveTrailing != null) ...[
                const SizedBox(width: 4),
                effectiveTrailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
