import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

/// Servicio responsable de comunicarse con el hardware de sensores del dispositivo.
///
/// Encapsula las llamadas directas al paquete `sensors_plus` para acelerómetro y
/// giroscopio, desacoplando los controladores de la biblioteca de hardware.
class SensorService {
  final Stream<AccelerometerEvent>? _customAccelerometerStream;
  final Stream<GyroscopeEvent>? _customGyroscopeStream;

  /// Crea una instancia de [SensorService].
  ///
  /// Permite inyectar streams personalizados en pruebas unitarias para simular
  /// eventos de acelerómetro y giroscopio sin requerir sensores físicos reales.
  SensorService({
    Stream<AccelerometerEvent>? accelerometerStream,
    Stream<GyroscopeEvent>? gyroscopeStream,
  })  : _customAccelerometerStream = accelerometerStream,
        _customGyroscopeStream = gyroscopeStream;

  /// Stream continuo de eventos emitidos por el acelerómetro físico del dispositivo.
  ///
  /// Retorna las aceleraciones en los ejes X, Y y Z en metros por segundo al cuadrado (m/s²),
  /// incluyendo la gravedad terrestre (~9.8 m/s²).
  Stream<AccelerometerEvent> get accelerometerEvents =>
      _customAccelerometerStream ?? accelerometerEventStream();

  /// Stream continuo de eventos emitidos por el giroscopio físico del dispositivo.
  ///
  /// Retorna la velocidad de rotación angular en los ejes X, Y y Z en radianes por segundo (rad/s).
  Stream<GyroscopeEvent> get gyroscopeEvents =>
      _customGyroscopeStream ?? gyroscopeEventStream();
}
