# CLAUDE.md — Guía del Proyecto SensorTrack

> **Documento de referencia oficial del equipo** para el desarrollo de **SensorTrack** (Asignatura: *Desarrollo de Plataformas Móviles*).
> Todo colaborador humano o asistente de código debe seguir estrictamente las especificaciones, arquitectura MVC y estándares de documentación definidos en este archivo, basados en `Taller_SensorTrack_Flutter_Sensores_Supabase.docx`.

---

## 1. Resumen del Proyecto

- **Nombre de la aplicación:** `SensorTrack`
- **Nombre del paquete Dart/Flutter:** `sensortrack_flutter`
- **Versión de SDK Dart:** `^3.14.0` (según `pubspec.yaml`)
- **Objetivo:** Desarrollar una aplicación móvil en **Flutter y Dart** que capture información en tiempo real desde los sensores físicos del dispositivo móvil, procese y visualice los datos obtenidos, calcule estadísticas y almacene registros históricos en una base de datos PostgreSQL en la nube mediante **Supabase**.
- **Documento fuente de requerimientos:** `Taller_SensorTrack_Flutter_Sensores_Supabase.docx` (en la raíz del repositorio).

---

## 2. Sensores a Implementar

El taller exige implementar **al menos tres (3)** sensores o capacidades físicas del dispositivo. El proyecto estandariza los siguientes:

### Sensores obligatorios (base del proyecto)
1. **Acelerómetro**
   - **Datos:** Aceleración en ejes `X`, `Y`, `Z` (`double`).
   - **Aplicación:** Detectar movimiento del dispositivo en tiempo real.
   - **Identificador `sensor_type` en BD:** `'accelerometer'`
2. **Giroscopio**
   - **Datos:** Velocidad angular / rotación en ejes `X`, `Y`, `Z` (`double`).
   - **Aplicación:** Detectar rotaciones físicas del dispositivo.
   - **Identificador `sensor_type` en BD:** `'gyroscope'`
3. **GPS / Ubicación**
   - **Datos:** `latitude`, `longitude`, precisión (`accuracy`) y fecha/hora de captura (`recorded_at`).
   - **Aplicación:** Obtener ubicación geográfica y mostrarla en interfaz (y opcionalmente en mapa).
   - **Identificador `sensor_type` en BD:** `'gps'`

### Sensores opcionales contemplados en el taller
La arquitectura debe quedar preparada (mediante enum `SensorType` extensible) para soportar opcionalmente:
- **Magnetómetro** (`'magnetometer'`): Campo magnético para obtener orientación.
- **Sensor de luz** (`'light'`): Intensidad luminosa para detectar condiciones de iluminación.

---

## 3. Requerimientos Funcionales y Pantallas

La aplicación se organiza en una pantalla de bienvenida (**Splash**) y **5 módulos / pantallas principales**:

### Splash Screen (`lib/views/splash/`)
- Mostrar el nombre de la aplicación: **SensorTrack** mientras se completa la inicialización de la app y la verificación inicial de conexión con Supabase.

### Módulo 1 — Pantalla Principal / Inicio (`lib/views/home/`)
- Presentar el menú principal de navegación hacia los módulos (Sensores, Ubicación, Historial, Estadísticas).
- Mostrar el **estado de conexión con Supabase** (conectado / desconectado / error).
- Mostrar el **listado/resumen de sensores disponibles** en el dispositivo físico.

### Módulo 2 — Monitoreo de Sensores (`lib/views/sensors/`)
- Visualizar en tiempo real los valores de **Acelerómetro** (ejes `X`, `Y`, `Z`).
- Visualizar en tiempo real los valores de **Giroscopio** (rotación en `X`, `Y`, `Z`).
- Incluir controles explícitos para **iniciar y detener el monitoreo** (evitar lecturas continuas descontroladas).
- Incluir un botón explícito denominado **"Guardar medición"** para persistir una captura puntual en Supabase.
- (Opcional) Modo de captura automática con intervalo/frecuencia configurable.

### Módulo 2 (GPS) / Pantalla 3 — Ubicación (`lib/views/location/`)
- Solicitar y gestionar los permisos de ubicación antes de leer el GPS.
- Obtener y mostrar **latitud**, **longitud**, **precisión** (`accuracy`) y **fecha/hora de captura**.
- Mostrar la ubicación en la interfaz y, opcionalmente, en un mapa.
- Permitir guardar la ubicación en Supabase **únicamente con conocimiento y autorización explícita del usuario**.

### Módulo 3 — Registro de Información en Supabase (`lib/services/supabase_service.dart`)
- Conectar la app Flutter con el proyecto Supabase.
- Permitir guardar mediciones de acelerómetro, giroscopio y coordenadas GPS con su precisión y marca de tiempo (`recorded_at`).
- Permitir consultar los registros almacenados para alimentar el historial y las estadísticas.
- Manejar correctamente errores de conexión, permisos o políticas RLS.

### Módulo 4 — Historial de Mediciones (`lib/views/history/`)
- Consultar y listar los registros almacenados en Supabase mostrando:
  - Tipo de sensor (`sensor_type`).
  - Valores registrados (`x`, `y`, `z` según corresponda).
  - Fecha y hora (`recorded_at`).
  - Ubicación (`latitude`, `longitude`, `accuracy`) cuando corresponda.
- Permitir seleccionar un registro de la lista para **consultar sus detalles completos** (en pantalla o modal/vista de detalle).

