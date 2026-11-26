import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../config/supabase_config.dart';
import '../models/sensor_type.dart';
import '../services/supabase_service.dart';

/// Estados posibles de conectividad con Supabase mostrados en la pantalla Inicio.
enum SupabaseConnectionStatus {
  /// Comprobación en curso.
  checking,

  /// Conexión verificada correctamente contra la tabla `sensor_readings`.
  connected,

  /// No se pudo establecer comunicación con Supabase.
  disconnected,

  /// No se proporcionaron credenciales `SUPABASE_URL` / `SUPABASE_KEY`.
  notConfigured,
}

/// Estados de disponibilidad detectados para un sensor físico del dispositivo.
enum SensorAvailabilityStatus {
  /// Sondeo de disponibilidad en progreso.
  checking,

  /// El sensor respondió o el servicio está habilitado en el dispositivo.
  available,

  /// El sensor no está disponible, está desactivado o no emitió respuesta.
  unavailable,
}

/// Representa el resultado de disponibilidad de un [SensorType] específico.
class SensorAvailabilityItem {
  /// Tipo de sensor evaluado.
  final SensorType sensorType;

  /// Estado actual de disponibilidad del sensor.
  final SensorAvailabilityStatus status;

  /// Mensaje explicativo corto mostrado en la lista de Inicio.
  final String statusMessage;

  /// Crea una instancia inmutable de [SensorAvailabilityItem].
  const SensorAvailabilityItem({
    required this.sensorType,
    required this.status,
    required this.statusMessage,
  });

