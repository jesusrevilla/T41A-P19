-- 07_eventos_json.sql
-- Gestión de eventos JSON

SET search_path TO corte, public;

-- Evento genérico: aplica acción a partir de JSON
-- Ejemplo payload:
-- {
--   "tipo":"rotar_posicionar",
--   "pieza_id": 123,
--   "angulo_deg": 90,
--   "dx": 50,
--   "dy": 10
-- }
CREATE OR REPLACE FUNCTION fn_aplicar_evento_json(p_evento JSONB)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE t TEXT; pieza INT; ang DOUBLE PRECISION; dx NUMERIC; dy NUMERIC;
BEGIN
  t   := p_evento->>'tipo';
  IF t = 'rotar_posicionar' THEN
    pieza := (p_evento->>'pieza_id')::INT;
    ang   := COALESCE((p_evento->>'angulo_deg')::DOUBLE PRECISION, 0);
    dx    := COALESCE((p_evento->>'dx')::NUMERIC, 0);
    dy    := COALESCE((p_evento->>'dy')::NUMERIC, 0);
    PERFORM sp_rotar_posicionar_figuras(pieza, ang, dx, dy, p_evento);
  ELSE
    RAISE EXCEPTION 'Tipo de evento no soportado: %', t;
  END IF;
END $$;