### Módulo 5 — Estadísticas y Visualización (`lib/views/stats/`)
- Mostrar métricas calculadas a partir de los datos registrados:
  - **Cantidad total de registros.**
  - **Número de mediciones por sensor.**
  - **Valores máximos y mínimos del acelerómetro.**
  - **Última ubicación registrada.**
  - **Gráfico de evolución de las mediciones** utilizando `fl_chart`.

---

## 4. Stack Tecnológico, Dependencias y Permisos Nativos

### Paquetes instalados
Las 4 dependencias obligatorias del taller **ya están instaladas y congeladas** en `pubspec.yaml`. Los integrantes del equipo únicamente deben ejecutar `flutter pub get` al clonar o actualizar ramas, y **NO deben modificar `pubspec.yaml` ni `pubspec.lock`** durante el desarrollo paralelo sin acuerdo previo del equipo:

```bash
flutter pub get
```

| Tecnología / Paquete | Versión en `pubspec.yaml` | Utilidad en SensorTrack |
| --- | --- | --- |
| `flutter` | SDK (`dart ^3.14.0`) | Framework de desarrollo móvil multiplataforma |
| `supabase_flutter` | `^2.18.3` | Cliente oficial para conexión y consultas a Supabase (PostgreSQL) |
| `sensors_plus` | `^7.1.1` | Lectura en tiempo real de acelerómetro, giroscopio (y magnetómetro) |
| `geolocator` | `^14.1.2` | Gestión de permisos y lectura de ubicación GPS y precisión |
| `fl_chart` | `^1.3.1` | Gráficos estadísticos de evolución de mediciones |

> **Nota importante sobre UI en `pubspec.yaml`:** El proyecto inicial incluye `material_ui: ^1.1.0` proveniente del template inicial de Flutter/Dart (`sdk: ^3.14.0`). No lo elimines de `pubspec.yaml` sin validar compatibilidad previa; sin embargo, para mantener consistencia entre pantallas y con los ejemplos del taller, todo el código nuevo en `lib/` debe estandarizarse importando **`package:flutter/material.dart`** (Material 3 estándar de Flutter).

### Permisos nativos requeridos
Al configurar el módulo de ubicación (`geolocator`), verificar los manifiestos nativos:

- **Android** (`android/app/src/main/AndroidManifest.xml`):
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
- **iOS** (`ios/Runner/Info.plist`):
  - Agregar `NSLocationWhenInUseUsageDescription` con un mensaje claro en español explicando al usuario por qué SensorTrack necesita acceder a su ubicación.

---

## 5. Base de Datos en Supabase y Seguridad

