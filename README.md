# SensorTrack (`sensortrack_flutter`)

Aplicación móvil desarrollada en **Flutter y Dart** para capturar información en tiempo real desde los sensores físicos de un dispositivo móvil (acelerómetro, giroscopio y GPS), visualizar estadísticas y almacenar registros históricos en **Supabase** (PostgreSQL).

> **Guía completa de arquitectura, contratos y reglas para agentes de IA:** consultar [`CLAUDE.md`](./CLAUDE.md).
> **Documento oficial de requerimientos:** [`Taller_SensorTrack_Flutter_Sensores_Supabase.docx`](./Taller_SensorTrack_Flutter_Sensores_Supabase.docx).

---

## Stack Tecnológico y Dependencias Instaladas

Las dependencias requeridas ya están configuradas en `pubspec.yaml`:

| Paquete | Versión | Propósito |
| --- | --- | --- |
| `supabase_flutter` | `^2.18.3` | Conexión y persistencia en PostgreSQL (Supabase) |
| `sensors_plus` | `^7.1.1` | Lectura en tiempo real de acelerómetro y giroscopio |
| `geolocator` | `^14.1.2` | Permisos nativos y lectura de ubicación GPS y precisión |
| `fl_chart` | `^1.3.1` | Gráficos estadísticos de evolución de mediciones |

---

## Instalación y Ejecución

1. **Descargar dependencias:**
   ```bash
   flutter pub get
   ```

2. **Ejecutar pasando las credenciales de Supabase de forma segura** (nunca hardcodear claves en el código fuente):
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co \
     --dart-define=SUPABASE_KEY=tu-clave-publica
   ```

---

## Arquitectura MVC del Proyecto

```text
lib/
├── main.dart           # Punto de entrada e inicialización de Supabase
├── config/             # Constantes, tema Material 3, rutas y configuración Supabase
├── models/             # [M] Modelos inmutables de dominio (SensorType, SensorReading, SensorStats)
├── services/           # Capa de acceso a hardware (sensors_plus, geolocator) y Supabase
├── controllers/        # [C] ChangeNotifier por módulo/pantalla, streams y lógica de UI
└── views/              # [V] Pantallas (splash, home, sensors, location, history, stats) y widgets
```

---

## División de Trabajo en Equipo (3 Integrantes — Specs Independientes)

El desarrollo se organiza en **Fase 0** (contratos base y stubs de rutas por el Integrante 1), **Fase 1** (trabajo 100% en paralelo sin tocar archivos de otros) y **Fase 2** (integración en `develop` y pruebas en dispositivo físico).

| Integrante | Módulos | Rama en Fase 1 | Carpetas / Archivos exclusivos (R/W) |
| --- | --- | --- | --- |
| **Integrante 1** | Core, SQL/RLS, Splash e Inicio (Módulo 1 + Base Módulo 3) | `feature/int1-home-splash` | `sql/`, `lib/main.dart`, `lib/config/`, `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`, `lib/services/supabase_service.dart`, `lib/controllers/home_controller.dart`, `lib/views/splash/`, `lib/views/home/`, `lib/views/widgets/` |
| **Integrante 2** | Sensores físicos y Ubicación GPS (Módulo 2 + Guardado) | `feature/int2-sensors-location` | `lib/services/sensor_service.dart`, `lib/services/location_service.dart`, `lib/controllers/sensor_controller.dart`, `lib/controllers/location_controller.dart`, `lib/views/sensors/`, `lib/views/location/`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` |
| **Integrante 3** | Historial, Detalle y Estadísticas (Módulo 4 + Módulo 5) | `feature/int3-history-stats` | `lib/models/sensor_stats.dart`, `lib/controllers/history_controller.dart`, `lib/controllers/stats_controller.dart`, `lib/views/history/`, `lib/views/stats/` |

> **Importante para el uso de agentes de IA:** antes de iniciar cada tarea, entrega a tu agente el prompt específico de tu Spec ubicado en la **Sección 10.E de [`CLAUDE.md`](./CLAUDE.md)** para garantizar que respete los contratos congelados y no modifique archivos de otros integrantes.

---

## Comandos de Verificación

Ejecutar antes de cada commit o Pull Request:

```bash
dart format .
flutter analyze
flutter test
```
