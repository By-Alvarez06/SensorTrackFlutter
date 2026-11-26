import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/sensor_reading.dart';
import '../models/sensor_type.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

/// Controlador MVC para la pantalla de ubicación geográfica (GPS).
///
/// Gestiona la interacción con [LocationService] para solicitar permisos y obtener
/// la posición GPS actual, y con [SupabaseService] para guardar las coordenadas
/// únicamente bajo el consentimiento explícito del usuario.
class LocationController extends ChangeNotifier {
  final LocationService _locationService;
  final SupabaseService _supabaseService;

  bool _isLoading = false;
  bool _isSaving = false;
  Position? _currentPosition;
  String? _errorMessage;
  String? _successMessage;

  /// Crea una instancia de [LocationController].
  ///
  /// Permite inyectar [locationService] y [supabaseService] personalizados para pruebas unitarias.
  LocationController({
    LocationService? locationService,
    SupabaseService? supabaseService,
  })  : _locationService = locationService ?? const LocationService(),
        _supabaseService = supabaseService ?? SupabaseService();

  // --- Getters de estado para la Vista ---

  /// `true` mientras se solicita el permiso o se espera la posición GPS.
  bool get isLoading => _isLoading;

  /// `true` mientras se realiza la inserción en la base de datos Supabase.
  bool get isSaving => _isSaving;

  /// Posición geográfica obtenida más recientemente o `null` si aún no se ha obtenido.
  Position? get currentPosition => _currentPosition;

  /// Mensaje de error para mostrar en la interfaz o `null`.
  String? get errorMessage => _errorMessage;

  /// Mensaje de éxito tras una operación exitosa o `null`.
  String? get successMessage => _successMessage;

  /// Indica si ya se dispone de una posición válida para ser visualizada o guardada.
  bool get hasLocation => _currentPosition != null;

  // --- Métodos de Acción / Casos de Uso ---

  /// Solicita permisos si es necesario y obtiene la posición GPS actual del dispositivo.
  Future<void> fetchLocation() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentPosition();
      _currentPosition = position;
      _successMessage = 'Ubicación GPS obtenida con éxito.';
    } on LocationServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al obtener la ubicación: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Abre la pantalla de ajustes de ubicación del dispositivo (para activar el GPS).
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Abre la pantalla de ajustes de la aplicación (para habilitar permisos denegados).
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Limpia los mensajes de error o éxito.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Guarda la ubicación actual en Supabase.
  ///
  /// Se ejecuta ÚNICAMENTE tras confirmación o autorización explícita del usuario
  /// en la interfaz para cumplir con las consideraciones de privacidad (Sección 8).
  Future<bool> saveLocationToSupabase() async {
    final position = _currentPosition;
    if (position == null) {
      _errorMessage = 'No hay datos de ubicación disponibles para guardar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final reading = SensorReading(
        sensorType: SensorType.gps,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        recordedAt: position.timestamp,
      );

      await _supabaseService.insertReading(reading);

      _successMessage = 'Ubicación GPS guardada exitosamente en Supabase.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar la ubicación en Supabase: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