### Esquema de la tabla `sensor_readings`
Crear la tabla en el editor SQL de Supabase y guardar el script completo (incluyendo políticas RLS) en `sql/create_sensor_readings.sql` (Entregable #5):

```sql
CREATE TABLE sensor_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_type TEXT NOT NULL,
    x DOUBLE PRECISION,
    y DOUBLE PRECISION,
    z DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);
```

| Campo | Tipo de dato | Descripción |
| --- | --- | --- |
| `id` | `UUID` | Identificador único del registro (`gen_random_uuid()`) |
| `sensor_type` | `TEXT` | Tipo de sensor (`'accelerometer'`, `'gyroscope'`, `'gps'`, etc.) |
| `x` | `DOUBLE PRECISION` | Valor del eje X |
| `y` | `DOUBLE PRECISION` | Valor del eje Y |
| `z` | `DOUBLE PRECISION` | Valor del eje Z |
| `latitude` | `DOUBLE PRECISION` | Latitud geográfica |
| `longitude` | `DOUBLE PRECISION` | Longitud geográfica |
| `accuracy` | `DOUBLE PRECISION` | Precisión del GPS en metros |
| `recorded_at` | `TIMESTAMPTZ` | Fecha y hora de captura (`NOW()`) |

### Políticas RLS (Row Level Security)
- Si se habilita RLS en `sensor_readings` (recomendado en las consideraciones técnicas del taller), documentar y versionar las políticas `SELECT` e `INSERT` en `sql/create_sensor_readings.sql` acordes al flujo de la app.

### Seguridad de credenciales (CRÍTICO)
- **NUNCA** subir la URL real ni la clave (`anonKey` / `publishableKey`) de Supabase al repositorio de GitHub.
- Configurar la inicialización en `lib/config/supabase_config.dart` leyendo variables en tiempo de compilación con `--dart-define`:
  ```bash
  flutter run --dart-define=SUPABASE_URL=https://tu-proyecto.supabase.co --dart-define=SUPABASE_KEY=tu-clave-publica
  ```
- Si el equipo opta por archivo `.env`, debe añadirse `.env` a `.gitignore` y versionar únicamente `.env.example` sin valores reales.
- **Nota técnica sobre `Supabase.initialize`:** El documento del taller muestra `publishableKey:` en `Supabase.initialize(...)`. Al instalar `supabase_flutter`, verificar si la versión instalada usa el parámetro `anonKey:` o `publishableKey:` y unificarlo en `lib/config/supabase_config.dart`.

---

## 6. Arquitectura MVC (Modelo - Vista - Controlador)

El proyecto sigue estrictamente el patrón **MVC (Model-View-Controller)** apoyado por una capa de **Servicios** para aislar el acceso a hardware y red.

### Estructura de carpetas del repositorio

```text
sensortrack_flutter/
├── CLAUDE.md                       # Estándares y guía oficial del proyecto
├── pubspec.yaml                    # Dependencias y metadatos del paquete
├── analysis_options.yaml           # Reglas de lint (flutter_lints)
├── Taller_SensorTrack_Flutter_Sensores_Supabase.docx
├── sql/                            # Scripts SQL de Supabase (Entregable #5)
│   └── create_sensor_readings.sql  # Creación de sensor_readings y políticas RLS
├── docs/                           # Informe técnico y evidencias (Entregables #2, #3, #4, #6)
├── lib/
│   ├── main.dart                   # Punto de entrada: inicializa Supabase, tema y rutas
│   ├── config/                     # Configuración global (constantes, rutas, tema, Supabase)
│   │   ├── app_routes.dart
│   │   ├── app_theme.dart
│   │   └── supabase_config.dart
│   ├── models/                     # [M] MODELO: entidades de dominio y serialización
│   │   ├── sensor_type.dart        # Enum SensorType y utilidades de mapeo BD/UI
│   │   ├── sensor_reading.dart     # Clase SensorReading (fromJson / toJson / copyWith)
│   │   └── sensor_stats.dart       # Modelo agregado para métricas de Estadísticas
│   ├── services/                   # Capa de infraestructura (hardware y backend)
│   │   ├── sensor_service.dart     # Encapsula streams de sensors_plus
│   │   ├── location_service.dart   # Encapsula permisos y lecturas de geolocator
│   │   └── supabase_service.dart   # CRUD y consultas sobre tabla sensor_readings
│   ├── controllers/                # [C] CONTROLADOR: estado de UI y lógica de casos de uso
│   │   ├── home_controller.dart
│   │   ├── sensor_controller.dart
│   │   ├── location_controller.dart
│   │   ├── history_controller.dart
│   │   └── stats_controller.dart
│   └── views/                      # [V] VISTA: pantallas y widgets reutilizables
│       ├── splash/                 # Pantalla Splash (SensorTrack)
│       ├── home/                   # Pantalla 1: Inicio
│       ├── sensors/                # Pantalla 2: Acelerómetro y Giroscopio
│       ├── location/               # Pantalla 3: Ubicación GPS
│       ├── history/                # Pantalla 4: Historial y Detalle de medición
│       ├── stats/                  # Pantalla 5: Estadísticas y gráficos (fl_chart)
│       └── widgets/                # Widgets compartidos (tarjetas, estados de carga/error)
└── test/
    ├── widget_test.dart
    ├── models/                     # Pruebas unitarias de serialización y modelos
    ├── controllers/                # Pruebas unitarias de controladores (con mocks)
    └── views/                      # Pruebas de widgets/pantallas
```

### Reglas estrictas por capa

1. **Modelo (`lib/models/`)**
   - **SÍ pertenece:** Clases inmutables de datos (`SensorReading`, `SensorStats`), enumeraciones (`SensorType`), métodos `fromJson`, `toJson`, `copyWith` y validaciones puras de dominio.
   - **PROHIBIDO:** Importar `flutter/material.dart` (widgets), llamar a `Supabase.instance`, leer streams de hardware o manejar estado de UI.

2. **Servicios (`lib/services/`)**
   - **SÍ pertenece:** Comunicación directa con `supabase_flutter`, `sensors_plus` y `geolocator`. Transforma respuestas crudas en modelos (`SensorReading`) y traduce excepciones técnicas en errores comprensibles.
   - **PROHIBIDO:** `BuildContext`, `setState`, `ChangeNotifier` o navegación.

3. **Controladores (`lib/controllers/`)**
   - **SÍ pertenece:** Extienden `ChangeNotifier`. Administran el estado de cada pantalla (`isLoading`, `errorMessage`, listas de lecturas, estado de monitoreo activo), suscripciones `StreamSubscription`, control de frecuencia (throttling), invocación a `services/` y limpieza en `dispose()`.
   - **PROHIBIDO:** Construir widgets, usar `BuildContext` directamente para lógica de negocio o acceder directo a `Supabase.instance.client` saltándose `SupabaseService`.

4. **Vistas (`lib/views/`)**
   - **SÍ pertenece:** Widgets (`StatelessWidget` / `StatefulWidget` únicamente para ciclo de vida del controlador o animaciones locales), renderizado declarativo escuchando al controlador (`ListenableBuilder` / `AnimatedBuilder`), retroalimentación visual (`SnackBar`, diálogos de error/confirmación) y envío de acciones del usuario al controlador.
   - **PROHIBIDO:** Lógica de negocio, llamadas directas a `Supabase.instance.client`, suscripciones directas a `accelerometerEventStream()`, cálculos estadísticos o consultas SQL.

### Flujo de datos MVC
```text
Usuario interactúa con la Vista (lib/views/)
        │
        ▼
Vista invoca un método del Controlador (lib/controllers/)
        │
        ▼
Controlador coordina Servicios (lib/services/) y Modelos (lib/models/)
        │
        ▼
Controlador actualiza su estado y llama a notifyListeners()
        │
        ▼
Vista se reconstruye automáticamente reflejando el nuevo estado
```

### Adaptación de los ejemplos del taller a MVC
En las secciones 8 y 9 de `Taller_SensorTrack_Flutter_Sensores_Supabase.docx` se muestran ejemplos didácticos donde `accelerometerEventStream()` y `Supabase.instance.client.from('sensor_readings').insert(...)` viven dentro de un widget o función suelta. **En este proyecto NO deben copiarse tal cual en las vistas:**
- El stream de `accelerometerEventStream()` y `gyroscopeEventStream()` debe exponerse desde `SensorService` y suscribirse/cancelarse dentro de `SensorController`.
- La función `guardarMedicion(...)` debe implementarse como método tipado en `SupabaseService` (recibiendo un `SensorReading`), invocado desde `SensorController` / `LocationController` con manejo completo de excepciones.

---

## 7. Estándares de Código y Documentación Obligatoria

Un requerimiento explícito del equipo y del Entregable #1 es que **el código esté exhaustivamente documentado, claro y explicado**. Todo Pull Request será rechazado si carece de documentación adecuada.

### Reglas de documentación en Dart
1. **Comentarios Dartdoc (`///`) obligatorios** en:
   - Todas las clases públicas, `enum`s y extensiones.
   - Todos los constructores y campos públicos relevantes.
   - Todos los métodos y funciones públicas (incluyendo descripción clara de qué hace, parámetros con `[nombreParametro]`, qué retorna y qué excepciones puede lanzar).
2. **Comentarios en línea (`//`) obligatorios** para explicar **el porqué** de decisiones técnicas no triviales:
   - Control de frecuencia / throttling de sensores.
   - Cancelación de `StreamSubscription` en `dispose()`.
   - Verificación y flujo de permisos de ubicación.
   - Cálculos estadísticos (máximos, mínimos, agrupación por sensor, series para `fl_chart`).
   - Manejo de errores específicos de Supabase/red.
3. Idioma de la documentación y comentarios: **Español** (claro, técnico y sin ambigüedades).

### Ejemplo estándar de documentación del proyecto
```dart
/// Representa una medición capturada por un sensor físico del dispositivo
/// y almacenada en la tabla `sensor_readings` de Supabase.
class SensorReading {
  /// Identificador único del registro generado por PostgreSQL (UUID).
  final String? id;

  /// Tipo de sensor que originó la medición.
  final SensorType sensorType;

  /// Valor del eje X (aceleración o velocidad angular), si aplica.
  final double? x;

  // ... resto de propiedades documentadas ...

  /// Crea una instancia inmutable de [SensorReading].
  const SensorReading({
    this.id,
    required this.sensorType,
    this.x,
  });

  /// Convierte la medición al formato JSON esperado por la tabla
  /// `sensor_readings` de Supabase.
  ///
  /// Omite `id` y `recordedAt` cuando son nulos para que PostgreSQL
  /// asigne los valores por defecto (`gen_random_uuid()` y `NOW()`).
  Map<String, dynamic> toJson() {
    // Se omiten campos nulos generados por el servidor para evitar
    // sobreescribir los defaults definidos en la base de datos.
    return {
      'sensor_type': sensorType.dbValue,
      if (x != null) 'x': x,
    };
  }
}
```

### Convenciones de estilo y calidad
- **Nombres de archivos:** `snake_case.dart` (ej. `sensor_reading.dart`, `sensor_controller.dart`).
- **Clases y enums:** `PascalCase` (ej. `SensorReading`, `SensorType`).
- **Variables, parámetros, métodos y constantes:** `camelCase` (ej. `isMonitoring`, `saveReading()`).
- **Linter y análisis estático:** Cumplir todas las reglas de `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`). El comando `flutter analyze` debe terminar con **0 errores y 0 advertencias**.
- **Formateo:** Ejecutar `dart format .` antes de cada commit.
- **Logs:** No usar `print()` en código de producción; utilizar `debugPrint()` únicamente para trazas de depuración controladas.
- **Inmutabilidad:** Preferir `const` en constructores y widgets siempre que sea posible.

