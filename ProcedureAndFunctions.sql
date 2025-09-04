-- Un procedimiento almacenado para registrar una venta. POSTGRESQL

CREATE FUNCTION registrar_venta(p_cliente_id INTEGER, p_producto_id INTEGER, p_cantidad INTEGER)
RETURNS VOID AS $$
DECLARE
    v_venta_id INTEGER;
    v_precio_unitario NUMERIC(12,2);
BEGIN
    INSERT INTO ventas (cliente_id) VALUES (p_cliente_id) RETURNING id INTO v_venta_id;

    SELECT precio INTO v_precio_unitario FROM productos WHERE id = p_producto_id;

    INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario)
    VALUES (v_venta_id, p_producto_id, p_cantidad, v_precio_unitario);
END;
$$ LANGUAGE plpgsql;

-- Validar que el cliente exista.

CREATE FUNCTION validate_cliente(p_cliente_id INTEGER)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE id = p_cliente_id) THEN
        RAISE EXCEPTION 'Cliente con ID % no existe.', p_cliente_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Verificar que el stock sea suficiente antes de procesar la venta. POSTGESQL
-- Si no hay stock suficiente, Notificar por medio de un mensaje en consola usando RAISE.

CREATE FUNCTION verificar_stock(p_producto_id INTEGER, p_cantidad INTEGER)
RETURNS VOID AS $$
DECLARE
    v_stock INTEGER;
BEGIN
    SELECT stock INTO v_stock FROM productos WHERE id = p_producto_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Producto con ID % no existe.', p_producto_id;
    END IF;

    IF v_stock < p_cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto ID %: disponible %, requerido %.',
                        p_producto_id, v_stock, p_cantidad;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Si hay stock, se realiza el registro de la venta.

CREATE FUNCTION procesar_venta(p_cliente_id INTEGER, p_producto_id INTEGER, p_cantidad INTEGER)
RETURNS VOID AS $$
BEGIN
    PERFORM validate_cliente(p_cliente_id);
    PERFORM verificar_stock(p_producto_id, p_cantidad); 
    PERFORM registrar_venta(p_cliente_id, p_producto_id, p_cantidad);
    UPDATE productos SET stock = stock - p_cantidad WHERE id = p_producto_id;
END;
$$ LANGUAGE plpgsql;

-- Triggers

-- 1. Actualización automática del stock en ventas

-- > Cada vez que se inserte un registro en la tabla `ventas_detalle`, el sistema debe **descontar automáticamente** la cantidad de productos vendidos del campo `stock` de la tabla `productos`.

-- Si el stock es insuficiente, el trigger debe evitar la operación y lanzar un error con `RAISE EXCEPTION`.

CREATE OR REPLACE FUNCTION actualizar_stock()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.cantidad > (SELECT stock FROM productos WHERE id = NEW.producto_id)) THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto ID %: disponible %, requerido %.',
                        NEW.producto_id, (SELECT stock FROM productos WHERE id = NEW.producto_id), NEW.cantidad;
    END IF;
    UPDATE productos SET stock = stock - NEW.cantidad WHERE id = NEW.producto_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON ventas_detalle
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock();

-- Ya actualizamos el stock en la función procesar_venta jeje, pero igual ahi se lo dejamos jiji

--2. Registro de auditoría de ventas

-- > Al insertar una nueva venta en la tabla `ventas`, se debe generar automáticamente un registro en la tabla `auditoria_ventas` indicando:

-- ID de la venta
-- Fecha y hora del registro
-- Usuario que realizó la transacción (usando `current_user`)

CREATE OR REPLACE FUNCTION registrar_auditoria_venta()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria_ventas (venta_id, usuario)
    VALUES (NEW.id, current_user);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_auditoria_venta
AFTER INSERT ON ventas
FOR EACH ROW
EXECUTE FUNCTION registrar_auditoria_venta();

SELECT procesar_venta(2, 2, 2); 


--3. Notificación de productos agotados

-- > Cuando el stock de un producto llegue a **0** después de una actualización, se debe registrar en la tabla `alertas_stock` un mensaje indicando:

-- ID del producto
-- Nombre del producto
-- Fecha en la que se agotó

CREATE OR REPLACE FUNCTION notificar_producto_agotado()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stock = 0 THEN
        INSERT INTO alertas_stock (producto_id, nombre_producto, mensaje)
        VALUES (NEW.id, NEW.nombre, 'Producto agotado');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_notificar_producto_agotado
