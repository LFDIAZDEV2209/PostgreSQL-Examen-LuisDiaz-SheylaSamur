--Listar los productos con stock menor a 5 unidades.

SELECT * FROM productos WHERE stock < 5;

-- Calcular ventas totales de un mes específico.

SELECT SUM(vd.cantidad * vd.precio_unitario) AS ventas_totales
FROM ventas_detalle vd
JOIN ventas v ON v.id = vd.venta_id
WHERE v.fecha >= '2025-09-01' AND v.fecha < '2025-10-01';

-- Obtener el cliente con más compras realizadas.

SELECT c.nombre, COUNT(v.id) AS total_compras
FROM clientes c
JOIN ventas v ON v.cliente_id = c.id
JOIN ventas_detalle vd ON vd.venta_id = v.id
GROUP BY c.nombre
ORDER BY total_compras DESC
LIMIT 1;

-- Listar los 5 productos más vendidos.

SELECT p.nombre, SUM(vd.cantidad) AS total_vendido
FROM productos p
JOIN ventas_detalle vd ON vd.producto_id = p.id
GROUP BY p.nombre
ORDER BY total_vendido DESC
LIMIT 5;

-- Consultar ventas realizadas en un rango de fechas de tres Días y un Mes.

SELECT v.id, c.nombre AS cliente, v.fecha, COUNT(v.id) AS ventas_realizadas
FROM ventas v
JOIN clientes c ON c.id = v.cliente_id
JOIN ventas_detalle vd ON vd.venta_id = v.id
WHERE v.fecha >= '2025-08-01' AND v.fecha < '2025-09-04'
GROUP BY v.id, c.nombre, v.fecha
ORDER BY v.fecha;


-- Identificar clientes que no han comprado en los últimos 6 meses.

SELECT c.nombre
FROM clientes c
LEFT JOIN ventas v ON v.cliente_id = c.id AND v.fecha >= NOW() - INTERVAL '6 months'
WHERE v.id IS NULL;