---

## 8. Consideraciones Técnicas Obligatorias

Derivadas directamente de la Sección 11 del taller, de cumplimiento obligatorio en toda implementación:

1. **Pruebas en dispositivo físico:** Acelerómetro, giroscopio y GPS deben validarse preferentemente en un teléfono físico real (los emuladores no reproducen movimiento ni rotación física fielmente).
2. **Ciclo de vida y memoria:** Toda `StreamSubscription` abierta en un controlador o vista debe almacenarse y cancelarse obligatoriamente en `dispose()`. En callbacks de widgets, validar `if (!mounted) return;`.
3. **Sensores no disponibles:** Capturar errores cuando el dispositivo no disponga de un sensor físico específico (ej. dispositivos sin giroscopio) y mostrar un estado informativo en la UI sin cerrar la app.
4. **Control de frecuencia de guardado (anti-spam a Supabase):**
   - **Prohibido** ejecutar `insert` en cada evento emitido por `accelerometerEventStream()` o `gyroscopeEventStream()` (emiten decenas de eventos por segundo).
   - Implementar botones claros para **Iniciar / Detener monitoreo**.
   - El guardado principal se realiza bajo demanda con el botón **"Guardar medición"** (y si se implementa guardado automático periódico, aplicar un intervalo mínimo configurable mediante `Timer` o throttling).
5. **Privacidad y permisos de ubicación:**
   - Verificar si el servicio de ubicación del dispositivo está habilitado (`Geolocator.isLocationServiceEnabled()`).
   - Gestionar todos los estados de permiso (`denied`, `deniedForever`, `whileInUse`, `always`) ofreciendo al usuario abrir configuración cuando corresponda.
   - **Nunca** capturar ni almacenar coordenadas GPS en Supabase sin conocimiento y autorización explícita del usuario.
6. **Resiliencia con Supabase:**
   - Envolver todas las operaciones remotas en bloques `try / catch` capturando `PostgrestException`, errores de socket/red y timeouts.
   - Mostrar mensajes de error comprensibles para el usuario y permitir reintentar la operación.
7. **Seguridad de datos (RLS):**
   - Documentar y habilitar políticas RLS en Supabase si la tabla queda expuesta públicamente, evitando permisos innecesarios (por ejemplo, no permitir `DELETE`/`UPDATE` anónimos si no se requieren).

