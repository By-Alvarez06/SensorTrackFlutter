import 'sensor_type.dart';

/// Modelo de dominio inmutable que representa una medición de sensor
/// almacenada o por almacenar en la tabla `sensor_readings` de Supabase.
class SensorReading {
  /// Identificador único UUID generado por PostgreSQL, o `null` si aún no se persiste.
  final String? id;

  /// Tipo de sensor físico que originó esta medición.
  final SensorType sensorType;

  /// Valor del eje X (aceleración, velocidad angular o campo magnético).
  final double? x;

  /// Valor del eje Y (aceleración, velocidad angular o campo magnético).
  final double? y;

  /// Valor del eje Z (aceleración, velocidad angular o campo magnético).
  final double? z;

  /// Latitud geográfica en grados decimales (cuando [sensorType] es [SensorType.gps]).
  final double? latitude;

  /// Longitud geográfica en grados decimales (cuando [sensorType] es [SensorType.gps]).
  final double? longitude;

  /// Precisión estimada de la ubicación GPS en metros.
  final double? accuracy;

  /// Fecha y hora de captura de la medición.
  final DateTime? recordedAt;

  /// Crea una instancia inmutable de [SensorReading].
  const SensorReading({
    this.id,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.recordedAt,
  });

  /// Indica si el registro contiene los tres valores espaciales ([x], [y], [z]).
  bool get hasAxisValues => x != null && y != null && z != null;

  /// Indica si el registro contiene coordenadas geográficas ([latitude] y [longitude]).
  bool get hasLocation => latitude != null && longitude != null;

  /// Construye un [SensorReading] a partir de un mapa JSON devuelto por Supabase.
  ///
  /// Convierte de forma segura números enteros o decimales a `double?` y
  /// parsea `recorded_at` en formato ISO-8601. Lanza [FormatException] o
  /// [ArgumentError] si `sensor_type` falta o es inválido.
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    final rawType = json['sensor_type'];
    if (rawType is! String || rawType.trim().isEmpty) {
      throw const FormatException(
        'El campo "sensor_type" es obligatorio y debe ser un texto válido.',
      );
    }

    final rawRecordedAt = json['recorded_at'];
    final DateTime? parsedDate = switch (rawRecordedAt) {
      String s => DateTime.tryParse(s),
      DateTime dt => dt,
      _ => null,
    };

    return SensorReading(
      id: json['id'] as String?,
      sensorType: SensorType.fromDbValue(rawType),
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      z: _toDouble(json['z']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDouble(json['accuracy']),
      recordedAt: parsedDate,
    );
  }

  /// Convierte la medición al mapa JSON esperado por Supabase para inserción.
  ///
  /// Omite `id` y `recorded_at` cuando son `null` para que PostgreSQL asigne
  /// automáticamente sus valores por defecto (`gen_random_uuid()` y `NOW()`).
  Map<String, dynamic> toJson() {
    // Solo se incluyen los campos con valor para no sobrescribir los defaults
    // del servidor ni enviar llaves innecesarias según el tipo de sensor.
    return {
      if (id != null) 'id': id,
      'sensor_type': sensorType.dbValue,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (recordedAt != null)
        'recorded_at': recordedAt!.toUtc().toIso8601String(),
    };
  }

  /// Retorna una copia de este [SensorReading] reemplazando solo los campos indicados.
  SensorReading copyWith({
    String? id,
    SensorType? sensorType,
    double? x,
    double? y,
    double? z,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? recordedAt,
  }) {
    return SensorReading(
      id: id ?? this.id,
      sensorType: sensorType ?? this.sensorType,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// Convierte dinámicamente valores numéricos o textuales a `double?`.
  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorReading &&
        other.id == id &&
        other.sensorType == sensorType &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        sensorType,
        x,
        y,
        z,
        latitude,
        longitude,
        accuracy,
        recordedAt,
      );

  @override
  String toString() {
    return 'SensorReading(id: $id, sensorType: ${sensorType.dbValue}, '
        'x: $x, y: $y, z: $z, latitude: $latitude, '
        'longitude: $longitude, accuracy: $accuracy, recordedAt: $recordedAt)';
  }
}
