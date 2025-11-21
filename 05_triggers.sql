-- DESCRIPCION: Validaciones automáticas en inserción

CREATE OR REPLACE FUNCTION fn_trigger_validar_limites()
RETURNS TRIGGER AS $$
DECLARE
    v_ancho_max NUMERIC;
    v_alto_max NUMERIC;
BEGIN
    SELECT ancho, alto INTO v_ancho_max, v_alto_max
    FROM materia_prima
    WHERE id_materia = NEW.id_materia;

    IF (NEW.posicion_x < 0 OR NEW.posicion_x > v_ancho_max OR
        NEW.posicion_y < 0 OR NEW.posicion_y > v_alto_max) THEN
        RAISE EXCEPTION 'Coordenadas fuera de límites (Max: %x%)', v_ancho_max, v_alto_max;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_posicion ON cortes_optimizados;

CREATE TRIGGER trg_validar_posicion
BEFORE INSERT ON cortes_optimizados
FOR EACH ROW
EXECUTE FUNCTION fn_trigger_validar_limites();