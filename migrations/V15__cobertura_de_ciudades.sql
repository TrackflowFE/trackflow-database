-- El catálogo de ciudades (V4) y el de centros (V6) se cargaron por separado, y no
-- quedaron de acuerdo: de 57 ciudades solo 5 tenían centros. Un envío hacia cualquiera
-- de las otras 52 se registraba sin problema, pero nunca podía recibirse en un centro
-- de origen ni llegar a uno de destino: quedaba muerto desde el registro.
--
-- Desde esta versión el registro exige cobertura (al menos un centro activo en la
-- ciudad de origen y en la de destino), y esta migración deja el catálogo coherente con
-- esa regla:
--
--   1. Salen del catálogo las ciudades a las que solo se llega por aire o por río: San
--      Andrés, Leticia, Inírida, Mitú y Puerto Carreño. La red opera por carretera, y
--      ofrecerlas en el autocompletado prometería un servicio que no existe.
--   2. Cada ciudad restante recibe al menos un centro: un centro de distribución en las
--      capitales y ciudades intermedias, y un punto de recolección en los municipios de
--      las áreas metropolitanas.
--
-- V4 dice que su semilla son "las 32 capitales"; con el paso 1 ya no lo es. V4 no se
-- edita porque Flyway valida el checksum de las migraciones aplicadas.

-- 1. Ciudades sin acceso por carretera. La guarda evita romper una base que ya tenga
-- algo apuntando a ellas (un envío registrado antes de esta versión): en ese caso la
-- ciudad se queda, sin centro y por lo tanto sin cobertura, y el registro de envíos
-- nuevos la rechaza igual.
delete from cities c
where (c.name, c.department) in (
        ('SAN ANDRÉS', 'ARCHIPIÉLAGO DE SAN ANDRÉS'),
        ('LETICIA', 'AMAZONAS'),
        ('INÍRIDA', 'GUAINÍA'),
        ('MITÚ', 'VAUPÉS'),
        ('PUERTO CARREÑO', 'VICHADA'))
  and not exists (select 1 from shipments s where s.sender_city_id = c.id or s.recipient_city_id = c.id)
  and not exists (select 1 from reports_shipment_tracking t
                  where t.origin_city_id = c.id or t.destination_city_id = c.id)
  and not exists (select 1 from logistics_tracked_shipments t
                  where t.origin_city_id = c.id or t.destination_city_id = c.id)
  and not exists (select 1 from reports_shipment_volume v where v.origin_city_id = c.id)
  and not exists (select 1 from logistics_centers lc where lc.city_id = c.id);

