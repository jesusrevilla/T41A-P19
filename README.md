# Proyecto: Sistema de Optimización de Corte de Materia Prima en PostgreSQL

## Descripción del Proyecto
Este proyecto consiste en el diseño e implementación de una base de datos en **PostgreSQL** para optimizar el corte de materia prima laminar (madera, chapa metálica, tela, etc.). El sistema permitirá:

- **Gestión de usuarios y roles**:
  - CRUD para usuarios.
  - Roles: **Administrador** y **Operador**.
- **Registro de materia prima**:
  - Identificada por **número de parte**.
  - Parámetros: dimensiones, distancia mínima entre piezas, distancia mínima a la orilla.
- **Gestión de productos y piezas**:
  - Cada producto estará definido por:
    - **Número de parte**
    - **Descripción**
    - **Geometría**
    - **Cantidad de elementos por pieza**
  - Alta de piezas con sus componentes geométricos (segmentos rectos, arcos, figuras cerradas).
- **Eventos en JSON**:
  - Procesamiento de eventos que indiquen rotación, posición y ajustes de piezas para optimizar el aprovechamiento.
- **Procedimientos almacenados y funciones**:
  - **Procedimiento `sp_rotar_posicionar_figuras`**:
    - Recibe ID de pieza, ángulo de rotación, coordenadas de posición y evento JSON.
    - Actualiza geometrías y registra el evento.
  - **Función `fn_calcular_utilizacion`**:
    - Calcula el porcentaje de aprovechamiento de la materia prima considerando área total, piezas colocadas y restricciones.
- **Triggers**:
  - Validación automática de parámetros.
  - Recalcular aprovechamiento después de cada cambio.
- **Seguridad**:
  - Asignación de privilegios según rol.

---

## Rúbrica del Proyecto
| **Criterio**                                      | **Peso** |
|---------------------------------------------------|---------|
| Diseño del modelo relacional (tablas, relaciones, claves) | 10% |
| Pruebas unitarias | 10% |
| Implementación de CRUD para usuarios y roles      | 10% |
| Procedimientos almacenados para alta de materia prima y productos | 10% |
| Procedimiento para rotación y posicionamiento de figuras | 10% |
| Función para cálculo de utilización de materia prima | 10% |
| Triggers para validación y actualización automática | 10% |
| Gestión de eventos en formato JSON                | 10% |
| Seguridad y roles (Administrador/Operador)        | 10% |
| Documentación y secuencia de actividades          | 10% |

---

## Secuencia de Actividades
1. **Análisis y diseño**:
   - Definir entidades: Usuario, Rol, MateriaPrima, Producto, Pieza, Geometría, Configuración.
   - Crear diagrama ER.
2. **Configuración de PostgreSQL**:
   - Crear base de datos.
   - Definir roles: `admin`, `operador`.
3. **Creación de tablas**:
   - `usuarios`, `roles`, `materia_prima`, `productos`, `piezas`, `geometrias`, `eventos`.
4. **CRUD de usuarios y roles**:
   - Funciones para alta, baja, modificación y consulta.
5. **Procedimientos almacenados**:
   - Alta de materia prima (con número de parte).
   - Alta de productos (con número de parte, descripción, geometría, cantidad).
   - **Rotación y posicionamiento de figuras**.
6. **Funciones**:
   - **Cálculo de utilización de materia prima**.
7. **Triggers**:
   - Validar distancia mínima entre piezas.
   - Actualizar estado cuando se recibe un evento JSON.
8. **Gestión de eventos JSON**:
   - Función para parsear JSON y aplicar rotación/configuración.
9. **Seguridad**:
   - Asignación de privilegios según rol.
10. **Pruebas y optimización**:
    - Casos de prueba para cada módulo.
11. **Documentación final**:
    - Manual técnico y de usuario.
12. **Genera pruebas unitarias**:
    - Para los procedimientos almacenados
    - Las fucniones
    - Triggers
