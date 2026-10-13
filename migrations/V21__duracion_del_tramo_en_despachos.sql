-- El reporte de envíos retrasados medía a todos los envíos en tránsito con la misma vara:
-- 48 horas. Un Medellín → Bogotá (9 h de camino) podía ir dos días tarde sin aparecer, y
-- además el reporte mostraba como "punto actual" el centro del que el camión ya había
-- salido.
--
-- Desde esta versión cada despacho guarda cuánto dura su tramo según la red, y el modelo
-- de lectura del rastreo guarda hacia dónde va el camión y esa duración mientras el
-- último movimiento sea el despacho. Con eso el reporte compara cada envío en camino
-- contra su propio tramo (más un 25 % de tolerancia) y dice "en camino a Bogotá".

alter table logistics_events add column planned_leg_hours integer;

-- Relleno: la duración del tramo directo entre la ciudad del despacho y su siguiente
-- parada. Si la red no tiene ese tramo, queda vacío y rige la regla fija del estado.
update logistics_events e
set planned_leg_hours = t.hours
from logistics_route_legs t
where e.type = 'DISPATCHED'
  and e.planned_leg_hours is null
  and t.from_city_id = e.city_id
  and t.to_city_id = e.next_stop_city_id;

alter table reports_shipment_tracking add column next_stop_city varchar(255);
alter table reports_shipment_tracking add column planned_leg_hours integer;

-- Relleno de la proyección: solo los envíos cuyo último movimiento es un despacho.
update reports_shipment_tracking v
set next_stop_city = u.next_stop_city,
    planned_leg_hours = u.planned_leg_hours
from (
    select distinct on (tracking_number) tracking_number, type, next_stop_city, planned_leg_hours
    from logistics_events
    order by tracking_number, occurred_at desc, id desc
) u
where u.tracking_number = v.tracking_number
  and u.type = 'DISPATCHED';
