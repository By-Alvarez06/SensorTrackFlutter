/// Tipos de sensores físicos y capacidades soportadas por SensorTrack.
///
/// Cada valor se corresponde exactamente con el campo `sensor_type` almacenado
/// en la tabla `sensor_readings` de Supabase.
enum SensorType {
  /// Acelerómetro del dispositivo (ejes X, Y, Z en m/s²).
  accelerometer,

  /// Giroscopio del dispositivo (velocidad angular X, Y, Z en rad/s).
  gyroscope,

  /// Ubicación geográfica obtenida mediante GPS (latitud, longitud y precisión).
  gps,

  /// Magnetómetro del dispositivo (campo magnético en µT, sensor opcional).
  magnetometer,

  /// Sensor de luz ambiental (intensidad luminosa en lux, sensor opcional).
  light;

  /// Identificador textual exacto usado en la columna `sensor_type` de Supabase.
  String get dbValue => switch (this) {
    SensorType.accelerometer => 'accelerometer',
    SensorType.gyroscope => 'gyroscope',
    SensorType.gps => 'gps',
    SensorType.magnetometer => 'magnetometer',
    SensorType.light => 'light',
  };

  /// Nombre legible en español para mostrar al usuario en las vistas.
  String get displayName => switch (this) {
    SensorType.accelerometer => 'Acelerómetro',
    SensorType.gyroscope => 'Giroscopio',
    SensorType.gps => 'GPS / Ubicación',
    SensorType.magnetometer => 'Magnetómetro',
    SensorType.light => 'Sensor de luz',
  };

  /// Unidad de medida principal asociada al sensor para formateo en interfaz.
  String get unit => switch (this) {
    SensorType.accelerometer => 'm/s²',
    SensorType.gyroscope => 'rad/s',
    SensorType.gps => '° / m',
    SensorType.magnetometer => 'µT',
    SensorType.light => 'lx',
  };

  /// Convierte el valor de texto proveniente de PostgreSQL en un [SensorType].
  ///
  /// Normaliza [value] eliminando espacios extremos y convirtiendo a minúsculas.
  /// Lanza un [ArgumentError] si el texto no corresponde a ningún tipo válido.
  static SensorType fromDbValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'accelerometer' => SensorType.accelerometer,
      'gyroscope' => SensorType.gyroscope,
      'gps' => SensorType.gps,
      'magnetometer' => SensorType.magnetometer,
      'light' => SensorType.light,
      _ => throw ArgumentError.value(
        value,
        'value',
        'Tipo de sensor no soportado por SensorTrack',
      ),
    };
  }
}
