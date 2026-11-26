import 'package:flutter/foundation.dart';

import '../models/sensor_reading.dart';
import '../models/sensor_type.dart';
import '../services/supabase_service.dart';

/// Controlador MVC para la pantalla de historial de mediciones (`HistoryPage`).
///
/// Administra la carga de registros desde [SupabaseService], el filtrado por
/// [SensorType], la actualización bajo demanda y el manejo de errores de red.
class HistoryController extends ChangeNotifier {
  final SupabaseService _supabaseService;

  /// Cantidad máxima de registros solicitados en cada consulta al historial.
  final int pageLimit;

  List<SensorReading> _readings = const [];
  SensorType? _selectedFilter;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;

  // Evita notificar a la vista si el controlador ya fue destruido mientras
  // había una consulta remota en progreso.
  bool _isDisposed = false;

  // Contador incremental para descartar respuestas obsoletas si el usuario
  // cambia rápidamente de filtro antes de que responda la petición anterior.
  int _requestSequence = 0;

  /// Crea una instancia de [HistoryController].
  ///
  /// Permite inyectar un [supabaseService] personalizado para pruebas unitarias.
  HistoryController({SupabaseService? supabaseService, this.pageLimit = 100})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Lista inmutable de mediciones actualmente cargadas.
  List<SensorReading> get readings => List.unmodifiable(_readings);

  /// Filtro de sensor activo, o `null` si se muestran todos los sensores.
  SensorType? get selectedFilter => _selectedFilter;

  /// Indica si existe una consulta en curso contra Supabase.
  bool get isLoading => _isLoading;

  /// Mensaje descriptivo del último error ocurrido, o `null` si no hay errores.
  String? get errorMessage => _errorMessage;

  /// Indica si existe un error activo para mostrar en la interfaz.
  bool get hasError => _errorMessage != null;

  /// Indica si el listado actual de mediciones está vacío.
  bool get isEmpty => _readings.isEmpty;

  /// Fecha y hora local de la última actualización exitosa, si existe.
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  /// Carga las mediciones desde Supabase aplicando [selectedFilter].
  ///
  /// Captura [SupabaseServiceException] y cualquier error inesperado para
  /// exponer un mensaje comprensible en [errorMessage] sin lanzar excepciones.
  Future<void> loadReadings() async {
    final requestId = ++_requestSequence;
    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final fetched = await _supabaseService.fetchReadings(
        sensorType: _selectedFilter,
        limit: pageLimit,
      );

      // Si hubo una petición más reciente o el controlador se cerró, se ignora.
      if (_isDisposed || requestId != _requestSequence) {
        return;
      }

      _readings = List.unmodifiable(fetched);
      _lastUpdatedAt = DateTime.now();
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
          'Ocurrió un error inesperado al cargar el historial de mediciones.';
    } finally {
      if (!_isDisposed && requestId == _requestSequence) {
        _isLoading = false;
        _notifySafely();
      }
    }
  }

  /// Recarga el listado actual manteniendo el filtro seleccionado.
  Future<void> refresh() => loadReadings();

  /// Cambia el filtro activo por [sensorType] y recarga el historial.
  ///
  /// Evita consultas redundantes cuando se vuelve a seleccionar el mismo filtro
  /// y no hay un error pendiente por reintentar.
  Future<void> setFilter(SensorType? sensorType) async {
    if (_selectedFilter == sensorType && !hasError) {
      return;
    }
    _selectedFilter = sensorType;
    await loadReadings();
  }

  /// Consulta el detalle actualizado de una medición específica por su [id].
  ///
  /// Delega la operación en [SupabaseService.fetchReadingById] para mantener la
  /// vista desacoplada de la capa de servicios. Puede lanzar
  /// [SupabaseServiceException] si falla la consulta remota.
  Future<SensorReading?> fetchReadingDetail(String id) {
    return _supabaseService.fetchReadingById(id);
  }

  /// Limpia el mensaje de error activo si existe.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifySafely();
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
