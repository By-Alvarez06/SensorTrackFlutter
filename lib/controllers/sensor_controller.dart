import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/sensor_reading.dart';
import '../models/sensor_type.dart';
import '../services/sensor_service.dart';
import '../services/supabase_service.dart';

/// Controlador MVC para la pantalla de monitoreo en tiempo real de sensores físicos.
///
/// Gestiona las suscripciones a los streams de acelerómetro y giroscopio,
/// administra el estado de la UI (valores en tiempo real, banderas de carga/error)
/// y permite guardar mediciones puntuales en Supabase sin saturar la red.
class SensorController extends ChangeNotifier {
  final SensorService _sensorService;
  final SupabaseService _supabaseService;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  /// Indica si el monitoreo de los sensores se encuentra activo.
  bool _isMonitoring = false;

  /// Indica si se está guardando una medición en Supabase actualmente.
  bool _isSaving = false;

  /// Mensaje de error para mostrar al usuario, si ocurre alguno.
  String? _errorMessage;

  /// Mensaje de éxito temporal para retroalimentación visual al guardar.
  String? _successMessage;

  // Valores más recientes del acelerómetro (m/s²)
  double? _accelX;
  double? _accelY;
  double? _accelZ;

  // Valores más recientes del giroscopio (rad/s)
  double? _gyroX;
  double? _gyroY;
  double? _gyroZ;

  // Banderas de disponibilidad física de los sensores en el dispositivo
  bool _isAccelerometerAvailable = true;
  bool _isGyroscopeAvailable = true;

  /// Crea una instancia de [SensorController].
  ///
  /// Permite inyectar [sensorService] y [supabaseService] personalizados para pruebas unitarias.
  SensorController({
    SensorService? sensorService,
    SupabaseService? supabaseService,
  })  : _sensorService = sensorService ?? SensorService(),
        _supabaseService = supabaseService ?? SupabaseService();

  // --- Getters de estado para la Vista ---

  /// `true` si se están escuchando los streams de sensores actualmente.
  bool get isMonitoring => _isMonitoring;

  /// `true` mientras se realiza la inserción de una medición en Supabase.
  bool get isSaving => _isSaving;

  /// Mensaje de error activo o `null`.
  String? get errorMessage => _errorMessage;

  /// Mensaje de éxito activo o `null`.
  String? get successMessage => _successMessage;

  /// Valor actual del eje X del acelerómetro.
  double? get accelX => _accelX;

  /// Valor actual del eje Y del acelerómetro.
  double? get accelY => _accelY;

  /// Valor actual del eje Z del acelerómetro.
  double? get accelZ => _accelZ;

  /// Valor actual de rotación en X del giroscopio.
  double? get gyroX => _gyroX;

  /// Valor actual de rotación en Y del giroscopio.
  double? get gyroY => _gyroY;

  /// Valor actual de rotación en Z del giroscopio.
  double? get gyroZ => _gyroZ;

  /// Indica si el acelerómetro está disponible y emitiendo datos sin error.
  bool get isAccelerometerAvailable => _isAccelerometerAvailable;

  /// Indica si el giroscopio está disponible y emitiendo datos sin error.
  bool get isGyroscopeAvailable => _isGyroscopeAvailable;

  // --- Métodos de Acción / Casos de Uso ---

  /// Inicia el monitoreo continuo de los sensores físico (acelerómetro y giroscopio).
  void startMonitoring() {
    if (_isMonitoring) return;

    _errorMessage = null;
    _successMessage = null;

    // 1. Suscripción al acelerómetro
    _accelerometerSubscription = _sensorService.accelerometerEvents.listen(
      (event) {
        _accelX = event.x;
        _accelY = event.y;
        _accelZ = event.z;
        _isAccelerometerAvailable = true;
        notifyListeners();
      },
      onError: (error) {
        // Si el hardware no dispone del sensor o falla el canal nativo
        _isAccelerometerAvailable = false;
        _errorMessage =
            'El acelerómetro no está disponible en este dispositivo.';
        notifyListeners();
      },
      cancelOnError: false,
    );

    // 2. Suscripción al giroscopio
    _gyroscopeSubscription = _sensorService.gyroscopeEvents.listen(
      (event) {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
        _isGyroscopeAvailable = true;
        notifyListeners();
      },
      onError: (error) {
        // En emuladores o ciertos terminales de gama baja puede no existir giroscopio
        _isGyroscopeAvailable = false;
        _errorMessage = 'El giroscopio no está disponible en este dispositivo.';
        notifyListeners();
      },
      cancelOnError: false,
    );

    _isMonitoring = true;
    notifyListeners();
  }

  /// Detiene el monitoreo y cancela las suscripciones activas a los streams.
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;

    _isMonitoring = false;
    notifyListeners();
  }

  /// Limpia los mensajes de error o éxito mostrados en la vista.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Guarda una captura puntual del sensor especificado ([type]) en la base de datos Supabase.
  ///
  /// Cumple con la regla anti-spam de la Sección 8: únicamente persiste bajo demanda
  /// cuando el usuario presiona el botón "Guardar medición".
  Future<bool> saveReading(SensorType type) async {
    // Validar que tengamos datos disponibles para el sensor seleccionado
    if (type == SensorType.accelerometer &&
        (_accelX == null || _accelY == null || _accelZ == null)) {
      _errorMessage = 'No hay lecturas del acelerómetro para guardar.';
      notifyListeners();
      return false;
    }

    if (type == SensorType.gyroscope &&
        (_gyroX == null || _gyroY == null || _gyroZ == null)) {
      _errorMessage = 'No hay lecturas del giroscopio para guardar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final reading = SensorReading(
        sensorType: type,
        x: type == SensorType.accelerometer ? _accelX : _gyroX,
        y: type == SensorType.accelerometer ? _accelY : _gyroY,
        z: type == SensorType.accelerometer ? _accelZ : _gyroZ,
        recordedAt: DateTime.now(),
      );

      await _supabaseService.insertReading(reading);

      _successMessage =
          'Medición de ${type.displayName} guardada exitosamente en Supabase.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar en Supabase: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    // Esencial para evitar fugas de memoria: cancelar siempre streams abiertos
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }
}
