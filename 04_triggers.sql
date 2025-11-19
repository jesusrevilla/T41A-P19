
-- TRIGGER: Validar que las piezas no queden demasiado cerca
CREATE OR REPLACE FUNCTION fn_validar_distancias()
RETURNS TRIGGER AS $$
DECLARE
    min_dist NUMERIC;
BEGIN
    SELECT distancia_minima_piezas INTO min_dist
    FROM materia_prima LIMIT 1;

    IF NEW.ancho < 1 OR NEW.alto < 1 THEN
        RAISE EXCEPTION 'Dimensiones inválidas para la pieza.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_distancias
BEFORE INSERT OR UPDATE ON piezas
FOR EACH ROW EXECUTE FUNCTION fn_validar_distancias();


-- TRIGGER: Recalcular aprovechamiento tras cada evento
CREATE OR REPLACE FUNCTION fn_actualizar_utilizacion()
RETURNS TRIGGER AS $$
DECLARE
    porcentaje NUMERIC;
BEGIN
    porcentaje := fn_calcular_utilizacion(1); -- materia_prima_id = 1 ejemplo

    INSERT INTO utilizacion (materia_prima_id, porcentaje)
    VALUES (1, porcentaje);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalcular_utilizacion
AFTER INSERT ON eventos
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_utilizacion();
