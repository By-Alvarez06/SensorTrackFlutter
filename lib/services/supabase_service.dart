import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/sensor_reading.dart';
import '../models/sensor_type.dart';

/// Excepción controlada para errores de comunicación o permisos con Supabase.
class SupabaseServiceException implements Exception {
  /// Mensaje descriptivo en español orientado al usuario o controlador.
  final String message;

  /// Error original capturado para fines de depuración, si existe.
  final Object? cause;

  /// Crea una instancia de [SupabaseServiceException].
  const SupabaseServiceException(this.message, {this.cause});

  @override
  String toString() => 'SupabaseServiceException: $message';
}

/// Servicio encargado de toda la comunicación con la tabla `sensor_readings`
/// en Supabase (verificación de conexión, inserción y consultas).
class SupabaseService {
  /// Nombre de la tabla en PostgreSQL donde se persisten las mediciones.
  static const String _tableName = 'sensor_readings';

  final SupabaseClient? _injectedClient;

  /// Tiempo máximo de espera para cada operación remota contra Supabase.
  final Duration timeout;

  /// Crea una instancia de [SupabaseService].
  ///
  /// Permite inyectar un [client] personalizado para pruebas unitarias; si se
  /// omite, utiliza [SupabaseConfig.clientOrNull].
  SupabaseService({
    SupabaseClient? client,
    this.timeout = const Duration(seconds: 10),
  }) : _injectedClient = client;

  /// Obtiene el cliente activo de Supabase o `null` si no fue inicializado.
  SupabaseClient? get _client => _injectedClient ?? SupabaseConfig.clientOrNull;

  /// Verifica si la aplicación puede consultar la tabla `sensor_readings`.
  ///
  /// Ejecuta una consulta mínima (`SELECT id LIMIT 1`). Retorna `false` sin
  /// lanzar excepciones cuando Supabase no está configurado o hay error de red.
  Future<bool> checkConnection() async {
    final client = _client;
    if (client == null) {
      return false;
    }

    try {
      await client.from(_tableName).select('id').limit(1).timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Inserta una nueva medición [reading] en la tabla `sensor_readings`.
  ///
  /// Lanza [SupabaseServiceException] si Supabase no está inicializado, si se
  /// agota el tiempo de espera o si ocurre un error de PostgreSQL/RLS/red.
  Future<void> insertReading(SensorReading reading) async {
    final client = _requireClient();

    try {
      await client.from(_tableName).insert(reading.toJson()).timeout(timeout);
    } on PostgrestException catch (error) {
      throw SupabaseServiceException(
        'Error de base de datos al guardar la medición: ${error.message}',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw SupabaseServiceException(
        'Tiempo de espera agotado al conectar con Supabase.',
        cause: error,
      );
    } catch (error) {
      throw SupabaseServiceException(
        'No se pudo guardar la medición en Supabase. Verifica tu conexión.',
        cause: error,
      );
    }
  }

  /// Consulta las mediciones almacenadas en `sensor_readings`.
  ///
  /// Si se especifica [sensorType], filtra por ese sensor. Ordena siempre por
  /// `recorded_at` descendente (más recientes primero) hasta un máximo de [limit].
  /// Lanza [SupabaseServiceException] ante errores de conexión o permisos.
  Future<List<SensorReading>> fetchReadings({
    SensorType? sensorType,
    int limit = 100,
  }) async {
    final client = _requireClient();

    try {
      // En Postgrest v2 los filtros (.eq) deben aplicarse sobre
      // PostgrestFilterBuilder antes de las transformaciones (.order, .limit).
      var query = client.from(_tableName).select();
      if (sensorType != null) {
        query = query.eq('sensor_type', sensorType.dbValue);
      }

      final response = await query
          .order('recorded_at', ascending: false)
          .limit(limit)
          .timeout(timeout);

      return response
          .map<SensorReading>(
            (row) => SensorReading.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } on PostgrestException catch (error) {
      throw SupabaseServiceException(
        'Error al consultar el historial en Supabase: ${error.message}',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw SupabaseServiceException(
        'Tiempo de espera agotado al consultar registros en Supabase.',
        cause: error,
      );
    } catch (error) {
      throw SupabaseServiceException(
        'No se pudieron obtener las mediciones desde Supabase.',
        cause: error,
      );
    }
  }

  /// Obtiene una medición específica por su identificador [id] en Supabase.
  ///
  /// Retorna `null` si no existe ningún registro con ese identificador.
  /// Lanza [SupabaseServiceException] si ocurre un error de red o consulta.
  Future<SensorReading?> fetchReadingById(String id) async {
    final client = _requireClient();

    try {
      final response = await client
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(timeout);

      if (response == null) {
        return null;
      }

      return SensorReading.fromJson(Map<String, dynamic>.from(response));
    } on PostgrestException catch (error) {
      throw SupabaseServiceException(
        'Error al consultar el detalle de la medición: ${error.message}',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw SupabaseServiceException(
        'Tiempo de espera agotado al obtener el detalle desde Supabase.',
        cause: error,
      );
    } catch (error) {
      throw SupabaseServiceException(
        'No se pudo obtener el detalle de la medición en Supabase.',
        cause: error,
      );
    }
  }

  /// Valida que exista un cliente inicializado antes de ejecutar una consulta.
  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const SupabaseServiceException(
        'Supabase no está inicializado. Configura SUPABASE_URL y SUPABASE_KEY.',
      );
    }
    return client;
  }
}
