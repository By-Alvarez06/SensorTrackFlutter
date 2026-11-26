import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_type.dart';

/// Utilidades de formato numérico, temporal y de estilo para el módulo de estadísticas.
abstract final class StatsFormatters {
  /// Formatea [dateTime] en hora local con patrón `dd/MM/yyyy HH:mm:ss`.
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Sin fecha registrada';
    }
    final local = dateTime.toLocal();
    final day = _twoDigits(local.day);
    final month = _twoDigits(local.month);
    final year = local.year.toString().padLeft(4, '0');
    final hour = _twoDigits(local.hour);
    final minute = _twoDigits(local.minute);
    final second = _twoDigits(local.second);
    return '$day/$month/$year $hour:$minute:$second';
  }

  /// Formatea [dateTime] en hora local corta (`HH:mm`) para etiquetas del eje X.
  static String formatShortTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    final local = dateTime.toLocal();
    return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  /// Formatea un valor numérico finito con [decimals] decimales o retorna `--`.
  static String formatNumber(double? value, {int decimals = 2}) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return value.toStringAsFixed(decimals);
  }

  /// Formatea una coordenada geográfica con 6 decimales.
  static String formatCoordinate(double? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return '${value.toStringAsFixed(6)}°';
  }

  /// Formatea la precisión horizontal GPS en metros.
  static String formatAccuracy(double? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return '${value.toStringAsFixed(1)} m';
  }

  /// Retorna el ícono representativo de [type].
  static IconData sensorIcon(SensorType type) => switch (type) {
        SensorType.accelerometer => Icons.speed,
        SensorType.gyroscope => Icons.screen_rotation,
        SensorType.gps => Icons.location_on,
        SensorType.magnetometer => Icons.explore,
        SensorType.light => Icons.light_mode,
      };

  /// Retorna el color temático de [type] para barras y tarjetas.
  static Color sensorColor(SensorType type, ColorScheme colorScheme) =>
      switch (type) {
        SensorType.accelerometer => colorScheme.primary,
        SensorType.gyroscope => colorScheme.tertiary,
        SensorType.gps => colorScheme.secondary,
        SensorType.magnetometer => Colors.teal,
        SensorType.light => Colors.amber.shade800,
      };

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
