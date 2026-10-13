-- Un evento logístico tenía una sola fecha, `registered_at`, que es cuando el
-- sistema recibió el reporte. Eso no es cuando ocurrió el movimiento: el lector
-- de la bodega pierde señal y descarga los registros horas después, o el
-- conductor sincroniza al terminar la ruta.
--
-- Se separan las dos fechas. `occurred_at` es la del movimiento —la que ve el
-- cliente y la que ordena el historial— y `registered_at` queda como la de
-- recepción, útil para auditar cuánto tardó en reportarse.
--
-- A los eventos existentes se les asigna su fecha de registro: es la única que
-- se tiene, y era la que se venía mostrando como si fuera la del movimiento.

alter table logistics_events add column occurred_at timestamp(6) with time zone;

update logistics_events set occurred_at = registered_at where occurred_at is null;

alter table logistics_events alter column occurred_at set not null;

-- El historial se consulta por envío y en orden cronológico de ocurrencia.
create index idx_logistics_events_tracking_occurred
    on logistics_events (tracking_number, occurred_at);
