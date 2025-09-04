-- Clientes
INSERT INTO clientes (nombre, correo, telefono, estado) VALUES
('Ana Gómez', 'ana.gomez@example.com', '3001112233', 'activo'),
('Carlos Pérez', 'carlos.perez@example.com', '3002223344', 'activo'),
('Mariana Torres', 'mariana.torres@example.com', '3003334455', 'inactivo');

-- Proveedores
INSERT INTO proveedores (nombre) VALUES
('Proveedor A'),
('Proveedor B'),
('Proveedor C');

-- Productos (ligados a proveedores)
INSERT INTO productos (nombre, categoria, precio, stock, proveedor_id) VALUES
('Laptop HP', 'Tecnología', 2500000, 10, 1),
('Mouse Logitech', 'Accesorios', 80000, 50, 1),
('Silla Gamer', 'Muebles', 700000, 15, 2),
('Camiseta Nike', 'Ropa', 120000, 40, 3);

-- Ventas (ligadas a clientes)
INSERT INTO ventas (cliente_id, fecha) VALUES
(1, '2025-09-01 10:30:00'),
(2, '2025-09-02 15:00:00');

-- Detalles de las ventas (ligados a productos y ventas)
INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 1, 2500000),   -- Laptop
(1, 2, 2, 80000),     -- 2 Mouse
(2, 4, 3, 120000);    -- 3 Camisetas

-- Historial de precios
INSERT INTO historial_precios (producto_id, precio_anterior, precio_nuevo, cambiado_en) VALUES
(1, 2400000, 2500000, '2025-08-20 12:00:00'),
(2, 75000, 80000, '2025-08-22 09:30:00');

-- Auditoría de ventas
INSERT INTO auditoria_ventas (venta_id, usuario, registrado_en) VALUES
(1, 'admin', '2025-09-01 10:35:00'),
(2, 'vendedor1', '2025-09-02 15:05:00');

-- Alertas de stock (ejemplo cuando queda bajo)
INSERT INTO alertas_stock (producto_id, nombre_producto, mensaje, generado_en) VALUES
(3, 'Silla Gamer', 'Stock bajo: quedan 3 unidades', '2025-09-03 11:00:00'),
(2, 'Mouse Logitech', 'Stock bajo: quedan 5 unidades', '2025-09-03 11:30:00');