---

## 9. Flujo de Trabajo en Equipo y Git

### Estrategia de ramas
- `main`: Rama estable y lista para demostración/entrega al docente. Prohibido hacer push directo con código sin probar.
- `develop`: Rama de integración continua del equipo.
- `feature/int<1|2|3>-<descripcion>`: Ramas de trabajo por integrante según los Specs de la Sección 10:
  - Fase 0 (Integrante 1): `feature/int1-core-base`
  - Fase 1 (paralelo):
    - Integrante 1: `feature/int1-home-splash`
    - Integrante 2: `feature/int2-sensors-location`
    - Integrante 3: `feature/int3-history-stats`
- `fix/<descripcion>`: Correcciones de errores puntuales.

### Convención de mensajes de commit
Usar prefijos claros (Conventional Commits):
- `feat:` nueva funcionalidad (ej. `feat: implementar monitoreo en tiempo real del acelerómetro`)
- `fix:` corrección de error (ej. `fix: cancelar stream de giroscopio en dispose`)
- `docs:` documentación o comentarios (ej. `docs: agregar script SQL y políticas RLS`)
- `refactor:` mejora interna sin cambiar comportamiento
- `test:` pruebas unitarias o de widgets
- `chore:` configuración, dependencias o mantenimiento

### Checklist obligatorio antes de hacer Pull Request
- [ ] El código respeta estrictamente la separación MVC (`models`, `services`, `controllers`, `views`).
- [ ] El agente/integrante **solo modificó archivos de su propiedad** (ver Matriz en Sección 10.D).
- [ ] Todas las clases y métodos públicos tienen comentarios Dartdoc (`///`) en español y comentarios en línea donde la lógica lo requiera.
- [ ] `dart format .` aplicado sin cambios pendientes.
- [ ] `flutter analyze` pasa con 0 errores y 0 advertencias.
- [ ] `flutter test` pasa correctamente.
- [ ] No hay credenciales, URLs privadas ni claves de Supabase hardcodeadas en el diff.
- [ ] Las `StreamSubscription` se cancelan correctamente en `dispose()`.

---

## 10. Specs por Integrante (Equipo de 3 personas + Agentes de IA)

Esta sección divide el desarrollo de **SensorTrack** en **3 Specs independientes** para que los 3 integrantes trabajen en paralelo con sus propios agentes de IA **sin sobreescribir ni romper el código de los demás**.

### A. Reglas de oro para agentes de IA (aislamiento estricto)

1. **Propiedad exclusiva de archivos:** Ningún agente puede crear, editar ni eliminar archivos fuera de la lista **Archivos con permiso de escritura (R/W)** asignada a su integrante.
2. **Contratos congelados (Solo lectura):** Los archivos base publicados en Fase 0 (`lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`, `lib/services/supabase_service.dart`, `lib/config/`, `lib/views/widgets/`) son de **solo lectura** para los Integrantes 2 y 3. Si hace falta un cambio en un contrato, se coordina primero con el Integrante 1 antes de editar.
3. **Widgets privados por pantalla:** La carpeta compartida `lib/views/widgets/` pertenece exclusivamente al Integrante 1. Los Integrantes 2 y 3 crean sus subwidgets privados dentro de sus propias carpetas (`lib/views/sensors/widgets/`, `lib/views/location/widgets/`, `lib/views/history/widgets/`, `lib/views/stats/widgets/`).
4. **Dependencias congeladas:** `pubspec.yaml` y `pubspec.lock` ya contienen los paquetes del taller y **no se modifican** durante el desarrollo paralelo.
5. **Una rama por integrante:** Cada integrante parte de `develop` después de fusionada la Fase 0.

### B. Flujo en 3 Fases

- **Fase 0 — Contratos y Esqueleto Base (Integrante 1 → PR a `develop`):**
  - El Integrante 1 implementa `sql/create_sensor_readings.sql`, `lib/config/*`, `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`, `lib/services/supabase_service.dart` y `lib/main.dart`.
  - Además, crea **4 archivos stub mínimos** (~10 líneas cada uno: solo el constructor `const <Page>({super.key})` y un `Scaffold` temporal) en:
    - `lib/views/sensors/sensors_page.dart`
    - `lib/views/location/location_page.dart`
    - `lib/views/history/history_page.dart`
    - `lib/views/stats/stats_page.dart`
  - El objetivo de estos stubs es que `lib/config/app_routes.dart` y `lib/main.dart` compilen desde el minuto uno. **Una vez fusionada la Fase 0 a `develop`, el Integrante 1 NUNCA vuelve a editar esos 4 archivos.**
- **Fase 1 — Desarrollo 100% paralelo (los 3 integrantes simultáneamente desde `develop`):**
  - **Integrante 1 (`feature/int1-home-splash`):** Completa `SplashPage`, `HomePage`, `HomeController`, `lib/views/widgets/` y los tests base.
  - **Integrante 2 (`feature/int2-sensors-location`):** Implementa `SensorService`, `LocationService`, `SensorController`, `LocationController`, permisos nativos Android/iOS, y reemplaza los stubs de `sensors_page.dart` y `location_page.dart`.
  - **Integrante 3 (`feature/int3-history-stats`):** Implementa `SensorStats`, `HistoryController`, `StatsController`, `ReadingDetailPage`, gráficos `fl_chart`, y reemplaza los stubs de `history_page.dart` y `stats_page.dart`.