  /// Retorna una copia reemplazando los campos indicados.
  SensorAvailabilityItem copyWith({
    SensorAvailabilityStatus? status,
    String? statusMessage,
  }) {
    return SensorAvailabilityItem(
      sensorType: sensorType,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Callback inyectable para verificar la disponibilidad de un [SensorType].
typedef SensorProbeCallback = Future<bool> Function(SensorType type);

/// Callback inyectable para comprobar conectividad con Supabase.
typedef ConnectionCheckCallback = Future<bool> Function();

/// Callback inyectable para consultar si existen credenciales de Supabase.
typedef IsSupabaseConfiguredCallback = bool Function();

/// Controlador MVC de la pantalla principal ([HomePage]).
///
/// Coordina la verificación del estado de conexión con Supabase y realiza una
/// comprobación ligera y desacoplada de los sensores disponibles en el
/// dispositivo sin interferir con los servicios exclusivos de otros módulos.
class HomeController extends ChangeNotifier {
  final SupabaseService _supabaseService;
  final ConnectionCheckCallback? _connectionChecker;
  final IsSupabaseConfiguredCallback _isConfiguredChecker;
  final SensorProbeCallback? _sensorProbe;
  final Duration _probeTimeout;

  final List<StreamSubscription<dynamic>> _activeSubscriptions = [];
  final List<Timer> _activeTimers = [];

  bool _isDisposed = false;
  bool _isRefreshing = false;
  SupabaseConnectionStatus _connectionStatus =
      SupabaseConnectionStatus.checking;
  String _connectionMessage = 'Verificando estado de Supabase...';
  DateTime? _lastCheckedAt;
  late List<SensorAvailabilityItem> _sensors;

  /// Crea una instancia de [HomeController].
  ///
  /// Permite inyectar callbacks de prueba ([connectionChecker],
  /// [isConfiguredChecker], [sensorProbe]) para ejecutar tests unitarios
  /// deterministas sin hardware físico ni red real.
  HomeController({
    SupabaseService? supabaseService,
    ConnectionCheckCallback? connectionChecker,
    IsSupabaseConfiguredCallback? isConfiguredChecker,
    SensorProbeCallback? sensorProbe,
    Duration probeTimeout = const Duration(milliseconds: 600),
  })  : _supabaseService = supabaseService ?? SupabaseService(),
        _connectionChecker = connectionChecker,
        _isConfiguredChecker =
            isConfiguredChecker ?? (() => SupabaseConfig.isConfigured),
        _sensorProbe = sensorProbe,
        _probeTimeout = probeTimeout {
    _sensors = _buildInitialSensors();
  }

  /// Estado actual de la conexión con Supabase.
  SupabaseConnectionStatus get connectionStatus => _connectionStatus;

  /// Mensaje descriptivo del estado de Supabase para mostrar en la vista.
  String get connectionMessage => _connectionMessage;

  /// Indica si se está ejecutando una actualización completa actualmente.
  bool get isRefreshing => _isRefreshing;

  /// Fecha y hora de la última verificación completada, si ya ocurrió una.
  DateTime? get lastCheckedAt => _lastCheckedAt;

  /// Lista inmutable de sensores evaluados y su disponibilidad.
  List<SensorAvailabilityItem> get sensors => List.unmodifiable(_sensors);

  /// Cantidad de sensores detectados como disponibles en el dispositivo.
  int get availableSensorsCount => _sensors
      .where((item) => item.status == SensorAvailabilityStatus.available)
      .length;

  /// Inicializa los datos mostrados en [HomePage].
  Future<void> initialize() => refresh();

  /// Actualiza en paralelo el estado de Supabase y la lista de sensores.
  Future<void> refresh() async {
    if (_isDisposed) return;

    _isRefreshing = true;
    _sensors = _buildInitialSensors();
    _safeNotifyListeners();

    await Future.wait([checkSupabaseConnection(), _checkSensorsAvailability()]);

    if (_isDisposed) return;
    _lastCheckedAt = DateTime.now();
    _isRefreshing = false;
    _safeNotifyListeners();
  }

  /// Verifica únicamente el estado de conectividad con Supabase.
  Future<void> checkSupabaseConnection() async {
    if (_isDisposed) return;

    _connectionStatus = SupabaseConnectionStatus.checking;
    _connectionMessage = 'Verificando conexión con Supabase...';
    _safeNotifyListeners();

    // Si faltan variables --dart-define se informa de inmediato sin consultar red.
    if (!_isConfiguredChecker()) {
      if (_isDisposed) return;
      _connectionStatus = SupabaseConnectionStatus.notConfigured;
      _connectionMessage =
          'Ejecuta la app con --dart-define=SUPABASE_URL y SUPABASE_KEY.';
      _safeNotifyListeners();
      return;
    }

    bool connected = false;
    try {
      final checker = _connectionChecker ?? _supabaseService.checkConnection;
      connected = await checker();
    } catch (_) {
      connected = false;
    }

    if (_isDisposed) return;

    if (connected) {
      _connectionStatus = SupabaseConnectionStatus.connected;
      _connectionMessage = 'Base de datos sensor_readings operativa.';
    } else {
      _connectionStatus = SupabaseConnectionStatus.disconnected;
      _connectionMessage =
          'No se pudo conectar con Supabase. Verifica red o políticas RLS.';
    }
    _safeNotifyListeners();
  }

  /// Evalúa la disponibilidad de cada [SensorType] soportado por SensorTrack.
  Future<void> _checkSensorsAvailability() async {
    final results = await Future.wait(
      SensorType.values.map(_evaluateSingleSensor),
    );

    if (_isDisposed) return;
    _sensors = results;
    _safeNotifyListeners();
  }

  /// Evalúa un único [type] usando el probe inyectado o el sondeo por defecto.
  Future<SensorAvailabilityItem> _evaluateSingleSensor(SensorType type) async {
    if (type == SensorType.light && _sensorProbe == null) {
      return const SensorAvailabilityItem(
        sensorType: SensorType.light,
        status: SensorAvailabilityStatus.unavailable,
        statusMessage: 'Sensor opcional (requiere plugin dedicado)',
      );
    }

    bool isAvailable = false;
    try {
      final probe = _sensorProbe ?? _defaultSensorProbe;
      isAvailable = await probe(type);
    } catch (_) {
      isAvailable = false;
    }

    return SensorAvailabilityItem(
      sensorType: type,
      status: isAvailable
          ? SensorAvailabilityStatus.available
          : SensorAvailabilityStatus.unavailable,
      statusMessage: _statusMessageFor(type, isAvailable),
    );
  }

  /// Sondeo ligero por defecto usando `sensors_plus` y `geolocator` en solo lectura.
  Future<bool> _defaultSensorProbe(SensorType type) async {
    switch (type) {
      case SensorType.accelerometer:
        return _probeStream(accelerometerEventStream());
      case SensorType.gyroscope:
        return _probeStream(gyroscopeEventStream());
      case SensorType.magnetometer:
        return _probeStream(magnetometerEventStream());
      case SensorType.gps:
        try {
          // Solo consulta si el servicio de ubicación está activo, sin pedir
          // permisos ni capturar coordenadas del usuario desde Home.
          return await Geolocator.isLocationServiceEnabled().timeout(
            _probeTimeout,
          );
        } catch (_) {
          return false;
        }
      case SensorType.light:
        return false;
    }
  }

  /// Escucha un único evento de [stream] con timeout para comprobar hardware activo.
  Future<bool> _probeStream(Stream<dynamic> stream) {
    if (_isDisposed) {
      return Future.value(false);
    }

    final completer = Completer<bool>();
    late StreamSubscription<dynamic> subscription;
    late Timer timer;

    void completeProbe(bool available) {
      if (timer.isActive) {
        timer.cancel();
      }
      _activeTimers.remove(timer);
      _activeSubscriptions.remove(subscription);
      unawaited(subscription.cancel());

      if (!completer.isCompleted) {
        completer.complete(available);
      }
    }

    timer = Timer(_probeTimeout, () => completeProbe(false));
    _activeTimers.add(timer);

    try {
      subscription = stream.listen(
        (_) => completeProbe(true),
        onError: (_) => completeProbe(false),
        cancelOnError: true,
      );
      _activeSubscriptions.add(subscription);
    } catch (_) {
      timer.cancel();
      _activeTimers.remove(timer);
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Genera la lista inicial de sensores en estado [SensorAvailabilityStatus.checking].
  List<SensorAvailabilityItem> _buildInitialSensors() {
    return SensorType.values
        .map(
          (type) => SensorAvailabilityItem(
            sensorType: type,
            status: SensorAvailabilityStatus.checking,
            statusMessage: 'Verificando disponibilidad...',
          ),
        )
        .toList();
  }

  /// Construye un mensaje descriptivo claro según el sensor y su resultado.
  String _statusMessageFor(SensorType type, bool isAvailable) {
    if (isAvailable) {
      return switch (type) {
        SensorType.gps => 'Servicio de ubicación activo',
        _ => 'Sensor operativo en el dispositivo',
      };
    }

    return switch (type) {
      SensorType.gps => 'GPS desactivado o no disponible',
      SensorType.light => 'Sensor opcional (requiere plugin dedicado)',
      _ => 'Sin respuesta del sensor en este dispositivo',
    };
  }

  /// Notifica a los observadores solo si el controlador no fue destruido.
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    for (final timer in List<Timer>.from(_activeTimers)) {
      timer.cancel();
    }
    _activeTimers.clear();

    for (final subscription in List<StreamSubscription<dynamic>>.from(
      _activeSubscriptions,
    )) {
      unawaited(subscription.cancel());
    }
    _activeSubscriptions.clear();

    super.dispose();
  }
}
