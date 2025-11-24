
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

DROP TRIGGER IF EXISTS trg_validar_materia_prima ON materia_prima;

CREATE TRIGGER trg_validar_materia_prima
BEFORE INSERT OR UPDATE ON materia_prima
FOR EACH ROW
EXECUTE FUNCTION trg_validar_materia_prima_fn();


CREATE OR REPLACE FUNCTION trg_validar_posicion_pieza_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mp        materia_prima;
    v_conflicto INTEGER;
BEGIN
    -- Si la pieza no está asignada a ninguna lámina, no validamos
    IF NEW.materia_prima_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT *
    INTO v_mp
    FROM materia_prima
    WHERE id = NEW.materia_prima_id;

    -- Validar distancia mínima a la orilla
    IF NEW.posicion_x_mm < v_mp.distancia_min_borde_mm
       OR NEW.posicion_y_mm < v_mp.distancia_min_borde_mm THEN
        RAISE EXCEPTION 'Pieza viola distancia mínima a la orilla';
    END IF;

    -- Validar distancia mínima simple entre piezas (en el eje X, de forma didáctica)
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

DROP TRIGGER IF EXISTS trg_validar_posicion_pieza ON piezas;

CREATE TRIGGER trg_validar_posicion_pieza
BEFORE INSERT OR UPDATE ON piezas
FOR EACH ROW
EXECUTE FUNCTION trg_validar_posicion_pieza_fn();


CREATE OR REPLACE FUNCTION trg_recalcular_utilizacion_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_mp_id INT;
BEGIN
    -- Según la operación, usamos NEW o OLD para obtener la pieza
    IF TG_OP = 'DELETE' THEN
        SELECT materia_prima_id
        INTO v_mp_id
        FROM piezas
        WHERE id = OLD.pieza_id;
    ELSE
        SELECT materia_prima_id
        INTO v_mp_id
        FROM piezas
        WHERE id = NEW.pieza_id;
    END IF;

    -- Si la pieza está asignada a una materia prima, recalculamos
    IF v_mp_id IS NOT NULL THEN
        PERFORM fn_calcular_utilizacion(v_mp_id);
    END IF;

    -- Devolver el registro correcto según la operación
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_recalcular_utilizacion ON geometrias;

CREATE TRIGGER trg_recalcular_utilizacion
AFTER INSERT OR UPDATE OR DELETE ON geometrias
FOR EACH ROW
EXECUTE FUNCTION trg_recalcular_utilizacion_fn();


CREATE OR REPLACE FUNCTION trg_procesar_evento_json_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Solo procesamos eventos de tipo "ajuste_pieza"
    IF NEW.tipo_evento = 'ajuste_pieza' THEN
        PERFORM fn_aplicar_configuracion_evento(NEW.payload);
        NEW.procesado := TRUE;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_procesar_evento_json ON eventos;

CREATE TRIGGER trg_procesar_evento_json
BEFORE INSERT ON eventos
FOR EACH ROW
EXECUTE FUNCTION trg_procesar_evento_json_fn();
