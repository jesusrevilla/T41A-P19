-- -------------------------------------------------------------------------
-- 3. TRIGGERS
-- -------------------------------------------------------------------------

-- 3.1. Trigger Function: Actualizar el porcentaje de utilización
CREATE OR REPLACE FUNCTION trg_actualizar_utilizacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_opt_corte_id BIGINT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_opt_corte_id := OLD.opt_corte_id;
    ELSE
        v_opt_corte_id := NEW.opt_corte_id;
    END IF;

    UPDATE optimizacion_corte
    SET utilizacion_porcentaje = fn_calcular_utilizacion(v_opt_corte_id)
    WHERE opt_corte_id = v_opt_corte_id;

    RETURN NULL;
END;
$$;

CREATE TRIGGER tr_actualizar_utilizacion
AFTER INSERT OR UPDATE OR DELETE ON piezas_colocadas
FOR EACH ROW
EXECUTE FUNCTION trg_actualizar_utilizacion();


-- 3.2. Trigger Function: Validación de Colocación (Distancia Mínima a Orilla)
CREATE OR REPLACE FUNCTION trg_validar_colocacion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_distancia_min_orilla NUMERIC;
    v_largo_materia NUMERIC;
    v_ancho_materia NUMERIC;
    v_ancho_pieza NUMERIC := 100.0; -- Bounding box fijo de la pieza de prueba
    v_largo_pieza NUMERIC := 100.0; -- Bounding box fijo de la pieza de prueba
BEGIN
    SELECT mp.distancia_min_orilla, mp.dimension_largo, mp.dimension_ancho
    INTO v_distancia_min_orilla, v_largo_materia, v_ancho_materia
    FROM optimizacion_corte oc
    JOIN materia_prima mp ON oc.materia_prima_id = mp.materia_prima_id
    WHERE oc.opt_corte_id = NEW.opt_corte_id;

    -- VALIDACIÓN 1: Borde inferior/izquierdo
    IF NEW.posicion_x < v_distancia_min_orilla OR NEW.posicion_y < v_distancia_min_orilla THEN
        RAISE EXCEPTION 'Error de validación: La pieza está demasiado cerca del borde. Mínimo requerido: %', v_distancia_min_orilla;
    END IF;
    
    -- VALIDACIÓN 2: Borde superior/derecho
    IF (NEW.posicion_x + v_largo_pieza) > (v_largo_materia - v_distancia_min_orilla) OR
       (NEW.posicion_y + v_ancho_pieza) > (v_ancho_materia - v_distancia_min_orilla) THEN
        RAISE EXCEPTION 'Error de validación: La pieza excede el límite de la materia prima con el margen de orilla.';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_validar_colocacion_before
BEFORE INSERT OR UPDATE ON piezas_colocadas
FOR EACH ROW
EXECUTE FUNCTION trg_validar_colocacion();
