CREATE OR REPLACE FUNCTION validar_distancias()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.distancia_entre_piezas < 0 OR NEW.distancia_borde < 0 THEN
        RAISE EXCEPTION 'Distancias inválidas';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_materia_prima
BEFORE INSERT OR UPDATE ON materia_prima
FOR EACH ROW EXECUTE FUNCTION validar_distancias();
