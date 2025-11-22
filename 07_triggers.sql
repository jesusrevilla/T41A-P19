-- 1. Trigger para procesar eventos JSON automáticamente
CREATE OR REPLACE FUNCTION tr_procesar_evento_json()
RETURNS TRIGGER AS $$
DECLARE
    v_pieza_id INT;
BEGIN
    -- Si el evento es de tipo 'ajuste_pieza'
    IF NEW.tipo_evento = 'ajuste_pieza' THEN
        v_pieza_id := (NEW.payload->>'pieza_id')::INT;
        
        CALL sp_rotar_posicionar_figuras(v_pieza_id, NEW.payload);
        -- Marcar como procesado
        NEW.procesado := TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_evento_json
BEFORE INSERT ON eventos
FOR EACH ROW
EXECUTE FUNCTION tr_procesar_evento_json();

-- 2. Trigger de validación básica 
-- Simulamos una validación simple: si la posición X es menor que la distancia a la orilla, error.
CREATE OR REPLACE FUNCTION tr_validar_posicion()
RETURNS TRIGGER AS $$
DECLARE
    v_dist_orilla NUMERIC;
BEGIN
    IF NEW.materia_prima_id IS NOT NULL THEN
        SELECT distancia_min_orilla INTO v_dist_orilla
        FROM materia_prima WHERE id = NEW.materia_prima_id;

        IF NEW.posicion_x < v_dist_orilla OR NEW.posicion_y < v_dist_orilla THEN
            RAISE EXCEPTION 'La pieza viola la distancia mínima a la orilla';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_posicion
BEFORE UPDATE OR INSERT ON piezas
FOR EACH ROW
EXECUTE FUNCTION tr_validar_posicion();
