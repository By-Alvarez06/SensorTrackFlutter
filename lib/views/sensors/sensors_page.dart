import 'package:material_ui/material_ui.dart';

import '../../controllers/sensor_controller.dart';
import '../../models/sensor_type.dart';

/// Pantalla de monitoreo en tiempo real de acelerómetro y giroscopio.
///
/// Permite al usuario iniciar y pausar el monitoreo de los sensores físicos
/// y guardar mediciones puntuales en Supabase bajo demanda.
class SensorsPage extends StatefulWidget {
  /// Crea una instancia de [SensorsPage].
  const SensorsPage({super.key});

  @override
  State<SensorsPage> createState() => _SensorsPageState();
}

class _SensorsPageState extends State<SensorsPage> {
  late final SensorController _controller;

  @override
  void initState() {
    super.initState();
    // Instanciar el controlador MVC
    _controller = SensorController();
  }

  @override
  void dispose() {
    // Liberar recursos y cancelar suscripciones a los streams
    _controller.dispose();
    super.dispose();
  }

  /// Muestra un SnackBar con mensajes de éxito o error al usuario.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoreo de Sensores'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          // Detectar mensajes pendientes y mostrarlos de forma segura
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Barra de control de monitoreo (Iniciar / Detener)
              Card(
                color: _controller.isMonitoring
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _controller.isMonitoring
                            ? Icons.sensors
                            : Icons.sensors_off,
                        color: _controller.isMonitoring
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _controller.isMonitoring
                                  ? 'Monitoreo activo'
                                  : 'Monitoreo detenido',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _controller.isMonitoring
                                  ? 'Leyendo datos en tiempo real'
                                  : 'Presiona Iniciar para comenzar',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _controller.isSaving
                            ? null
                            : () {
                                if (_controller.isMonitoring) {
                                  _controller.stopMonitoring();
                                } else {
                                  _controller.startMonitoring();
                                }
                              },
                        icon: Icon(
                          _controller.isMonitoring
                              ? Icons.stop
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _controller.isMonitoring ? 'Detener' : 'Iniciar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarjeta 1: Acelerómetro
              _SensorDisplayCard(
                title: 'Acelerómetro',
                unit: 'm/s²',
                icon: Icons.speed,
                isAvailable: _controller.isAccelerometerAvailable,
                isSaving: _controller.isSaving,
                x: _controller.accelX,
                y: _controller.accelY,
                z: _controller.accelZ,
                onSave: () => _controller.saveReading(SensorType.accelerometer),
              ),
              const SizedBox(height: 16),

              // Tarjeta 2: Giroscopio
              _SensorDisplayCard(
                title: 'Giroscopio',
                unit: 'rad/s',
                icon: Icons.rotate_right,
                isAvailable: _controller.isGyroscopeAvailable,
                isSaving: _controller.isSaving,
                x: _controller.gyroX,
                y: _controller.gyroY,
                z: _controller.gyroZ,
                onSave: () => _controller.saveReading(SensorType.gyroscope),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget reutilizable para mostrar los ejes X, Y, Z y el botón de guardado de un sensor.
class _SensorDisplayCard extends StatelessWidget {
  final String title;
  final String unit;
  final IconData icon;
  final bool isAvailable;
  final bool isSaving;
  final double? x;
  final double? y;
  final double? z;
  final VoidCallback onSave;

  const _SensorDisplayCard({
    required this.title,
    required this.unit,
    required this.icon,
    required this.isAvailable,
    required this.isSaving,
    required this.x,
    required this.y,
    required this.z,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '($unit)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 24),
            if (!isAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Este sensor no está disponible o no se detecta en el dispositivo.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AxisValueColumn(axis: 'X', value: x),
                  _AxisValueColumn(axis: 'Y', value: y),
                  _AxisValueColumn(axis: 'Z', value: z),
                ],
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    (isSaving || !isAvailable || x == null) ? null : onSave,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Guardar medición'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Columna individual que muestra el valor de un eje específico formateado a 2 decimales.
class _AxisValueColumn extends StatelessWidget {
  final String axis;
  final double? value;

  const _AxisValueColumn({
    required this.axis,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Eje $axis',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value != null ? value!.toStringAsFixed(2) : '--',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
