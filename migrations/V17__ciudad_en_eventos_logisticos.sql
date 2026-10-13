-- El evento logístico guardaba la ciudad solo como texto ("BOGOTÁ - CUNDINAMARCA"),
-- congelado en el momento del registro. Sirve para mostrar, pero no para agrupar: un
-- reporte por ciudad tendría que comparar etiquetas, que es justo el problema que el
-- catálogo de ciudades (V4) vino a resolver para el origen y el destino.
--
-- Se agrega el id de la ciudad del centro donde ocurrió el movimiento, en el evento y en
-- las proyecciones que lo usan. La etiqueta se queda, congelada como siempre (V8): el id
-- es para agrupar y la etiqueta para mostrar sin consultar el catálogo.

alter table logistics_events add column city_id bigint;

alter table logistics_events add constraint fk_logistics_events_city
    foreign key (city_id) references cities (id);

create index idx_logistics_events_city on logistics_events (city_id);

-- Relleno desde el centro: un centro no cambia de ciudad, así que su ciudad actual es
-- la misma que tenía cuando ocurrió el movimiento. Los eventos sin centro (texto libre,
-- anteriores a V8) se quedan con city_id nulo.
update logistics_events e
set city_id = c.city_id
from logistics_centers c
where c.id = e.center_id
  and e.city_id is null;

-- Reporte de volumen: la ciudad por la que el envío entró a la red.
alter table reports_shipment_volume add column entry_city_id bigint;

alter table reports_shipment_volume add constraint fk_reports_volume_entry_city
    foreign key (entry_city_id) references cities (id);

update reports_shipment_volume v
set entry_city_id = c.city_id
from logistics_centers c
where c.id = v.entry_center_id;

-- Tracking del cliente: la ciudad donde está el paquete, que es la del último movimiento.
alter table reports_shipment_tracking add column last_movement_city_id bigint;
alter table reports_shipment_tracking add column last_movement_city varchar(255);

alter table reports_shipment_tracking add constraint fk_reports_tracking_last_movement_city
    foreign key (last_movement_city_id) references cities (id);

update reports_shipment_tracking t
set last_movement_city_id = e.city_id,
    last_movement_city = e.city_name
from (
    select distinct on (tracking_number) tracking_number, city_id, city_name
    from logistics_events
    order by tracking_number, occurred_at desc
) e
where e.tracking_number = t.tracking_number;
