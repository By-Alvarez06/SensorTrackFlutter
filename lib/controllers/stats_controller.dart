import 'package:flutter/foundation.dart';

import '../models/sensor_stats.dart';
import '../models/sensor_type.dart';
import '../services/supabase_service.dart';

/// Controlador MVC para el módulo de estadísticas y gráficos (`StatsPage`).
///
/// Obtiene las mediciones recientes desde [SupabaseService], calcula las
/// métricas agregadas mediante [SensorStats.fromReadings] y gestiona el sensor
/// seleccionado para el gráfico de evolución.
class StatsController extends ChangeNotifier {
  final SupabaseService _supabaseService;

  /// Cantidad máxima de registros consultados para construir las estadísticas.
  final int sampleLimit;

  SensorStats _stats = SensorStats.empty();
  SensorType _selectedChartSensor = SensorType.accelerometer;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  // Evita cambiar el gráfico seleccionado por el usuario al refrescar datos.
  bool _userSelectedChartSensor = false;

  // Evita notificar a la vista tras el cierre del ciclo de vida del widget.
  bool _isDisposed = false;

  // Descarta respuestas tardías cuando se dispara una recarga más reciente.
  int _requestSequence = 0;

  /// Crea una instancia de [StatsController].
  ///
  /// Permite inyectar un [supabaseService] personalizado para pruebas unitarias.
  StatsController({SupabaseService? supabaseService, this.sampleLimit = 200})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Resumen estadístico calculado a partir de las mediciones almacenadas.
  SensorStats get stats => _stats;

  /// Sensor actualmente seleccionado para visualizar en el gráfico de evolución.
  SensorType get selectedChartSensor => _selectedChartSensor;

  /// Indica si hay una carga de estadísticas en progreso.
  bool get isLoading => _isLoading;

  /// Mensaje descriptivo del último error de consulta, o `null` si no hay error.
  String? get errorMessage => _errorMessage;

  /// Indica si existe un error activo para mostrar en la vista.
  bool get hasError => _errorMessage != null;

  /// Indica si no existen mediciones registradas en el resumen actual.
  bool get isEmpty => !_stats.hasData;

  /// Fecha y hora local de la última actualización exitosa, si existe.
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  /// Serie temporal del sensor seleccionado actualmente para el gráfico.
  List<SensorEvolutionPoint> get activeChartSeries =>
      _stats.seriesFor(_selectedChartSensor);

  /// Consulta los registros en Supabase y recalcula todas las estadísticas.
  ///
  /// Captura [SupabaseServiceException] y errores inesperados para exponer un
  /// mensaje claro en [errorMessage].
  Future<void> loadStats() async {
    final requestId = ++_requestSequence;
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final readings = await _supabaseService.fetchReadings(limit: sampleLimit);

      if (_isDisposed || requestId != _requestSequence) {
        return;
      }

      final computedStats = SensorStats.fromReadings(readings);
      _stats = computedStats;
      _lastUpdatedAt = DateTime.now();

      // Si el usuario aún no eligió manualmente un sensor para el gráfico,
      // selecciona automáticamente el primero que tenga puntos graficables.
      if (!_userSelectedChartSensor) {
        _selectedChartSensor = _pickDefaultChartSensor(computedStats);
      }
    } on SupabaseServiceException catch (error) {
      if (_isDisposed || requestId != _requestSequence) {
        return;
      }
      _errorMessage = error.message;
    } catch (_) {
      if (_isDisposed || requestId != _requestSequence) {
        return;
      }
      _errorMessage =
          'Ocurrió un error inesperado al calcular las estadísticas.';
    } finally {
      if (!_isDisposed && requestId == _requestSequence) {
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  /// Recarga los datos desde Supabase y recalcula las estadísticas.
  Future<void> refresh() => loadStats();

  /// Selecciona [sensorType] como la serie activa en el gráfico de evolución.
  void selectChartSensor(SensorType sensorType) {
    _userSelectedChartSensor = true;
    if (_selectedChartSensor == sensorType) {
      return;
    }
    _selectedChartSensor = sensorType;
    _notifySafely();
  }

  /// Limpia el mensaje de error activo si existe.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifySafely();
  }

  static SensorType _pickDefaultChartSensor(SensorStats stats) {
    const candidates = [
      SensorType.accelerometer,
      SensorType.gyroscope,
      SensorType.gps,
    ];
    for (final candidate in candidates) {
      if (stats.seriesFor(candidate).isNotEmpty) {
        return candidate;
      }
    }
    return SensorType.accelerometer;
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
