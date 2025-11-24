CREATE OR REPLACE PROCEDURE sp_alta_geometria(
    p_pieza_id INT,
    p_datos JSONB,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO geometrias(pieza_id, datos, metadata)
    VALUES(p_pieza_id, p_datos, p_metadata);

    RAISE NOTICE 'Geometría registrada para pieza %', p_pieza_id;
END $$;
