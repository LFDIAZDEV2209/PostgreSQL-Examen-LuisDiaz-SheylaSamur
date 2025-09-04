# **🏪 Gestión de Inventario para una Tienda de Tecnología**

## **📌 Contexto del Problema**

La tienda **TechZone** es un negocio dedicado a la venta de productos tecnológicos, desde laptops y teléfonos hasta accesorios y componentes electrónicos. Con el crecimiento del comercio digital y la alta demanda de dispositivos electrónicos, la empresa ha notado la necesidad de mejorar la gestión de su inventario y ventas. Hasta ahora, han llevado el control de productos y transacciones en hojas de cálculo, lo que ha generado problemas como:

🔹 **Errores en el control de stock:** No saben con certeza qué productos están por agotarse, lo que ha llevado a problemas de desabastecimiento o acumulación innecesaria de productos en bodega.

🔹 **Dificultades en el seguimiento de ventas:** No cuentan con un sistema eficiente para analizar qué productos se venden más, en qué períodos del año hay mayor demanda o quiénes son sus clientes más frecuentes.

🔹 **Gestión manual de proveedores:** Los pedidos a proveedores se han realizado sin un historial claro de compras y ventas, dificultando la negociación de mejores precios y la planificación del abastecimiento.

🔹 **Falta de automatización en el registro de compras:** Cada vez que un cliente realiza una compra, los empleados deben registrar manualmente los productos vendidos y actualizar el inventario, lo que consume tiempo y es propenso a errores.

Para solucionar estos problemas, **TechZone** ha decidido implementar una base de datos en **PostgreSQL** que le permita gestionar de manera eficiente su inventario, las ventas, los clientes y los proveedores.

## **📋 Especificaciones del Sistema**

La empresa necesita un sistema que registre **todos los productos** disponibles en la tienda, clasificándolos por categoría y manteniendo un seguimiento de la cantidad en stock. Cada producto tiene un proveedor asignado, por lo que también es fundamental llevar un registro de los proveedores y los productos que suministran.

Cuando un cliente realiza una compra, el sistema debe registrar la venta y actualizar automáticamente el inventario, asegurando que no se vendan productos que ya están agotados. Además, la tienda quiere identificar **qué productos se venden más, qué clientes compran con mayor frecuencia y cuánto se ha generado en ventas en un período determinado**.



El nuevo sistema deberá cumplir con las siguientes funcionalidades:

​	1️⃣ **Registro de Productos:** Cada producto debe incluir su nombre, categoría, precio, stock disponible y proveedor.

​	2️⃣ **Registro de Clientes:** Se debe almacenar la información de cada cliente, incluyendo nombre, correo electrónico y número de teléfono.

​	3️⃣ **Registro de Ventas:** Cada venta debe incluir qué productos fueron vendidos, en qué cantidad y a qué cliente.

​	4️⃣ **Registro de Proveedores:** La tienda obtiene productos de diferentes proveedores, por lo que es necesario almacenar información sobre cada 	uno.

​	5️⃣ **Consultas avanzadas:** Se requiere la capacidad de analizar datos clave como productos más vendidos, ingresos por proveedor y clientes más 	frecuentes.

​	6️⃣ **Procedimiento almacenado con transacciones:** Para asegurar que no se vendan productos sin stock, el sistema debe validar la disponibilidad 	de inventario antes de completar una venta.

## Tablas de orientación

```sql
CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  categoria TEXT NOT NULL,
  precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
  stock INTEGER NOT NULL CHECK (stock >= 0),
  proveedor_id INTEGER NOT NULL
);

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

CREATE TABLE IF NOT EXISTS ventas (
  id SERIAL PRIMARY KEY,
  cliente_id INTEGER NOT NULL REFERENCES clientes(id),
  fecha TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ventas_detalle (
  id SERIAL PRIMARY KEY,
  venta_id INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0)
);

-- Tablas de apoyo
CREATE TABLE IF NOT EXISTS historial_precios (
  id BIGSERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  precio_anterior NUMERIC(12,2) NOT NULL,
  precio_nuevo NUMERIC(12,2) NOT NULL,
  cambiado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS auditoria_ventas (
  id BIGSERIAL PRIMARY KEY,
  venta_id INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  usuario TEXT NOT NULL,
  registrado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alertas_stock (
  id BIGSERIAL PRIMARY KEY,
  producto_id INTEGER NOT NULL REFERENCES productos(id),
  nombre_producto TEXT NOT NULL,
  mensaje TEXT NOT NULL,
  generado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

```



## **📌 Entregables del Examen**

Los estudiantes deben entregar un repositorio en **GitHub,** con su hash del último commit, con los siguientes archivos:

### **📄 1. Modelo E-R (modelo_er.png o modelo_er.jpg)**

