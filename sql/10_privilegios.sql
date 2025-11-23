GRANT SELECT, INSERT, UPDATE ON usuarios TO admin;
GRANT SELECT ON usuarios TO operador;

GRANT SELECT,INSERT,UPDATE ON productos,materia_prima,piezas,geometrias TO admin;
GRANT SELECT ON productos,materia_prima,piezas,geometrias TO operador;
