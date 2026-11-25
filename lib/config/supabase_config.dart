import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuración centralizada y segura para la conexión con Supabase.
///
/// Las credenciales se inyectan en tiempo de compilación mediante `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
///   --dart-define=SUPABASE_KEY=tu-clave-publica
/// ```
abstract final class SupabaseConfig {
  /// URL del proyecto Supabase leída desde `--dart-define=SUPABASE_URL`.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Clave pública (Publishable key) leída desde `--dart-define=SUPABASE_KEY`.
  static const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');

  /// Bandera interna para evitar acceder a `Supabase.instance` si no inicializó.
  static bool _isInitialized = false;

  /// Indica si se proveyeron tanto [supabaseUrl] como [supabaseKey].
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  /// Indica si [Supabase.initialize] finalizó correctamente en esta sesión.
  static bool get isInitialized => _isInitialized;

  /// Retorna la instancia activa de [SupabaseClient] o `null` si no está lista.
  static SupabaseClient? get clientOrNull =>
      _isInitialized ? Supabase.instance.client : null;

  /// Inicializa el SDK de Supabase si las credenciales están configuradas.
  ///
  /// Nunca lanza excepciones no controladas al arrancar la app: si faltan
  /// credenciales o falla la inicialización, registra un aviso con [debugPrint]
  /// y retorna `false` para que la interfaz informe el estado desconectado.
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    if (!isConfigured) {
      debugPrint(
        'SupabaseConfig: faltan SUPABASE_URL o SUPABASE_KEY en --dart-define. '
        'La aplicación iniciará en modo sin conexión.',
      );
      return false;
    }

    try {
      // En supabase_flutter ^2.18.3 el parámetro oficial es `publishableKey`.
      await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
      _isInitialized = true;
      return true;
    } catch (error) {
      debugPrint('SupabaseConfig: error al inicializar Supabase: $error');
      _isInitialized = false;
      return false;
    }
  }
}