- **Fase 2 — Integración y validación en dispositivo físico:**
  - Merge ordenado de las 3 ramas a `develop` (sin conflictos esperados al no compartir archivos R/W).
  - Pruebas integrales en teléfono físico real, recolección de capturas/evidencias e informe técnico en `docs/`, y merge final a `main`.

### C. Contratos Compartidos Exactos (firmas congeladas de Fase 0)

Todos los agentes de IA deben respetar estas firmas exactas para que los módulos compilen e integren sin fricción:

```dart
// 1. lib/models/sensor_type.dart
enum SensorType {
  accelerometer,
  gyroscope,
  gps,
  magnetometer,
  light;

  String get dbValue => switch (this) {
    SensorType.accelerometer => 'accelerometer',
    SensorType.gyroscope => 'gyroscope',
    SensorType.gps => 'gps',
    SensorType.magnetometer => 'magnetometer',
    SensorType.light => 'light',
  };

  String get displayName => ...;
  static SensorType fromDbValue(String value) => ...;
}

// 2. lib/models/sensor_reading.dart
class SensorReading {
  final String? id;
  final SensorType sensorType;
  final double? x;
  final double? y;
  final double? z;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? recordedAt;

  const SensorReading({
    this.id,
    required this.sensorType,
    this.x,
    this.y,
    this.z,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.recordedAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
  SensorReading copyWith({...}) => ...;
}

// 3. lib/services/supabase_service.dart
class SupabaseService {
  Future<bool> checkConnection();
  Future<void> insertReading(SensorReading reading);
  Future<List<SensorReading>> fetchReadings({
    SensorType? sensorType,
    int limit = 100,
  });
  Future<SensorReading?> fetchReadingById(String id);
}
```

- **Constructores de entrada registrados en `AppRoutes` (`lib/config/app_routes.dart`):**
  - `const SplashPage({super.key})` (`lib/views/splash/splash_page.dart`)
  - `const HomePage({super.key})` (`lib/views/home/home_page.dart`)
  - `const SensorsPage({super.key})` (`lib/views/sensors/sensors_page.dart`)
  - `const LocationPage({super.key})` (`lib/views/location/location_page.dart`)
  - `const HistoryPage({super.key})` (`lib/views/history/history_page.dart`)
  - `const StatsPage({super.key})` (`lib/views/stats/stats_page.dart`)
- **Desacoplamiento de `HomeController`:** Para mostrar los sensores disponibles en `HomePage` sin depender de `SensorService` ni `LocationService` (que pertenecen al Integrante 2), `HomeController` realiza su propia comprobación ligera de disponibilidad usando directamente `sensors_plus` / `geolocator` en modo de solo lectura.

### D. Matriz de Propiedad Exclusiva de Archivos

