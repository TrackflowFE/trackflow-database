-- La V19 rellenó la siguiente parada de cada despacho con la ciudad del primer ingreso
-- posterior, comparando occurred_at de forma estricta. Quedaron dos huecos:
--
--   1. Un despacho con la misma hora que el ingreso siguiente (lo normal cuando la fecha
--      se reporta con precisión de minutos) no encontraba ningún ingreso "posterior".
--   2. Los despachos registrados durante el despliegue, después de que la V19 corriera
--      pero todavía atendidos por la versión anterior, quedaron sin el dato.
--
-- Este relleno repite el de la V19 solo donde sigue vacío, y resuelve el empate de hora
-- con el id, que es el orden de registro, igual que el historial desde esta versión.

update logistics_events d
set next_stop_city_id = siguiente.city_id,
    next_stop_city = siguiente.city_name
from logistics_events siguiente
where d.type = 'DISPATCHED'
  and d.next_stop_city_id is null
  and siguiente.id = (
      select e.id
      from logistics_events e
      where e.tracking_number = d.tracking_number
        and e.type in ('RECEIVED_AT_CENTER', 'ARRIVED_AT_DESTINATION_CENTER')
        and (e.occurred_at, e.id) > (d.occurred_at, d.id)
        and e.city_id is not null
      order by e.occurred_at, e.id
      limit 1);
