import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Excepción de dominio para errores ocurridos durante la lectura del GPS o gestión de permisos.
class LocationServiceException implements Exception {
  /// Mensaje en español explicando la causa del error.
  final String message;

  /// Crea una instancia de [LocationServiceException].
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

/// Servicio encargado de la comunicación con el hardware GPS del dispositivo y la gestión de permisos.
///
/// Encapsula la API del paquete `geolocator` para comprobar disponibilidad del servicio,
/// solicitar permisos en tiempo de ejecución y obtener la posición actual.
class LocationService {
  /// Crea una instancia de [LocationService].
  const LocationService();

  /// Comprueba si el hardware o servicio de localización está encendido en el dispositivo.
  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Verifica el estado actual de los permisos de ubicación otorgados por el usuario.
  Future<LocationPermission> checkPermission() async {
    return Geolocator.checkPermission();
  }

  /// Solicita explícitamente los permisos de ubicación al usuario mediante el diálogo del sistema operativo.
  Future<LocationPermission> requestPermission() async {
    return Geolocator.requestPermission();
  }

  /// Abre la pantalla de configuración de ubicación del sistema para que el usuario pueda activarla.
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Abre la pantalla de ajustes de la aplicación para que el usuario gestione los permisos denegados permanentemente.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Obtiene la posición geográfica actual del dispositivo mediante el GPS.
  ///
  /// Lanza [LocationServiceException] si los servicios están desactivados,
  /// si los permisos fueron denegados o si no se pudo determinar la posición.
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 15),
  }) async {
    // 1. Verificar si el servicio de ubicación está habilitado en el dispositivo
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceException(
        'El servicio de ubicación (GPS) está desactivado en el dispositivo. Por favor actívalo.',
      );
    }

    // 2. Comprobar permisos
    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Los permisos de ubicación fueron denegados por el usuario.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Los permisos de ubicación están denegados permanentemente. Debes habilitarlos desde los Ajustes del sistema.',
      );
    }

    // 3. Obtener la posición con configuración de precisión y tiempo límite
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      throw const LocationServiceException(
        'Se agotó el tiempo de espera para obtener la señal GPS del dispositivo.',
      );
    } catch (e) {
      throw LocationServiceException(
        'No se pudo obtener la ubicación actual: $e',
      );
    }
  }
}
