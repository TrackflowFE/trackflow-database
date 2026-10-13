-- Todo "Recibido en centro" dejaba el envío en AT_DISTRIBUTION_CENTER, que la interfaz
-- muestra como "en el centro de origen". En un transbordo por un hub intermedio eso
-- hacía retroceder el progreso: el paquete ya había salido del origen y el cliente lo
-- veía de vuelta ahí. Desde esta versión solo el primer ingreso deja ese estado; un
-- ingreso posterior a un hub deja el envío EN TRÁNSITO, que es lo que está pasando.
--
-- Esta migración corrige los envíos cuyo último movimiento ya es un ingreso a un hub,
-- en las dos tablas que guardan el estado: la del envío y la proyección que consulta
-- el cliente. El resto del estado se deriva del historial, que no cambia.

with ultimo as (
    select distinct on (tracking_number) tracking_number, type, occurred_at
    from logistics_events
    order by tracking_number, occurred_at desc
),
en_hub as (
    select u.tracking_number
    from ultimo u
    where u.type = 'RECEIVED_AT_CENTER'
      and exists (select 1 from logistics_events e
                  where e.tracking_number = u.tracking_number
                    and e.occurred_at < u.occurred_at)
)
update shipments s
set status = 'IN_TRANSIT'
from en_hub h
where s.tracking_number = h.tracking_number
  and s.status = 'AT_DISTRIBUTION_CENTER';

with ultimo as (
    select distinct on (tracking_number) tracking_number, type, occurred_at
    from logistics_events
    order by tracking_number, occurred_at desc
),
en_hub as (
    select u.tracking_number
    from ultimo u
    where u.type = 'RECEIVED_AT_CENTER'
      and exists (select 1 from logistics_events e
                  where e.tracking_number = u.tracking_number
                    and e.occurred_at < u.occurred_at)
)
update reports_shipment_tracking t
set status = 'IN_TRANSIT'
from en_hub h
where t.tracking_number = h.tracking_number
  and t.status = 'AT_DISTRIBUTION_CENTER';
