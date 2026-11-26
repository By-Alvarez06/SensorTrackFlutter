import 'dart:math' as math;

import 'sensor_reading.dart';
import 'sensor_type.dart';

/// Valores extremos (mínimos y máximos) calculados sobre las mediciones
/// registradas del acelerómetro.
class AccelerometerExtremes {
  /// Valor mínimo registrado en el eje X (m/s²), o `null` si no hay muestras válidas.
  final double? minX;

  /// Valor máximo registrado en el eje X (m/s²), o `null` si no hay muestras válidas.
  final double? maxX;

  /// Valor mínimo registrado en el eje Y (m/s²), o `null` si no hay muestras válidas.
  final double? minY;

  /// Valor máximo registrado en el eje Y (m/s²), o `null` si no hay muestras válidas.
  final double? maxY;

  /// Valor mínimo registrado en el eje Z (m/s²), o `null` si no hay muestras válidas.
  final double? minZ;

  /// Valor máximo registrado en el eje Z (m/s²), o `null` si no hay muestras válidas.
  final double? maxZ;

  /// Magnitud vectorial mínima ($\sqrt{x^2 + y^2 + z^2}$) cuando existen los tres ejes.
  final double? minMagnitude;

  /// Magnitud vectorial máxima ($\sqrt{x^2 + y^2 + z^2}$) cuando existen los tres ejes.
  final double? maxMagnitude;

  /// Valor mínimo global considerando todos los ejes válidos (X, Y y Z).
  final double overallMin;

  /// Valor máximo global considerando todos los ejes válidos (X, Y y Z).
  final double overallMax;

  /// Cantidad de lecturas de acelerómetro con al menos un eje válido.
  final int sampleCount;

  /// Crea una instancia inmutable de [AccelerometerExtremes].
  const AccelerometerExtremes({
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.minZ,
    this.maxZ,
    this.minMagnitude,
    this.maxMagnitude,
    required this.overallMin,
    required this.overallMax,
    required this.sampleCount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccelerometerExtremes &&
        other.minX == minX &&
        other.maxX == maxX &&
        other.minY == minY &&
        other.maxY == maxY &&
        other.minZ == minZ &&
        other.maxZ == maxZ &&
        other.minMagnitude == minMagnitude &&
        other.maxMagnitude == maxMagnitude &&
        other.overallMin == overallMin &&
        other.overallMax == overallMax &&
        other.sampleCount == sampleCount;
  }

  @override
  int get hashCode => Object.hash(
        minX,
        maxX,
        minY,
        maxY,
        minZ,
        maxZ,
        minMagnitude,
        maxMagnitude,
        overallMin,
        overallMax,
        sampleCount,
      );

  @override
  String toString() {
    return 'AccelerometerExtremes(overallMin: $overallMin, overallMax: $overallMax, '
        'sampleCount: $sampleCount, minX: $minX, maxX: $maxX, minY: $minY, '
        'maxY: $maxY, minZ: $minZ, maxZ: $maxZ, minMagnitude: $minMagnitude, '
        'maxMagnitude: $maxMagnitude)';
  }
}

/// Punto individual de una serie temporal para graficar la evolución de mediciones.
///
/// Desacopla el modelo de dominio respecto a librerías de gráficos (`fl_chart`).
class SensorEvolutionPoint {
  /// Índice secuencial del punto en orden cronológico ascendente (`0..n-1`).
  final int index;

  /// Tipo de sensor al que pertenece este punto.
  final SensorType sensorType;

  /// Valor del eje X si el sensor utiliza ejes espaciales.
  final double? x;

  /// Valor del eje Y si el sensor utiliza ejes espaciales.
  final double? y;

  /// Valor del eje Z si el sensor utiliza ejes espaciales.
  final double? z;

  /// Magnitud escalar del punto: norma vectorial en sensores de ejes o precisión (m) en GPS.
  final double? magnitude;

  /// Marca temporal de la medición original, si está disponible.
  final DateTime? recordedAt;