- Un diagrama **Entidad-Relación (E-R)** con entidades, relaciones y cardinalidades bien definidas.

- El modelo debe estar **normalizado hasta la 3FN** para evitar redundancias. 

  > Puede usar Herramientas como DrawSql.io, StarUml o puede realizar el DER en Papel y cargar la imagen

### 📄 **2. Estructura de la Base de Datos (db.sql)**

- Archivo SQL con la creación de todas las tablas.
- Uso de claves primarias y foráneas para asegurar integridad referencial.
- Aplicación de restricciones (NOT NULL, CHECK, UNIQUE).

### 📄 **3. Inserción de Datos (insert.sql)**

- Cada entidad debe contener al menos 15 registros.
- Datos representativos y realistas.

### 📄 **4. Consultas SQL (queries.sql)**

Incluir 6 consultas avanzadas:

1️⃣ Listar los productos con stock menor a 5 unidades.

2️⃣ Calcular ventas totales de un mes específico.

3️⃣ Obtener el cliente con más compras realizadas.

4️⃣ Listar los 5 productos más vendidos.

5️⃣ Consultar ventas realizadas en un rango de fechas de tres Días y un Mes.

6️⃣ Identificar clientes que no han comprado en los últimos 6 meses.

# 📄 Procedimientos y Funciones (ProcedureAndFunctions.sql)**

- Un procedimiento almacenado para registrar una venta.
- Validar que el cliente exista.
- Verificar que el stock sea suficiente antes de procesar la venta.
- Si no hay stock suficiente, Notificar por medio de un mensaje en consola usando RAISE.
- Si hay stock, se realiza el registro de la venta.

# 📌 Enunciados de Triggers

Actualización automática del stock en ventas

> Cada vez que se inserte un registro en la tabla `ventas_detalle`, el sistema debe **descontar automáticamente** la cantidad de productos vendidos del campo `stock` de la tabla `productos`.

- Si el stock es insuficiente, el trigger debe evitar la operación y lanzar un error con `RAISE EXCEPTION`.

------

Registro de auditoría de ventas

> Al insertar una nueva venta en la tabla `ventas`, se debe generar automáticamente un registro en la tabla `auditoria_ventas` indicando:

- ID de la venta
- Fecha y hora del registro
- Usuario que realizó la transacción (usando `current_user`)

------

Notificación de productos agotados

> Cuando el stock de un producto llegue a **0** después de una actualización, se debe registrar en la tabla `alertas_stock` un mensaje indicando:

- ID del producto
- Nombre del producto
- Fecha en la que se agotó

------

Validación de datos en clientes

> Antes de insertar un nuevo cliente en la tabla `clientes`, se debe validar que el campo `correo` no esté vacío y que no exista ya en la base de datos (unicidad).

- Si la validación falla, se debe impedir la inserción y lanzar un mensaje de error.

------

Historial de cambios de precio

> Cada vez que se actualice el campo `precio` en la tabla `productos`, el trigger debe guardar el valor anterior y el nuevo en una tabla `historial_precios` con la fecha y hora de la modificación.

------

Bloqueo de eliminación de proveedores con productos activos

> Antes de eliminar un proveedor en la tabla `proveedores`, se debe verificar si existen productos asociados a dicho proveedor.

- Si existen productos, se debe bloquear la eliminación y notificar con un error.

------

Control de fechas en ventas

> Antes de insertar un registro en la tabla `ventas`, el trigger debe validar que la fecha de la venta no sea mayor a la fecha actual (`NOW()`).

- Si se detecta una fecha futura, la inserción debe ser cancelada.

------

Registro de clientes inactivos

> Si un cliente no ha realizado compras en los últimos 6 meses y se intenta registrar una nueva venta a su nombre, el trigger debe actualizar su estado en la tabla `clientes` a **"activo"**.

### 📄 Documentación (README.md)**

El README.md debe incluir:

- Descripción del proyecto explicando su propósito y funcionalidad.
- Imagen del modelo E-R (modelo_er.png).
- Instrucciones detalladas para importar y ejecutar los archivos SQL en PostgreSQL.
- Descripción de cada script (db.sql, insert.sql, queries.sql, procedure.sql).
- Ejemplo de cómo ejecutar las consultas y el procedimiento almacenado en PostgreSQL.

## **📂 Estructura del Repositorio**

📌 modelo_er.png → Imagen del modelo Entidad-Relación.

📌 db.sql → Script de creación de la base de datos y tablas.

📌 insert.sql → Script para insertar datos de prueba en la base de datos.

📌 queries.sql → Conjunto de consultas avanzadas para análisis de datos.

📌 procedureAndFunctions.sql → Procedimiento almacenado para gestionar ventas con transacciones.

📌 README.md → Documentación del proyecto y guía de uso.