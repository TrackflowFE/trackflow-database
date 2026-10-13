-- Desde la versión 18, ningún movimiento puede tener una fecha anterior al registro del
-- envío. Los envíos registrados antes de esa regla pueden traer esa incoherencia: la
-- semilla cargada en Render el 30 de septiembre de 2026, antes de que la fecha de
-- registro viajara en el mensaje de la cola, tiene sus 12 envíos con movimientos
-- recibidos en centro hasta cinco días antes de "registrarse".
--
-- Se corrige sin borrar nada: la fecha de registro pasa a ser una hora antes del primer
-- movimiento, en las cuatro tablas que la guardan. Solo se tocan los envíos
-- incoherentes; en los demás la fecha queda igual.

create temporary table primer_movimiento on commit drop as
select tracking_number, min(occurred_at) - interval '1 hour' as registro_coherente
from logistics_events
group by tracking_number;

update shipments s
set registered_at = p.registro_coherente
from primer_movimiento p
where p.tracking_number = s.tracking_number
  and p.registro_coherente < s.registered_at;

update logistics_tracked_shipments s
set registered_at = p.registro_coherente
from primer_movimiento p
where p.tracking_number = s.tracking_number
  and p.registro_coherente < s.registered_at;

update reports_shipment_tracking s
set registered_at = p.registro_coherente
from primer_movimiento p
where p.tracking_number = s.tracking_number
  and p.registro_coherente < s.registered_at;

update reports_shipment_volume s
set registered_at = p.registro_coherente
from primer_movimiento p
where p.tracking_number = s.tracking_number
  and p.registro_coherente < s.registered_at;
