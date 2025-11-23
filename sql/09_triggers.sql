CREATE OR REPLACE FUNCTION fn_validar_distancias()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.distancia_entre_piezas < 0 THEN
        RAISE EXCEPTION 'Distancia inválida';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validar_mp
BEFORE INSERT ON materia_prima
FOR EACH ROW EXECUTE FUNCTION fn_validar_distancias();
