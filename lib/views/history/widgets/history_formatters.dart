import 'package:material_ui/material_ui.dart';

import '../../../models/sensor_type.dart';

/// Utilidades de formato y estilo visual exclusivas del módulo de historial.
abstract final class HistoryFormatters {
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

  /// Formatea [dateTime] en formato ISO-8601 UTC para metadatos técnicos.
  static String formatUtcIso(DateTime? dateTime) {
    if (dateTime == null) {
      return 'No disponible';
    }
    return dateTime.toUtc().toIso8601String();
  }

  /// Formatea el valor numérico de un eje o magnitud con [decimals] decimales.
  static String formatAxis(double? value, {int decimals = 2}) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return value.toStringAsFixed(decimals);
  }

  /// Formatea una coordenada geográfica (latitud o longitud) con 6 decimales.
  static String formatCoordinate(double? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return '${value.toStringAsFixed(6)}°';
  }

  /// Formatea la precisión horizontal del GPS en metros.
  static String formatAccuracy(double? value) {
    if (value == null || !value.isFinite) {
      return '--';
    }
    return '${value.toStringAsFixed(1)} m';
  }

  /// Retorna el ícono representativo para [type].
  static IconData sensorIcon(SensorType type) => switch (type) {
        SensorType.accelerometer => Icons.speed,
        SensorType.gyroscope => Icons.screen_rotation,
        SensorType.gps => Icons.location_on,
        SensorType.magnetometer => Icons.explore,
        SensorType.light => Icons.light_mode,
      };

  /// Retorna el color temático asociado a [type] según el [colorScheme] activo.
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
