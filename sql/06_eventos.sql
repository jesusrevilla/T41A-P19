CREATE OR REPLACE FUNCTION fn_registrar_evento(_id_pieza INT,_event JSON)
RETURNS VOID AS $$
BEGIN
    INSERT INTO eventos(id_pieza,evento) VALUES (_id_pieza,_event);
END;
$$ LANGUAGE plpgsql;
