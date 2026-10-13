-- Reporte de tiempos de tránsito: cuánto tarda un envío entregado en recorrer la red y
-- cuánto de ese tiempo se va en cada tramo. Es un modelo de lectura propio de reports,
-- con una fila por envío y la hora del PRIMER movimiento de cada tipo.
--
-- Los tramos son el lapso entre dos hitos consecutivos del recorrido:
--   received_at            -> dispatched_at           procesamiento en el centro de origen
--   dispatched_at          -> arrived_at              transporte hasta el centro destino
--   arrived_at             -> out_for_delivery_at     procesamiento en el centro destino
--   out_for_delivery_at    -> delivered_at            reparto al destinatario
-- El tiempo total va de received_at (entra a la red) a delivered_at, de modo que los
-- cuatro tramos suman el total. Un transbordo por un hub intermedio queda dentro del
-- tramo de transporte, porque solo se toma el primer despacho.
--
-- Se guarda la hora en que OCURRIÓ el movimiento (occurred_at), no la de su registro:
-- un lector sin señal puede reportar horas tarde y eso no es tiempo de tránsito.

create table reports_shipment_transit (
    tracking_number varchar(255) not null,
    received_at timestamp(6) with time zone,
    dispatched_at timestamp(6) with time zone,
    arrived_at timestamp(6) with time zone,
    out_for_delivery_at timestamp(6) with time zone,
    delivered_at timestamp(6) with time zone,
    primary key (tracking_number)
);

-- El reporte filtra por la fecha de entrega.
create index idx_reports_transit_delivered_at on reports_shipment_transit (delivered_at);

-- Respaldo de los envíos existentes, como hizo V13. POST /api/admin/rebuild-projections
-- sigue siendo el camino de recuperación.
insert into reports_shipment_transit
    (tracking_number, received_at, dispatched_at, arrived_at, out_for_delivery_at, delivered_at)
select s.tracking_number,
       min(e.occurred_at) filter (where e.type = 'RECEIVED_AT_CENTER'),
       min(e.occurred_at) filter (where e.type = 'DISPATCHED'),
       min(e.occurred_at) filter (where e.type = 'ARRIVED_AT_DESTINATION_CENTER'),
       min(e.occurred_at) filter (where e.type = 'OUT_FOR_DELIVERY'),
       min(e.occurred_at) filter (where e.type = 'DELIVERED')
from shipments s
    left join logistics_events e on e.tracking_number = s.tracking_number
group by s.tracking_number;
