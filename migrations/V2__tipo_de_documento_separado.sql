-- El documento de identidad estaba en una sola columna ("CC1001"), mezclando
-- dos datos distintos. Se separa en tipo y número, con el tipo restringido a
-- los documentos admitidos.
--
-- A los registros existentes se les asigna CC, que es el tipo mayoritario en
-- envíos entre personas naturales; el número se conserva tal cual estaba.

alter table shipments rename column sender_document_id to sender_document_number;
alter table shipments rename column recipient_document_id to recipient_document_number;

alter table shipments add column sender_document_type varchar(5);
alter table shipments add column recipient_document_type varchar(5);

update shipments set sender_document_type = 'CC' where sender_document_type is null;
update shipments set recipient_document_type = 'CC' where recipient_document_type is null;

alter table shipments alter column sender_document_type set not null;
alter table shipments alter column recipient_document_type set not null;

alter table shipments add constraint ck_shipments_sender_document_type
    check (sender_document_type in ('CC', 'CE', 'TI', 'PP', 'NIT'));
alter table shipments add constraint ck_shipments_recipient_document_type
    check (recipient_document_type in ('CC', 'CE', 'TI', 'PP', 'NIT'));