  /// Crea una instancia inmutable de [SensorEvolutionPoint].
  const SensorEvolutionPoint({
    required this.index,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    this.magnitude,
    this.recordedAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorEvolutionPoint &&
        other.index == index &&
        other.sensorType == sensorType &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.magnitude == magnitude &&
        other.recordedAt == recordedAt;
  }

  @override
  int get hashCode =>
      Object.hash(index, sensorType, x, y, z, magnitude, recordedAt);

  @override
  String toString() {
    return 'SensorEvolutionPoint(index: $index, sensorType: ${sensorType.dbValue}, '
        'x: $x, y: $y, z: $z, magnitude: $magnitude, recordedAt: $recordedAt)';
  }
}

/// Modelo agregado e inmutable con las estadísticas de las mediciones almacenadas.
///
/// Resume la cantidad total de registros, el desglose por tipo de sensor, los
/// extremos del acelerómetro, la última ubicación GPS y las series temporales
/// ordenadas cronológicamente para visualización.
class SensorStats {
  /// Cantidad total de registros procesados.
  final int totalReadings;

  /// Conteo de registros agrupado por cada [SensorType].
  final Map<SensorType, int> countBySensor;

  /// Valores mínimos y máximos del acelerómetro, o `null` si no hay lecturas válidas.
  final AccelerometerExtremes? accelerometerExtremes;

  /// Última lectura con coordenadas geográficas válidas, o `null` si no existe.
  final SensorReading? lastLocation;

  /// Serie cronológica ascendente de mediciones de acelerómetro.
  final List<SensorEvolutionPoint> accelerometerSeries;

  /// Serie cronológica ascendente de mediciones de giroscopio.
  final List<SensorEvolutionPoint> gyroscopeSeries;

  /// Serie cronológica ascendente de precisión GPS en metros.
  final List<SensorEvolutionPoint> gpsAccuracySeries;

  /// Crea una instancia inmutable de [SensorStats] asegurando colecciones no modificables.
  SensorStats({
    required this.totalReadings,
    required Map<SensorType, int> countBySensor,
    this.accelerometerExtremes,
    this.lastLocation,
    List<SensorEvolutionPoint> accelerometerSeries = const [],
    List<SensorEvolutionPoint> gyroscopeSeries = const [],
    List<SensorEvolutionPoint> gpsAccuracySeries = const [],
  })  : countBySensor = Map.unmodifiable({
          for (final type in SensorType.values) type: countBySensor[type] ?? 0,
        }),
        accelerometerSeries = List.unmodifiable(accelerometerSeries),
        gyroscopeSeries = List.unmodifiable(gyroscopeSeries),
        gpsAccuracySeries = List.unmodifiable(gpsAccuracySeries);

  /// Crea un resumen estadístico vacío sin lecturas registradas.
  factory SensorStats.empty() {
    return SensorStats(
      totalReadings: 0,
      countBySensor: {for (final type in SensorType.values) type: 0},
    );
  }

  /// Indica si existe al menos una medición registrada.
  bool get hasData => totalReadings > 0;

  /// Retorna la cantidad de registros asociados a [type].
  int countFor(SensorType type) => countBySensor[type] ?? 0;

  /// Retorna la serie temporal correspondiente a [type], o lista vacía si no aplica.
  List<SensorEvolutionPoint> seriesFor(SensorType type) => switch (type) {
        SensorType.accelerometer => accelerometerSeries,
        SensorType.gyroscope => gyroscopeSeries,
        SensorType.gps => gpsAccuracySeries,
        SensorType.magnetometer || SensorType.light => const [],
      };

  /// Calcula todas las métricas y series estadísticas a partir de [readings].
  ///
  /// Filtra valores no finitos (`NaN` o infinito) para evitar errores numéricos
  /// y ordena las series en sentido cronológico ascendente (más antiguo primero).
  factory SensorStats.fromReadings(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return SensorStats.empty();
    }

