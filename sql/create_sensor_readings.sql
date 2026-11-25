-- ============================================================================
-- SensorTrack - Script de creación de tabla y políticas RLS en Supabase
-- ============================================================================
-- Este script crea la tabla `sensor_readings` requerida para almacenar las
-- mediciones del acelerómetro, giroscopio, ubicación GPS y sensores opcionales.
--
-- Instrucciones de uso:
-- 1. Abrir el proyecto en https://supabase.com/
-- 2. Ir a "SQL Editor" -> "New query"
-- 3. Pegar y ejecutar este script completo.
-- ============================================================================

-- Creación idempotente de la tabla principal de lecturas de sensores
CREATE TABLE IF NOT EXISTS sensor_readings (
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

-- Índices recomendados para acelerar consultas de Historial y Estadísticas
-- (ordenamiento cronológico descendente y filtrado por tipo de sensor)
CREATE INDEX IF NOT EXISTS idx_sensor_readings_recorded_at
    ON sensor_readings (recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_sensor_type
    ON sensor_readings (sensor_type);

-- ============================================================================
-- Políticas de Seguridad a Nivel de Fila (Row Level Security - RLS)
-- ============================================================================
-- Se habilita RLS para proteger la tabla frente a operaciones no autorizadas.
-- De acuerdo con los requerimientos de SensorTrack, la aplicación cliente
-- únicamente necesita consultar registros (SELECT) e insertar nuevas
-- mediciones (INSERT). No se habilitan UPDATE ni DELETE públicos.
-- ============================================================================

ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas previas si se vuelve a ejecutar el script
DROP POLICY IF EXISTS "Permitir lectura publica de lecturas" ON sensor_readings;
DROP POLICY IF EXISTS "Permitir insercion publica de lecturas" ON sensor_readings;

-- Política de lectura (SELECT) para clientes anon y authenticated
CREATE POLICY "Permitir lectura publica de lecturas"
    ON sensor_readings
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Política de inserción (INSERT) validando que sensor_type no esté vacío
CREATE POLICY "Permitir insercion publica de lecturas"
    ON sensor_readings
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (char_length(trim(sensor_type)) > 0);