AFTER UPDATE OF stock ON productos
FOR EACH ROW
WHEN (NEW.stock = 0)
EXECUTE FUNCTION notificar_producto_agotado();


--4. Validación de datos en clientes

-- > Antes de insertar un nuevo cliente en la tabla `clientes`, se debe validar que el campo `correo` no esté vacío y que no exista ya en la base de datos (unicidad).

-- - Si la validación falla, se debe impedir la inserción y lanzar un mensaje de error.

CREATE OR REPLACE FUNCTION validar_cliente()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.correo IS NULL OR NEW.correo = '' THEN
        RAISE EXCEPTION 'El campo correo no puede estar vacío.';
    END IF;
    IF EXISTS (SELECT 1 FROM clientes WHERE correo = NEW.correo) THEN
        RAISE EXCEPTION 'El correo % ya existe en la base de datos.', NEW.correo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_cliente
BEFORE INSERT ON clientes
FOR EACH ROW
EXECUTE FUNCTION validar_cliente();

INSERT INTO clientes (nombre, correo, telefono) VALUES ('Test User', '', '3004445566'); 

--5. Historial de cambios de precio

-- > Cada vez que se actualice el campo `precio` en la tabla `productos`, el trigger debe guardar el valor anterior y el nuevo en una tabla `historial_precios` con la fecha y hora de la modificación.

CREATE OR REPLACE FUNCTION registrar_historial_precio()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.precio <> OLD.precio THEN
        INSERT INTO historial_precios (producto_id, precio_anterior, precio_nuevo)
        VALUES (NEW.id, OLD.precio, NEW.precio);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historial_precio
AFTER UPDATE OF precio ON productos
FOR EACH ROW
EXECUTE FUNCTION registrar_historial_precio();

UPDATE productos SET precio = 2600000 WHERE id = 1;


--6. Bloqueo de eliminación de proveedores con productos activos

-- > Antes de eliminar un proveedor en la tabla `proveedores`, se debe verificar si existen productos asociados a dicho proveedor.

-- - Si existen productos, se debe bloquear la eliminación y notificar con un error.

CREATE OR REPLACE FUNCTION bloquear_eliminacion_proveedor()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM productos WHERE proveedor_id = OLD.id) THEN
        RAISE EXCEPTION 'No se puede eliminar el proveedor ID %: tiene productos asociados.', OLD.id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bloquear_eliminacion_proveedor
BEFORE DELETE ON proveedores
FOR EACH ROW
EXECUTE FUNCTION bloquear_eliminacion_proveedor();

DELETE FROM proveedores WHERE id = 1;

-- 7. Control de fechas en ventas

-- > Antes de insertar un registro en la tabla `ventas`, el trigger debe validar que la fecha de la venta no sea mayor a la fecha actual (`NOW()`).

-- - Si se detecta una fecha futura, la inserción debe ser cancelada.

CREATE OR REPLACE FUNCTION validar_fecha_venta()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha > NOW() THEN
        RAISE EXCEPTION 'La fecha de la venta no puede ser futura: %', NEW.fecha;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_fecha_venta
BEFORE INSERT ON ventas
FOR EACH ROW
EXECUTE FUNCTION validar_fecha_venta();

INSERT INTO ventas (cliente_id, fecha) VALUES (1, '2026-01-01 10:00:00');


--8. Registro de clientes inactivos

-- > Si un cliente no ha realizado compras en los últimos 6 meses y se intenta registrar una nueva venta a su nombre, el trigger debe actualizar su estado en la tabla `clientes` a **"activo"**.

CREATE OR REPLACE FUNCTION actualizar_estado_cliente()
RETURNS TRIGGER AS $$
DECLARE
    v_ultima_venta TIMESTAMP;
BEGIN
    SELECT MAX(fecha) INTO v_ultima_venta FROM ventas WHERE cliente_id = NEW.cliente_id;
    IF v_ultima_venta IS NULL OR v_ultima_venta < NOW() - INTERVAL '6 months' THEN
        UPDATE clientes SET estado = 'activo' WHERE id = NEW.cliente_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_estado_cliente
BEFORE INSERT ON ventas
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_cliente();

-- Pruebas
UPDATE clientes SET estado = 'inactivo' WHERE id = 3;
SELECT registrar_venta(3, 3, 1);

