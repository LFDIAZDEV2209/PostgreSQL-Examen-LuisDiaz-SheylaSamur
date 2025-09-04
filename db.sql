CREATE TABLE IF NOT EXISTS clientes (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  correo TEXT NOT NULL UNIQUE,
  telefono TEXT,
  estado TEXT NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo','inactivo'))
);

CREATE TABLE IF NOT EXISTS proveedores (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  categoria TEXT NOT NULL,
  precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
  stock INTEGER NOT NULL CHECK (stock >= 0),
  proveedor_id INTEGER NOT NULL,
  FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
);

CREATE TABLE IF NOT EXISTS ventas (
  id SERIAL PRIMARY KEY,
  cliente_id INTEGER NOT NULL REFERENCES clientes(id),
  fecha TIMESTAMP NOT NULL DEFAULT NOW(),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

CREATE TABLE IF NOT EXISTS ventas_detalle (
  id SERIAL PRIMARY KEY,
  venta_id INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
  FOREIGN KEY (producto_id) REFERENCES productos(id),
  FOREIGN KEY (venta_id) REFERENCES ventas(id)
);

-- Tablas de apoyo
CREATE TABLE IF NOT EXISTS historial_precios (
  id BIGSERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  precio_anterior NUMERIC(12,2) NOT NULL,
  precio_nuevo NUMERIC(12,2) NOT NULL,
  cambiado_en TIMESTAMP NOT NULL DEFAULT NOW(),
  FOREIGN KEY (producto_id) REFERENCES productos(id)
);

CREATE TABLE IF NOT EXISTS auditoria_ventas (
  id BIGSERIAL PRIMARY KEY,
  venta_id INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  usuario TEXT NOT NULL,
  registrado_en TIMESTAMP NOT NULL DEFAULT NOW(),
  FOREIGN KEY (venta_id) REFERENCES ventas(id)
);

CREATE TABLE IF NOT EXISTS alertas_stock (
  id BIGSERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  nombre_producto TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  generado_en TIMESTAMP NOT NULL DEFAULT NOW(),
  FOREIGN KEY (producto_id) REFERENCES productos(id)
);