CREATE OR REPLACE FUNCTION tr_validar_colocacion()
RETURNS TRIGGER
AS $$
BEGIN
    -- Llamar a la función de validación
    IF NOT fn_validar_colocacion_nativo(
        CASE WHEN TG_OP = 'UPDATE' THEN OLD.id ELSE NULL END, 
        NEW.geometria,                                       
        NEW.id_materia_prima                                 
    ) THEN
        RAISE EXCEPTION 'La colocación de la geometría (ID %) es inválida. No cumple con límites, solapamiento o distancia mínima.', NEW.id
        USING HINT = 'Revise los parámetros de la Materia Prima y la posición/forma de la pieza.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_validar_geometria_colocacion
BEFORE INSERT OR UPDATE ON geometrias
FOR EACH ROW
EXECUTE FUNCTION tr_validar_colocacion();

CREATE OR REPLACE FUNCTION tr_registrar_ajuste_geometria()
RETURNS TRIGGER
AS $$
DECLARE
    v_id_usuario INT := current_setting('id_usuario', TRUE)::INT;
    v_es_valido BOOLEAN := NEW.es_valido; 
BEGIN

    INSERT INTO evento (id_materiap, id_usuario, fecha_hora, tipo_evento, descripcion)
    VALUES (
        NEW.id_materia_prima, -- p_id_materia_prima
        v_id_usuario,         -- p_id_usuario (asumido de una variable de sesión o similar)
        NOW(),
        CASE TG_OP
            WHEN 'INSERT' THEN 'Creación Geometría'
            WHEN 'UPDATE' THEN 'Ajuste Geométrico'
            ELSE 'Operación Geometría'
        END,
        jsonb_build_object(
            'id_geometria_base', NEW.id, 
            'validez', v_es_valido, 
            'angulo_deg', NEW.angulo_rot, 
            'pos_x', NEW.pos_x,
            'pos_y', NEW.pos_y,
            'operacion', TG_OP
        )
    );

    RETURN NEW; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER t_registrar_evento_geometria
AFTER INSERT OR UPDATE ON pieza
FOR EACH ROW
EXECUTE FUNCTION tr_registrar_ajuste_geometria();
