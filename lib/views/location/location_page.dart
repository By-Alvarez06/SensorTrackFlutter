import 'package:material_ui/material_ui.dart';

import '../../controllers/location_controller.dart';

/// Pantalla del módulo de ubicación geográfica (GPS).
///
/// Permite al usuario solicitar permisos de ubicación, leer las coordenadas
/// del GPS en tiempo real y persistirlas en Supabase con autorización explícita.
class LocationPage extends StatefulWidget {
  /// Crea una instancia de [LocationPage].
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final LocationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LocationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Muestra un mensaje flotante tipo SnackBar.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Abre un diálogo de confirmación explícito antes de guardar las coordenadas en Supabase.
  Future<void> _confirmSaveLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar guardado de ubicación'),
          content: const Text(
            '¿Deseas registrar tus coordenadas GPS actuales (latitud, longitud y precisión) en la base de datos de Supabase?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Aceptar y Guardar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _controller.saveLocationToSupabase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación GPS'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          // Notificación reactiva de errores y éxitos
          if (_controller.errorMessage != null) {
            final error = _controller.errorMessage!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showMessage(error, isError: true);
                _controller.clearMessages();
              }
            });
          } else if (_controller.successMessage != null) {
            final success = _controller.successMessage!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showMessage(success);
                _controller.clearMessages();
              }
            });
          }

          final position = _controller.currentPosition;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Botón principal para obtener la ubicación actual
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _controller.isLoading || _controller.isSaving
                      ? null
                      : () => _controller.fetchLocation(),
                  icon: _controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _controller.isLoading
                        ? 'Obteniendo GPS...'
                        : 'Obtener mi ubicación actual',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta con los datos de ubicación
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Coordenadas Geográficas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (position == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.location_searching,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aún no se ha capturado la ubicación GPS.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        _LocationInfoRow(
                          icon: Icons.explore,
                          label: 'Latitud',
                          value: '${position.latitude.toStringAsFixed(6)}°',
                        ),
                        const SizedBox(height: 12),
                        _LocationInfoRow(
                          icon: Icons.explore_outlined,
                          label: 'Longitud',
                          value: '${position.longitude.toStringAsFixed(6)}°',
                        ),
                        const SizedBox(height: 12),
                        _LocationInfoRow(
                          icon: Icons.gps_fixed,
                          label: 'Precisión estimada',
                          value:
                              '±${position.accuracy.toStringAsFixed(1)} metros',
                        ),
                        const SizedBox(height: 12),
                        _LocationInfoRow(
                          icon: Icons.access_time,
                          label: 'Fecha y hora',
                          value: position.timestamp
                              .toLocal()
                              .toString()
                              .split('.')[0],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón explícito para guardar en Supabase (solo si hay ubicación)
              if (_controller.hasLocation)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        _controller.isSaving ? null : _confirmSaveLocation,
                    icon: _controller.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _controller.isSaving
                          ? 'Guardando en Supabase...'
                          : 'Guardar ubicación en Supabase',
                    ),
                  ),
                ),

              // Botones de ayuda para abrir ajustes si hubo problemas de permisos
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _controller.openLocationSettings(),
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Ajustes GPS'),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _controller.openAppSettings(),
                      icon: const Icon(Icons.app_settings_alt, size: 18),
                      label: const Text('Permisos App'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fila para presentar una propiedad de ubicación con su icono, etiqueta y valor formateado.
class _LocationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LocationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
