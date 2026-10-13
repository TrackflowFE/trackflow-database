-- El modelo de lectura de HU-03 solo guardaba el nombre del destinatario y la
-- ciudad de destino. El frontend necesita mostrar también quién envía y desde
-- dónde, así que se agregan las columnas equivalentes de origen: sender_name
-- (shipments ya lo tenía, pero nunca se copiaba a la proyección), origin_city_id
-- y origin_city, siguiendo exactamente el mismo patrón que destination_city_id /
-- destination_city (la etiqueta se duplica a propósito para responder sin unir
-- tablas).

alter table reports_shipment_tracking add column sender_name varchar(255);
alter table reports_shipment_tracking add column origin_city_id bigint;
alter table reports_shipment_tracking add column origin_city varchar(255);

update reports_shipment_tracking r
set sender_name = s.sender_full_name,
    origin_city_id = c.id,
    origin_city = c.name || ' - ' || c.department
from shipments s
    join cities c on c.id = s.sender_city_id
where s.tracking_number = r.tracking_number;

-- Una proyección puede tener filas que ya no existan como envío; se reconstruye con
-- POST /api/admin/reconstruir-proyecciones en lugar de bloquear la migración.
delete from reports_shipment_tracking where sender_name is null;

alter table reports_shipment_tracking alter column sender_name set not null;
alter table reports_shipment_tracking alter column origin_city_id set not null;
alter table reports_shipment_tracking alter column origin_city set not null;

alter table reports_shipment_tracking add constraint fk_reports_tracking_origin_city
    foreign key (origin_city_id) references cities (id);