    final counts = <SensorType, int>{
      for (final type in SensorType.values) type: 0,
    };

    SensorReading? latestLocation;

    double? minX;
    double? maxX;
    double? minY;
    double? maxY;
    double? minZ;
    double? maxZ;
    double? minMagnitude;
    double? maxMagnitude;
    double? overallMin;
    double? overallMax;
    var accelSampleCount = 0;

    for (final reading in readings) {
      counts[reading.sensorType] = (counts[reading.sensorType] ?? 0) + 1;

      if (reading.hasLocation &&
          _isFinite(reading.latitude) &&
          _isFinite(reading.longitude)) {
        latestLocation = _pickMostRecentLocation(latestLocation, reading);
      }

      if (reading.sensorType == SensorType.accelerometer) {
        final x = _finiteOrNull(reading.x);
        final y = _finiteOrNull(reading.y);
        final z = _finiteOrNull(reading.z);

        if (x != null || y != null || z != null) {
          accelSampleCount++;
        }

        // No se inicializan extremos en 0.0 para respetar lecturas negativas reales.
        if (x != null) {
          minX = _minNullable(minX, x);
          maxX = _maxNullable(maxX, x);
          overallMin = _minNullable(overallMin, x);
          overallMax = _maxNullable(overallMax, x);
        }
        if (y != null) {
          minY = _minNullable(minY, y);
          maxY = _maxNullable(maxY, y);
          overallMin = _minNullable(overallMin, y);
          overallMax = _maxNullable(overallMax, y);
        }
        if (z != null) {
          minZ = _minNullable(minZ, z);
          maxZ = _maxNullable(maxZ, z);
          overallMin = _minNullable(overallMin, z);
          overallMax = _maxNullable(overallMax, z);
        }

        if (x != null && y != null && z != null) {
          final magnitude = math.sqrt(x * x + y * y + z * z);
          minMagnitude = _minNullable(minMagnitude, magnitude);
          maxMagnitude = _maxNullable(maxMagnitude, magnitude);
        }
      }
    }

    final AccelerometerExtremes? extremes =
        (accelSampleCount > 0 && overallMin != null && overallMax != null)
            ? AccelerometerExtremes(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                minZ: minZ,
                maxZ: maxZ,
                minMagnitude: minMagnitude,
                maxMagnitude: maxMagnitude,
                overallMin: overallMin,
                overallMax: overallMax,
                sampleCount: accelSampleCount,
              )
            : null;

    // SupabaseService.fetchReadings retorna en orden descendente (más reciente primero).
    // Se invierte la lista y luego se aplica ordenamiento estable por recordedAt ascendente
    // para que las gráficas muestren la evolución temporal de izquierda a derecha.
    final chronologicalReadings = _sortChronologicallyAscending(readings);

    final accelSeries = <SensorEvolutionPoint>[];
    final gyroSeries = <SensorEvolutionPoint>[];
    final gpsSeries = <SensorEvolutionPoint>[];

    for (final reading in chronologicalReadings) {
      switch (reading.sensorType) {
        case SensorType.accelerometer:
          final point = _buildAxisPoint(
            index: accelSeries.length,
            reading: reading,
          );
          if (point != null) {
            accelSeries.add(point);
          }
        case SensorType.gyroscope:
          final point = _buildAxisPoint(
            index: gyroSeries.length,
            reading: reading,
          );
          if (point != null) {
            gyroSeries.add(point);
          }
        case SensorType.gps:
          final accuracy = _finiteOrNull(reading.accuracy);
          if (accuracy != null) {
            gpsSeries.add(
              SensorEvolutionPoint(
                index: gpsSeries.length,
                sensorType: SensorType.gps,
                magnitude: accuracy,
                recordedAt: reading.recordedAt,
              ),
            );
          }
        case SensorType.magnetometer:
        case SensorType.light:
          break;
      }
    }

