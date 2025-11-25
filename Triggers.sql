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