| Ruta / Archivo | Propietario exclusivo (R/W) | Acceso otros integrantes |
| --- | --- | --- |
| `sql/create_sensor_readings.sql` | **Integrante 1** | Solo lectura |
| `lib/main.dart`, `lib/config/**` | **Integrante 1** | Solo lectura (tras Fase 0) |
| `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart` | **Integrante 1** | Solo lectura (tras Fase 0) |
| `lib/services/supabase_service.dart` | **Integrante 1** | Solo lectura (tras Fase 0) |
| `lib/controllers/home_controller.dart` | **Integrante 1** | Sin acceso / No tocar |
| `lib/views/splash/**`, `lib/views/home/**`, `lib/views/widgets/**` | **Integrante 1** | `widgets/` solo lectura |
| `test/models/sensor_reading_test.dart`, `test/widget_test.dart` | **Integrante 1** | Sin acceso / No tocar |
| `lib/services/sensor_service.dart`, `lib/services/location_service.dart` | **Integrante 2** | Sin acceso / No tocar |
| `lib/controllers/sensor_controller.dart`, `lib/controllers/location_controller.dart` | **Integrante 2** | Sin acceso / No tocar |
| `lib/views/sensors/**` (tras stub Fase 0) | **Integrante 2** | Sin acceso / No tocar |
| `lib/views/location/**` (tras stub Fase 0) | **Integrante 2** | Sin acceso / No tocar |
| `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | **Integrante 2** | Sin acceso / No tocar |
| `test/controllers/sensor_controller_test.dart`, `test/controllers/location_controller_test.dart`, `test/views/sensors_*`, `test/views/location_*` | **Integrante 2** | Sin acceso / No tocar |
| `lib/models/sensor_stats.dart` | **Integrante 3** | Sin acceso / No tocar |
| `lib/controllers/history_controller.dart`, `lib/controllers/stats_controller.dart` | **Integrante 3** | Sin acceso / No tocar |
| `lib/views/history/**` (tras stub Fase 0) | **Integrante 3** | Sin acceso / No tocar |
| `lib/views/stats/**` (tras stub Fase 0) | **Integrante 3** | Sin acceso / No tocar |
| `test/models/sensor_stats_test.dart`, `test/controllers/history_controller_test.dart`, `test/controllers/stats_controller_test.dart`, `test/views/history_*`, `test/views/stats_*` | **Integrante 3** | Sin acceso / No tocar |
| `docs/**` (informe técnico y evidencias) | **Compartido en Fase 2** | Subir con nombres únicos por integrante |

---

### E. Specs detallados por integrante

#### Spec 1 — Integrante 1: Core, Base de Datos, Splash e Inicio (Módulo 1 + Base Módulo 3)
- **Ramas:** `feature/int1-core-base` (Fase 0) y `feature/int1-home-splash` (Fase 1).
- **Alcance funcional:**
  - Script SQL completo de `sensor_readings` y políticas RLS.
  - Configuración global (`SupabaseConfig` con `--dart-define`, `AppTheme` Material 3, `AppRoutes`).
  - Modelos base (`SensorType`, `SensorReading`) y servicio `SupabaseService` con manejo de excepciones (`PostgrestException`, red/timeout).
  - Pantalla Splash (`SensorTrack`) con verificación inicial de conexión.
  - Pantalla Inicio (`HomePage`) con menú de navegación a los 4 módulos, indicador de estado de conexión con Supabase y listado de sensores disponibles en el dispositivo.
  - Widgets compartidos básicos en `lib/views/widgets/` (tarjetas, estados de carga/error).
- **Archivos con permiso de escritura (R/W):**
  - `sql/create_sensor_readings.sql`
  - `lib/main.dart`, `lib/config/**`
  - `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`
  - `lib/services/supabase_service.dart`
  - `lib/controllers/home_controller.dart`
  - `lib/views/splash/**`, `lib/views/home/**`, `lib/views/widgets/**`
  - *(Solo en Fase 0)* stubs mínimos de `sensors_page.dart`, `location_page.dart`, `history_page.dart`, `stats_page.dart`
  - `test/models/sensor_reading_test.dart`, `test/widget_test.dart`
- **Archivos prohibidos (tras Fase 0):** Todo archivo bajo `lib/services/sensor_service.dart`, `location_service.dart`, `lib/controllers/sensor_*`, `location_*`, `history_*`, `stats_*`, `lib/models/sensor_stats.dart`, `lib/views/sensors/**`, `lib/views/location/**`, `lib/views/history/**`, `lib/views/stats/**`, `AndroidManifest.xml`, `Info.plist`.
- **Criterios de aceptación:**
  - La app arranca en `SplashPage`, muestra `SensorTrack` y navega a `HomePage`.
  - `HomePage` muestra estado real de Supabase y lista de sensores disponibles; todos los botones de navegación funcionan.
  - `SupabaseService` inserta y consulta `SensorReading` con pruebas unitarias sobre `fromJson`/`toJson`.
- **Prompt listo para copiar/pegar en el agente de IA del Integrante 1:**
  ```text
  Lee CLAUDE.md completo antes de escribir código. Eres el agente del INTEGRANTE 1 (Spec 1).
  Tu propiedad exclusiva está definida en la Sección 10.D y 10.E (Spec 1) de CLAUDE.md.
  NO modifiques pubspec.yaml ni archivos de los Integrantes 2 y 3 (salvo crear los 4 stubs mínimos en Fase 0 si aún no existen).
  Respeta estrictamente las firmas congeladas de la Sección 10.C, la arquitectura MVC (Sección 6) y la documentación obligatoria Dartdoc /// + comentarios // en español (Sección 7).
  Al terminar, ejecuta `dart format .`, `flutter analyze` y `flutter test`.
  ```

---

#### Spec 2 — Integrante 2: Sensores Físicos y Ubicación GPS (Módulo 2 + Guardado en Supabase)
- **Rama:** `feature/int2-sensors-location` (creada desde `develop` tras Fase 0).
- **Alcance funcional:**
  - **Sensores (`SensorsPage`):** Lectura en tiempo real de acelerómetro (`X, Y, Z`) y giroscopio (`X, Y, Z`) mediante `SensorService` (`sensors_plus`), controles para iniciar y detener monitoreo, control de errores si un sensor no está disponible, botón explícito **"Guardar medición"** (sin guardar en cada tick del stream) conectado a `SupabaseService.insertReading`.
  - **Ubicación (`LocationPage`):** Solicitud y gestión completa de permisos con `LocationService` (`geolocator`: servicio desactivado, denegado, denegado permanentemente), visualización de latitud, longitud, precisión (`accuracy`), fecha/hora y mapa o vista previa opcional; guardado en Supabase únicamente tras consentimiento explícito del usuario.
  - Configuración de permisos nativos en Android (`AndroidManifest.xml`) e iOS (`Info.plist`).
- **Archivos con permiso de escritura (R/W):**
  - `lib/services/sensor_service.dart`, `lib/services/location_service.dart`
  - `lib/controllers/sensor_controller.dart`, `lib/controllers/location_controller.dart`
  - `lib/views/sensors/**` (incluyendo `lib/views/sensors/widgets/**`)
  - `lib/views/location/**` (incluyendo `lib/views/location/widgets/**`)
  - `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
  - `test/controllers/sensor_controller_test.dart`, `test/controllers/location_controller_test.dart`, `test/views/sensors_page_test.dart`, `test/views/location_page_test.dart`
- **Archivos de solo lectura:** `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`, `lib/services/supabase_service.dart`, `lib/config/**`, `lib/views/widgets/**`.
- **Archivos prohibidos:** `pubspec.yaml`, `lib/main.dart`, `sql/**`, `lib/models/**`, `lib/controllers/home_controller.dart`, `history_controller.dart`, `stats_controller.dart`, `lib/views/splash/**`, `lib/views/home/**`, `lib/views/history/**`, `lib/views/stats/**`.
- **Criterios de aceptación:**
  - `SensorsPage` muestra valores X/Y/Z en tiempo real, permite iniciar/detener monitoreo, cancela `StreamSubscription` en `dispose()` y guarda lecturas con el botón **"Guardar medición"** manejando errores de red/Supabase.
  - `LocationPage` gestiona todos los estados de permiso GPS, muestra latitud, longitud, precisión y fecha/hora, y solo persiste en Supabase cuando el usuario lo autoriza explícitamente.
- **Prompt listo para copiar/pegar en el agente de IA del Integrante 2:**
  ```text
  Lee CLAUDE.md completo antes de escribir código. Eres el agente del INTEGRANTE 2 (Spec 2: Sensores y Ubicación GPS).
  Tu propiedad exclusiva está definida en la Sección 10.D y 10.E (Spec 2) de CLAUDE.md.
  Los archivos de contrato de Fase 0 (models/sensor_type.dart, models/sensor_reading.dart, services/supabase_service.dart, config/, views/widgets/) son de SOLO LECTURA.
  NO modifiques pubspec.yaml, main.dart ni ningún archivo perteneciente al Integrante 1 o Integrante 3. Crea tus subwidgets en lib/views/sensors/widgets/ y lib/views/location/widgets/.
  Respeta MVC (Sección 6), las reglas de streams/throttling/permisos (Sección 8) y documentación Dartdoc /// + comentarios // en español (Sección 7).
  Al terminar, ejecuta `dart format .`, `flutter analyze` y tus pruebas unitarias/widget.
  ```

---

#### Spec 3 — Integrante 3: Historial, Detalle, Estadísticas y Gráficos (Módulo 4 + Módulo 5)
- **Rama:** `feature/int3-history-stats` (creada desde `develop` tras Fase 0).
- **Alcance funcional:**
  - **Historial (`HistoryPage`):** Consulta de registros desde `SupabaseService.fetchReadings`, filtro opcional por `SensorType`, pull-to-refresh, listado mostrando tipo de sensor, valores (`X, Y, Z`), fecha/hora y ubicación cuando corresponda; al seleccionar un registro, navegar a `ReadingDetailPage` con todos sus detalles.
  - **Estadísticas (`StatsPage` + `SensorStats`):** Cálculo en `StatsController` / `SensorStats` de: cantidad total de registros, número de mediciones por sensor, valores máximos y mínimos del acelerómetro, última ubicación registrada y **gráfico de evolución de mediciones** usando `fl_chart`.
- **Archivos con permiso de escritura (R/W):**
  - `lib/models/sensor_stats.dart`
  - `lib/controllers/history_controller.dart`, `lib/controllers/stats_controller.dart`
  - `lib/views/history/**` (incluyendo `reading_detail_page.dart` y `lib/views/history/widgets/**`)
  - `lib/views/stats/**` (incluyendo `lib/views/stats/widgets/**`)
  - `test/models/sensor_stats_test.dart`, `test/controllers/history_controller_test.dart`, `test/controllers/stats_controller_test.dart`, `test/views/history_page_test.dart`, `test/views/stats_page_test.dart`
- **Archivos de solo lectura:** `lib/models/sensor_type.dart`, `lib/models/sensor_reading.dart`, `lib/services/supabase_service.dart`, `lib/config/**`, `lib/views/widgets/**`.
- **Archivos prohibidos:** `pubspec.yaml`, `lib/main.dart`, `sql/**`, `lib/services/**`, `lib/controllers/home_controller.dart`, `sensor_controller.dart`, `location_controller.dart`, `lib/views/splash/**`, `lib/views/home/**`, `lib/views/sensors/**`, `lib/views/location/**`, `AndroidManifest.xml`, `Info.plist`.
- **Criterios de aceptación:**
  - `HistoryPage` carga registros desde Supabase, maneja estados de carga/vacío/error con opción de reintento y abre el detalle completo del registro seleccionado.
  - `StatsPage` muestra las 4 métricas solicitadas (total, conteo por sensor, máx/mín del acelerómetro, última ubicación) y renderiza correctamente el gráfico de evolución en `fl_chart` (incluso con listas vacías o pocos puntos sin lanzar excepciones).
- **Prompt listo para copiar/pegar en el agente de IA del Integrante 3:**
  ```text
  Lee CLAUDE.md completo antes de escribir código. Eres el agente del INTEGRANTE 3 (Spec 3: Historial y Estadísticas).
  Tu propiedad exclusiva está definida en la Sección 10.D y 10.E (Spec 3) de CLAUDE.md.
  Los archivos de contrato de Fase 0 (models/sensor_type.dart, models/sensor_reading.dart, services/supabase_service.dart, config/, views/widgets/) son de SOLO LECTURA.
  NO modifiques pubspec.yaml, main.dart ni ningún archivo perteneciente al Integrante 1 o Integrante 2. Crea tus subwidgets en lib/views/history/widgets/ y lib/views/stats/widgets/.
  Respeta MVC (Sección 6) y documentación obligatoria Dartdoc /// + comentarios // en español (Sección 7).
  Al terminar, ejecuta `dart format .`, `flutter analyze` y tus pruebas unitarias/widget.
  ```

---

## 11. Checklist de Entregables del Taller (Sección 12)

Al finalizar el proyecto, verificar que se cuente con los 7 entregables exigidos por la asignatura:

- [ ] **1.** Código fuente completo del proyecto Flutter en GitHub **bien documentado**.
- [ ] **2.** Evidencias de la aplicación ejecutándose en un **dispositivo físico** (guardar/organizar en `docs/`).
- [ ] **3.** Evidencia de la captura de los sensores (acelerómetro, giroscopio, GPS).
- [ ] **4.** Evidencia de los registros almacenados en Supabase.
- [ ] **5.** Script SQL de creación de la tabla (`sql/create_sensor_readings.sql`).
- [ ] **6.** Informe técnico breve que explique la arquitectura MVC utilizada y el funcionamiento de la aplicación (`docs/`).
- [ ] **7.** Demostración práctica de la aplicación al docente.
