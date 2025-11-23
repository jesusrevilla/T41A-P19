INSERT INTO roles(nombre) VALUES ('admin'), ('operador');

CREATE OR REPLACE FUNCTION fn_crear_usuario(_username TEXT,_password TEXT,_rol TEXT)
RETURNS VOID AS $$
DECLARE r_id INT;
BEGIN
    SELECT id INTO r_id FROM roles WHERE nombre=_rol;
    INSERT INTO usuarios(username,password,id_rol)
    VALUES(_username,_password,r_id);
END;
$$ LANGUAGE plpgsql;