    return SensorStats(
      totalReadings: readings.length,
      countBySensor: counts,
      accelerometerExtremes: extremes,
      lastLocation: latestLocation,
      accelerometerSeries: accelSeries,
      gyroscopeSeries: gyroSeries,
      gpsAccuracySeries: gpsSeries,
    );
  }

  /// Construye un [SensorEvolutionPoint] para sensores de 3 ejes si hay datos finitos.
  static SensorEvolutionPoint? _buildAxisPoint({
    required int index,
    required SensorReading reading,
  }) {
    final x = _finiteOrNull(reading.x);
    final y = _finiteOrNull(reading.y);
    final z = _finiteOrNull(reading.z);
    if (x == null && y == null && z == null) {
      return null;
    }

    final double? magnitude = (x != null && y != null && z != null)
        ? math.sqrt(x * x + y * y + z * z)
        : null;

    return SensorEvolutionPoint(
      index: index,
      sensorType: reading.sensorType,
      x: x,
      y: y,
      z: z,
      magnitude: magnitude,
      recordedAt: reading.recordedAt,
    );
  }

  /// Ordena las lecturas de forma estable en sentido cronológico ascendente.
  static List<SensorReading> _sortChronologicallyAscending(
    List<SensorReading> readings,
  ) {
    final indexed = <({int position, SensorReading reading})>[];
    var position = 0;
    for (final reading in readings.reversed) {
      indexed.add((position: position++, reading: reading));
    }

    indexed.sort((a, b) {
      final dateA = a.reading.recordedAt;
      final dateB = b.reading.recordedAt;
      if (dateA != null && dateB != null) {
        final comparison = dateA.compareTo(dateB);
        if (comparison != 0) {
          return comparison;
        }
      }
      return a.position.compareTo(b.position);
    });

    return [for (final item in indexed) item.reading];
  }

  /// Selecciona la lectura geográfica más reciente comparando [recordedAt].
  static SensorReading _pickMostRecentLocation(
    SensorReading? current,
    SensorReading candidate,
  ) {
    if (current == null) return candidate;

    final currentDate = current.recordedAt;
    final candidateDate = candidate.recordedAt;

    if (currentDate != null && candidateDate != null) {
      return candidateDate.isAfter(currentDate) ? candidate : current;
    }
    if (candidateDate != null && currentDate == null) {
      return candidate;
    }
    return current;
  }

  /// Verifica si [value] no es nulo y representa un número real finito.
  static bool _isFinite(double? value) => value != null && value.isFinite;

  /// Retorna [value] si es finito, o `null` en caso contrario.
  static double? _finiteOrNull(double? value) =>
      (value != null && value.isFinite) ? value : null;

  static double _minNullable(double? current, double candidate) =>
      current == null || candidate < current ? candidate : current;

  static double _maxNullable(double? current, double candidate) =>
      current == null || candidate > current ? candidate : current;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorStats &&
        other.totalReadings == totalReadings &&
        _mapEquals(other.countBySensor, countBySensor) &&
        other.accelerometerExtremes == accelerometerExtremes &&
        other.lastLocation == lastLocation &&
        _listEquals(other.accelerometerSeries, accelerometerSeries) &&
        _listEquals(other.gyroscopeSeries, gyroscopeSeries) &&
        _listEquals(other.gpsAccuracySeries, gpsAccuracySeries);
  }

  @override
  int get hashCode => Object.hash(
        totalReadings,
        Object.hashAllUnordered(
          countBySensor.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        accelerometerExtremes,
        lastLocation,
        Object.hashAll(accelerometerSeries),
        Object.hashAll(gyroscopeSeries),
        Object.hashAll(gpsAccuracySeries),
      );

  static bool _mapEquals(Map<SensorType, int> a, Map<SensorType, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'SensorStats(totalReadings: $totalReadings, '
        'countBySensor: $countBySensor, '
        'accelerometerExtremes: $accelerometerExtremes, '
        'lastLocation: $lastLocation)';
  }
}