-- 2. Un centro por ciudad. Se une con cities por nombre y departamento en vez de usar
-- subconsultas sueltas como V6: si una ciudad no existe, la fila simplemente no se
-- inserta, en lugar de fallar por un city_id nulo.
insert into logistics_centers (name, type, city_id, address, active)
select v.name, v.type, c.id, v.address, true
from (values
    -- Capitales y ciudades intermedias
    ('Centro Apartadó', 'CENTRO_DISTRIBUCION', 'APARTADÓ', 'ANTIOQUIA', 'Calle 100 #103-25, Apartadó'),
    ('Centro Rionegro', 'CENTRO_DISTRIBUCION', 'RIONEGRO', 'ANTIOQUIA', 'Autopista Medellín-Bogotá Km 37, Rionegro'),
    ('Centro Tunja', 'CENTRO_DISTRIBUCION', 'TUNJA', 'BOYACÁ', 'Av. Norte #45-60, Tunja'),
    ('Centro Duitama', 'CENTRO_DISTRIBUCION', 'DUITAMA', 'BOYACÁ', 'Cra 42 #22-10, Duitama'),
    ('Centro Sogamoso', 'CENTRO_DISTRIBUCION', 'SOGAMOSO', 'BOYACÁ', 'Calle 11 #18-35, Sogamoso'),
    ('Centro Manizales', 'CENTRO_DISTRIBUCION', 'MANIZALES', 'CALDAS', 'Av. Panamericana #45-20, Manizales'),
    ('Centro Florencia', 'CENTRO_DISTRIBUCION', 'FLORENCIA', 'CAQUETÁ', 'Calle 16 #10-45, Florencia'),
    ('Centro Popayán', 'CENTRO_DISTRIBUCION', 'POPAYÁN', 'CAUCA', 'Variante Norte #9-120, Popayán'),
    ('Centro Valledupar', 'CENTRO_DISTRIBUCION', 'VALLEDUPAR', 'CESAR', 'Calle 44 #25-80, Valledupar'),
    ('Centro Montería', 'CENTRO_DISTRIBUCION', 'MONTERÍA', 'CÓRDOBA', 'Cra 6 #62-30, Montería'),
    ('Centro Fusagasugá', 'CENTRO_DISTRIBUCION', 'FUSAGASUGÁ', 'CUNDINAMARCA', 'Av. Las Palmas #12-40, Fusagasugá'),
    ('Centro Girardot', 'CENTRO_DISTRIBUCION', 'GIRARDOT', 'CUNDINAMARCA', 'Cra 10 #33-15, Girardot'),
    ('Centro Quibdó', 'CENTRO_DISTRIBUCION', 'QUIBDÓ', 'CHOCÓ', 'Calle 31 #4-50, Quibdó'),
    ('Centro Neiva', 'CENTRO_DISTRIBUCION', 'NEIVA', 'HUILA', 'Cra 7 #26-70, Neiva'),
    ('Centro Riohacha', 'CENTRO_DISTRIBUCION', 'RIOHACHA', 'LA GUAJIRA', 'Calle 15 #18-40, Riohacha'),
    ('Centro Santa Marta', 'CENTRO_DISTRIBUCION', 'SANTA MARTA', 'MAGDALENA', 'Troncal del Caribe Km 2, Santa Marta'),
    ('Centro Villavicencio', 'CENTRO_DISTRIBUCION', 'VILLAVICENCIO', 'META', 'Anillo Vial #15-30, Villavicencio'),
    ('Centro Pasto', 'CENTRO_DISTRIBUCION', 'PASTO', 'NARIÑO', 'Calle 18 #32-15, Pasto'),
    ('Centro Cúcuta', 'CENTRO_DISTRIBUCION', 'CÚCUTA', 'NORTE DE SANTANDER', 'Av. Libertadores #10-50, Cúcuta'),
    ('Centro Armenia', 'CENTRO_DISTRIBUCION', 'ARMENIA', 'QUINDÍO', 'Av. Bolívar #20-45, Armenia'),
    ('Centro Pereira', 'CENTRO_DISTRIBUCION', 'PEREIRA', 'RISARALDA', 'Av. 30 de Agosto #87-90, Pereira'),
    ('Centro Bucaramanga', 'CENTRO_DISTRIBUCION', 'BUCARAMANGA', 'SANTANDER', 'Cra 15 #45-30, Bucaramanga'),
    ('Centro Barrancabermeja', 'CENTRO_DISTRIBUCION', 'BARRANCABERMEJA', 'SANTANDER', 'Calle 52 #20-15, Barrancabermeja'),
    ('Centro Sincelejo', 'CENTRO_DISTRIBUCION', 'SINCELEJO', 'SUCRE', 'Cra 25 #23-40, Sincelejo'),
    ('Centro Ibagué', 'CENTRO_DISTRIBUCION', 'IBAGUÉ', 'TOLIMA', 'Calle 60 #5-20, Ibagué'),
    ('Centro Buenaventura', 'CENTRO_DISTRIBUCION', 'BUENAVENTURA', 'VALLE DEL CAUCA', 'Av. Simón Bolívar Km 8, Buenaventura'),
    ('Centro Arauca', 'CENTRO_DISTRIBUCION', 'ARAUCA', 'ARAUCA', 'Calle 20 #24-30, Arauca'),
    ('Centro Yopal', 'CENTRO_DISTRIBUCION', 'YOPAL', 'CASANARE', 'Cra 20 #15-40, Yopal'),
    ('Centro Mocoa', 'CENTRO_DISTRIBUCION', 'MOCOA', 'PUTUMAYO', 'Calle 8 #7-25, Mocoa'),
    ('Centro San José del Guaviare', 'CENTRO_DISTRIBUCION', 'SAN JOSÉ DEL GUAVIARE', 'GUAVIARE',
        'Cra 22 #9-30, San José del Guaviare'),
    -- Municipios de las áreas metropolitanas
    ('Punto Bello', 'PUNTO_RECOLECCION', 'BELLO', 'ANTIOQUIA', 'Cra 50 #45-20, Bello'),
    ('Punto Envigado', 'PUNTO_RECOLECCION', 'ENVIGADO', 'ANTIOQUIA', 'Calle 38 Sur #43-15, Envigado'),
    ('Punto Itagüí', 'PUNTO_RECOLECCION', 'ITAGÜÍ', 'ANTIOQUIA', 'Cra 52 #51-40, Itagüí'),
    ('Punto Malambo', 'PUNTO_RECOLECCION', 'MALAMBO', 'ATLÁNTICO', 'Calle 11 #13-20, Malambo'),
    ('Punto Soledad', 'PUNTO_RECOLECCION', 'SOLEDAD', 'ATLÁNTICO', 'Calle 30 #19-45, Soledad'),
    ('Punto Cajicá', 'PUNTO_RECOLECCION', 'CAJICÁ', 'CUNDINAMARCA', 'Calle 2 #4-30, Cajicá'),
    ('Punto Chía', 'PUNTO_RECOLECCION', 'CHÍA', 'CUNDINAMARCA', 'Av. Pradilla #9-60, Chía'),
    ('Punto Funza', 'PUNTO_RECOLECCION', 'FUNZA', 'CUNDINAMARCA', 'Calle 15 #12-25, Funza'),
    ('Punto Mosquera', 'PUNTO_RECOLECCION', 'MOSQUERA', 'CUNDINAMARCA', 'Cra 3 #2-40, Mosquera'),
    ('Punto Soacha', 'PUNTO_RECOLECCION', 'SOACHA', 'CUNDINAMARCA', 'Autopista Sur #32-10, Soacha'),
    ('Punto Zipaquirá', 'PUNTO_RECOLECCION', 'ZIPAQUIRÁ', 'CUNDINAMARCA', 'Calle 8 #10-15, Zipaquirá'),
    ('Punto Dosquebradas', 'PUNTO_RECOLECCION', 'DOSQUEBRADAS', 'RISARALDA', 'Av. Simón Bolívar #36-50, Dosquebradas'),
    ('Punto Floridablanca', 'PUNTO_RECOLECCION', 'FLORIDABLANCA', 'SANTANDER', 'Cra 8 #4-30, Floridablanca'),
    ('Punto Girón', 'PUNTO_RECOLECCION', 'GIRÓN', 'SANTANDER', 'Calle 30 #25-15, Girón'),
    ('Punto Piedecuesta', 'PUNTO_RECOLECCION', 'PIEDECUESTA', 'SANTANDER', 'Cra 6 #9-40, Piedecuesta'),
    ('Punto Palmira', 'PUNTO_RECOLECCION', 'PALMIRA', 'VALLE DEL CAUCA', 'Calle 30 #28-20, Palmira'),
    ('Punto Yumbo', 'PUNTO_RECOLECCION', 'YUMBO', 'VALLE DEL CAUCA', 'Cra 4 #6-35, Yumbo')
) as v(name, type, city, department, address)
    join cities c on c.name = v.city and c.department = v.department
where not exists (select 1 from logistics_centers lc where lc.city_id = c.id and lc.name = v.name);
