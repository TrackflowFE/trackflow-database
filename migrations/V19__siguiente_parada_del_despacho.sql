-- Un despacho solo guardaba desde dónde salía el camión. El historial no podía decir
-- hacia dónde iba, y la interfaz mostraba "despachado hacia" el destino final aunque el
-- camión fuera a un hub intermedio: un envío Cartagena → Cali se veía despachado hacia
-- Cali cuando en realidad iba a Medellín.
--
-- Desde esta versión cada despacho guarda la siguiente parada de su ruta, calculada al
-- registrarlo y congelada como el resto del evento.

alter table logistics_events add column next_stop_city_id bigint;
alter table logistics_events add column next_stop_city varchar(255);

alter table logistics_events add constraint fk_logistics_events_next_stop_city
    foreign key (next_stop_city_id) references cities (id);

-- Relleno de los despachos existentes: la siguiente parada es la ciudad del primer
-- ingreso a un centro posterior al despacho. Un despacho todavía en camino no tiene ese
-- ingreso y se queda sin dato; la ruta del envío (GET /api/shipments/{guía}/route) sí
-- sabe a dónde va.
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
        and e.occurred_at > d.occurred_at
        and e.city_id is not null
      order by e.occurred_at
      limit 1);
