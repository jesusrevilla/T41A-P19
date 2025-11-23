-- Validación de materia prima (parámetros válidos)
CREATE OR REPLACE FUNCTION trg_validar_materia_prima_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.ancho_mm <= 0 OR NEW.alto_mm <= 0 THEN
        RAISE EXCEPTION 'Dimensiones de materia prima deben ser > 0';
    END IF;

    IF NEW.distancia_min_piezas_mm < 0 OR NEW.distancia_min_borde_mm < 0 THEN
        RAISE EXCEPTION 'Las distancias mínimas no pueden ser negativas';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_materia_prima
BEFORE INSERT OR UPDATE ON materia_prima
FOR EACH ROW
EXECUTE FUNCTION trg_validar_materia_prima_fn();


-- Validar distancia mínima a la orilla y mínima entre piezas
CREATE OR REPLACE FUNCTION trg_validar_posicion_pieza_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mp        materia_prima;
    v_conflicto INTEGER;
BEGIN
    IF NEW.materia_prima_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT * INTO v_mp
    FROM materia_prima
    WHERE id = NEW.materia_prima_id;

    -- Orilla mínima
    IF NEW.posicion_x_mm < v_mp.distancia_min_borde_mm
       OR NEW.posicion_y_mm < v_mp.distancia_min_borde_mm THEN
        RAISE EXCEPTION 'Pieza viola distancia mínima a la orilla';
    END IF;

    -- Distancia mínima simple en eje X (ejemplo didáctico)
    SELECT COUNT(*)
    INTO v_conflicto
    FROM piezas p
    WHERE p.materia_prima_id = NEW.materia_prima_id
      AND p.id <> COALESCE(NEW.id, -1)
      AND abs(p.posicion_x_mm - NEW.posicion_x_mm) < v_mp.distancia_min_piezas_mm;

    IF v_conflicto > 0 THEN
        RAISE EXCEPTION 'Pieza viola distancia mínima entre piezas';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_validar_posicion_pieza
BEFORE INSERT OR UPDATE ON piezas
FOR EACH ROW
EXECUTE FUNCTION trg_validar_posicion_pieza_fn();


-- Recalcular aprovechamiento después de cambios
CREATE OR REPLACE FUNCTION trg_recalcular_utilizacion_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mp_id INT;
BEGIN
    v_mp_id := COALESCE(NEW.materia_prima_id, OLD.materia_prima_id);
    IF v_mp_id IS NOT NULL THEN
        PERFORM fn_calcular_utilizacion(v_mp_id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_recalcular_utilizacion
AFTER INSERT OR UPDATE OR DELETE ON geometrias
FOR EACH ROW
EXECUTE FUNCTION trg_recalcular_utilizacion_fn();


-- Procesar eventos JSON al insertarlos
CREATE OR REPLACE FUNCTION trg_procesar_evento_json_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.tipo_evento = 'ajuste_pieza' THEN
        PERFORM fn_aplicar_configuracion_evento(NEW.payload);
        NEW.procesado := TRUE;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_procesar_evento_json
BEFORE INSERT ON eventos
FOR EACH ROW
EXECUTE FUNCTION trg_procesar_evento_json_fn();
