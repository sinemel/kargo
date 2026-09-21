-- =====================================================================
-- ChinaCargo Hub · Faz 2 · 0007
-- Satır düzeyi güvenlik (RLS) politikaları — tüm tablolar
-- Temel kural: müşteri yalnızca kendi şirketinin verisini görür.
-- Operatör personeli tümünü, çözüm ortağı atanan dosyaları görür.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A) Referans / global tablolar
--    Okuma: giriş yapan herkes (bazıları anon). Yazma: operatör + izin.
-- ---------------------------------------------------------------------

-- roles / permissions / role_permissions — okuma authenticated, yazma super admin
create policy roles_read on public.roles for select to authenticated using (true);
create policy roles_write on public.roles for all to authenticated
  using (app.has_permission('roles.manage')) with check (app.has_permission('roles.manage'));

create policy permissions_read on public.permissions for select to authenticated using (true);
create policy permissions_write on public.permissions for all to authenticated
  using (app.has_permission('roles.manage')) with check (app.has_permission('roles.manage'));

create policy role_permissions_read on public.role_permissions for select to authenticated using (true);
create policy role_permissions_write on public.role_permissions for all to authenticated
  using (app.has_permission('roles.manage')) with check (app.has_permission('roles.manage'));

-- milestone_types — okuma authenticated, yazma super admin
create policy milestone_types_read on public.milestone_types for select to authenticated using (true);
create policy milestone_types_write on public.milestone_types for all to authenticated
  using (app.has_permission('settings.manage')) with check (app.has_permission('settings.manage'));

-- system_settings — public olanlar anon'a açık (maliyet hesaplama aracı, slogan)
create policy system_settings_public_read on public.system_settings for select to anon, authenticated
  using (is_public or app.is_operator_staff());
create policy system_settings_write on public.system_settings for all to authenticated
  using (app.has_permission('settings.manage')) with check (app.has_permission('settings.manage'));

-- legal_texts — aktif metinler herkese açık (aydınlatma/rıza)
create policy legal_texts_read on public.legal_texts for select to anon, authenticated
  using (is_active or app.is_operator_staff());
create policy legal_texts_write on public.legal_texts for all to authenticated
  using (app.has_permission('settings.manage')) with check (app.has_permission('settings.manage'));

-- pricing_rules — okuma authenticated (hesap aracı), yazma operatör
create policy pricing_rules_read on public.pricing_rules for select to authenticated using (true);
create policy pricing_rules_write on public.pricing_rules for all to authenticated
  using (app.has_permission('pricing_rules.manage')) with check (app.has_permission('pricing_rules.manage'));

-- warehouses — aktif+public olanlar anon'a açık ("Çin depo noktaları")
create policy warehouses_public_read on public.warehouses for select to anon, authenticated
  using ((is_public and is_active) or app.is_operator_staff());
create policy warehouses_write on public.warehouses for all to authenticated
  using (app.has_permission('warehouses.manage')) with check (app.has_permission('warehouses.manage'));

create policy warehouse_locations_read on public.warehouse_locations for select to authenticated
  using (app.is_operator_staff());
create policy warehouse_locations_write on public.warehouse_locations for all to authenticated
  using (app.has_permission('warehouses.manage')) with check (app.has_permission('warehouses.manage'));

-- carriers — okuma operatör, yazma operatör
create policy carriers_read on public.carriers for select to authenticated using (app.is_operator_staff());
create policy carriers_write on public.carriers for all to authenticated
  using (app.has_permission('carriers.manage')) with check (app.has_permission('carriers.manage'));

-- exchange_rates — okuma authenticated, yazma operatör finans
create policy exchange_rates_read on public.exchange_rates for select to authenticated using (true);
create policy exchange_rates_write on public.exchange_rates for all to authenticated
  using (app.has_permission('finance.manage')) with check (app.has_permission('finance.manage'));

-- ---------------------------------------------------------------------
-- B) Şirket, üyelik, müşteri, tedarikçi
-- ---------------------------------------------------------------------

-- companies — operatör tümü; kullanıcı kendi şirket(ler)i
create policy companies_read on public.companies for select to authenticated
  using (app.is_operator_staff() or id in (select app.member_company_ids()));
create policy companies_insert on public.companies for insert to authenticated
  with check (app.has_permission('companies.manage'));
create policy companies_update on public.companies for update to authenticated
  using (app.has_permission('companies.manage') or (app.has_permission('company.manage_own') and id in (select app.member_company_ids())))
  with check (app.has_permission('companies.manage') or (app.has_permission('company.manage_own') and id in (select app.member_company_ids())));

-- company_users — operatör tümü; kendi şirketinin üyeleri; kendi satırı
create policy company_users_read on public.company_users for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()) or user_id = auth.uid());
create policy company_users_write on public.company_users for all to authenticated
  using (app.has_permission('users.manage_all') or (app.has_permission('users.manage_own') and company_id in (select app.member_company_ids())))
  with check (app.has_permission('users.manage_all') or (app.has_permission('users.manage_own') and company_id in (select app.member_company_ids())));

-- customers — operatör tümü; kullanıcı kendi şirket profili
create policy customers_read on public.customers for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy customers_write on public.customers for all to authenticated
  using (app.has_permission('companies.manage')) with check (app.has_permission('companies.manage'));

-- suppliers — operatör görür; müşteri kendi tedarikçilerini yönetir
create policy suppliers_read on public.suppliers for select to authenticated
  using (app.has_permission('suppliers.view_all') or company_id in (select app.member_company_ids()));
create policy suppliers_write on public.suppliers for all to authenticated
  using (app.has_permission('suppliers.manage_own') and company_id in (select app.member_company_ids()))
  with check (app.has_permission('suppliers.manage_own') and company_id in (select app.member_company_ids()));

-- ---------------------------------------------------------------------
-- C) Talep, teklif
-- ---------------------------------------------------------------------

-- shipment_requests
create policy requests_read on public.shipment_requests for select to authenticated
  using (app.has_permission('requests.view_all') or company_id in (select app.member_company_ids()));
create policy requests_insert on public.shipment_requests for insert to authenticated
  with check (app.has_permission('requests.create') and company_id in (select app.member_company_ids()));
create policy requests_update on public.shipment_requests for update to authenticated
  using (app.has_permission('requests.review') or (app.has_permission('requests.create') and company_id in (select app.member_company_ids())))
  with check (app.has_permission('requests.review') or (app.has_permission('requests.create') and company_id in (select app.member_company_ids())));

-- shipment_items — talebin görünürlüğünü izler
create policy items_read on public.shipment_items for select to authenticated
  using (app.has_permission('requests.view_all') or company_id in (select app.member_company_ids()));
create policy items_write on public.shipment_items for all to authenticated
  using (app.has_permission('requests.review') or (app.has_permission('requests.create') and company_id in (select app.member_company_ids())))
  with check (app.has_permission('requests.review') or (app.has_permission('requests.create') and company_id in (select app.member_company_ids())));

-- precheck_flags — operatör yazar; müşteri kendi taleplerinde görür
create policy precheck_read on public.precheck_flags for select to authenticated
  using (app.has_permission('requests.view_all') or company_id in (select app.member_company_ids()));
create policy precheck_write on public.precheck_flags for all to authenticated
  using (app.has_permission('precheck.manage')) with check (app.has_permission('precheck.manage'));

-- quotations — operatör tümü; müşteri kendi teklifleri (onay RPC ile)
create policy quotations_read on public.quotations for select to authenticated
  using (app.has_permission('quotations.prepare') or company_id in (select app.member_company_ids()));
create policy quotations_write on public.quotations for all to authenticated
  using (app.has_permission('quotations.prepare')) with check (app.has_permission('quotations.prepare'));

create policy quotation_requests_read on public.quotation_requests for select to authenticated
  using (app.is_operator_staff() or exists (
    select 1 from public.quotations q where q.id = quotation_id and q.company_id in (select app.member_company_ids())));
create policy quotation_requests_write on public.quotation_requests for all to authenticated
  using (app.has_permission('quotations.prepare')) with check (app.has_permission('quotations.prepare'));

create policy quotation_items_read on public.quotation_items for select to authenticated
  using (app.has_permission('quotations.prepare') or company_id in (select app.member_company_ids()));
create policy quotation_items_write on public.quotation_items for all to authenticated
  using (app.has_permission('quotations.prepare')) with check (app.has_permission('quotations.prepare'));

-- quotation_item_costs — HASSAS: yalnızca maliyet görme izni olan operatör
create policy quotation_costs_all on public.quotation_item_costs for all to authenticated
  using (app.has_permission('quotations.view_costs')) with check (app.has_permission('quotations.view_costs'));

-- ---------------------------------------------------------------------
-- D) Depo, konsolidasyon, sefer, konteyner
-- ---------------------------------------------------------------------

-- warehouse_receipts — operatör tümü; müşteri kendi kabulleri (salt okunur)
create policy receipts_read on public.warehouse_receipts for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy receipts_write on public.warehouse_receipts for all to authenticated
  using (app.has_permission('warehouse.receive')) with check (app.has_permission('warehouse.receive'));

create policy packages_read on public.packages for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy packages_write on public.packages for all to authenticated
  using (app.has_permission('warehouse.receive') or app.has_permission('warehouse.inspect'))
  with check (app.has_permission('warehouse.receive') or app.has_permission('warehouse.inspect'));

create policy inspections_read on public.inspections for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy inspections_write on public.inspections for all to authenticated
  using (app.has_permission('warehouse.inspect')) with check (app.has_permission('warehouse.inspect'));

-- media_assets — müşteriye görünür işareti + kiracı; operatör tümü
create policy media_read on public.media_assets for select to authenticated
  using (app.is_operator_staff() or (company_id in (select app.member_company_ids()) and is_customer_visible));
create policy media_write on public.media_assets for all to authenticated
  using (app.has_permission('warehouse.upload_media') or app.is_operator_staff())
  with check (app.has_permission('warehouse.upload_media') or app.is_operator_staff());

-- consolidations
create policy consolidations_read on public.consolidations for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy consolidations_write on public.consolidations for all to authenticated
  using (app.has_permission('consolidations.manage') or app.has_permission('consolidations.prepare'))
  with check (app.has_permission('consolidations.manage') or app.has_permission('consolidations.prepare'));

create policy consolidation_items_read on public.consolidation_items for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy consolidation_items_write on public.consolidation_items for all to authenticated
  using (app.has_permission('consolidations.manage') or app.has_permission('consolidations.prepare'))
  with check (app.has_permission('consolidations.manage') or app.has_permission('consolidations.prepare'));

-- sailing_schedules — operatör tümü; müşteri yalnızca kendi sevkiyatının seferi
create policy schedules_read on public.sailing_schedules for select to authenticated
  using (app.is_operator_staff() or id in (
    select schedule_id from public.shipments where company_id in (select app.member_company_ids())));
create policy schedules_write on public.sailing_schedules for all to authenticated
  using (app.has_permission('schedules.manage')) with check (app.has_permission('schedules.manage'));

-- containers — operatör tümü; müşteri kendi sevkiyatının konteyneri
create policy containers_read on public.containers for select to authenticated
  using (app.is_operator_staff() or id in (
    select container_id from public.shipments where company_id in (select app.member_company_ids())));
create policy containers_write on public.containers for all to authenticated
  using (app.has_permission('containers.manage')) with check (app.has_permission('containers.manage'));

-- container_loads — HASSAS: müşteri YALNIZCA kendi yükünü görür (başka müşteri sızmaz)
create policy container_loads_read on public.container_loads for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy container_loads_write on public.container_loads for all to authenticated
  using (app.has_permission('bookings.manage') or app.has_permission('containers.manage'))
  with check (app.has_permission('bookings.manage') or app.has_permission('containers.manage'));

-- ---------------------------------------------------------------------
-- E) Sevkiyat, takip, evrak, gümrük, teslimat
-- ---------------------------------------------------------------------

-- shipments — operatör tümü; müşteri kendi; çözüm ortağı atanan
create policy shipments_read on public.shipments for select to authenticated
  using (app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or id in (select app.partner_shipment_ids()));
create policy shipments_write on public.shipments for all to authenticated
  using (app.has_permission('shipments.update_status')) with check (app.has_permission('shipments.update_status'));

-- shipment_milestones — müşteriye görünür olanlar; ekleme RPC/operatör
create policy milestones_read on public.shipment_milestones for select to authenticated
  using (app.is_operator_staff()
      or (company_id in (select app.member_company_ids()) and is_customer_visible)
      or shipment_id in (select app.partner_shipment_ids()));
create policy milestones_write on public.shipment_milestones for all to authenticated
  using (app.has_permission('shipments.update_status')) with check (app.has_permission('shipments.update_status'));

-- documents — kiracı + görünürlük; operatör tümü; çözüm ortağı atanan sevkiyat
create policy documents_read on public.documents for select to authenticated
  using (
    app.has_permission('documents.view_all')
    or (company_id in (select app.member_company_ids()) and is_customer_visible)
    or (entity_type = 'shipment' and entity_id in (select app.partner_shipment_ids()))
  );
create policy documents_insert on public.documents for insert to authenticated
  with check (
    app.has_permission('documents.upload_all')
    or (app.has_permission('documents.upload_own') and company_id in (select app.member_company_ids()))
    or (app.has_permission('documents.view_assigned') and entity_type = 'shipment' and entity_id in (select app.partner_shipment_ids()))
  );
create policy documents_update on public.documents for update to authenticated
  using (app.has_permission('documents.upload_all') or (app.has_permission('documents.upload_own') and company_id in (select app.member_company_ids())))
  with check (app.has_permission('documents.upload_all') or (app.has_permission('documents.upload_own') and company_id in (select app.member_company_ids())));

-- document_requirements — kiracı görür; operatör/ortak yazar
create policy doc_req_read on public.document_requirements for select to authenticated
  using (app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or (entity_type = 'shipment' and entity_id in (select app.partner_shipment_ids())));
create policy doc_req_write on public.document_requirements for all to authenticated
  using (app.has_permission('documents.flag_missing') or app.has_permission('documents.upload_all'))
  with check (app.has_permission('documents.flag_missing') or app.has_permission('documents.upload_all'));

-- customs_files — operatör tümü; müşteri kendi; çözüm ortağı atanan
create policy customs_read on public.customs_files for select to authenticated
  using (app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or partner_company_id in (select app.member_company_ids()));
create policy customs_insert on public.customs_files for insert to authenticated
  with check (app.has_permission('customs.manage'));
create policy customs_update on public.customs_files for update to authenticated
  using (app.has_permission('customs.manage')
      or (app.has_permission('customs.update_assigned') and partner_company_id in (select app.member_company_ids())))
  with check (app.has_permission('customs.manage')
      or (app.has_permission('customs.update_assigned') and partner_company_id in (select app.member_company_ids())));

-- delivery_orders — operatör tümü; müşteri kendi (talep)
create policy deliveries_read on public.delivery_orders for select to authenticated
  using (app.is_operator_staff() or company_id in (select app.member_company_ids()));
create policy deliveries_insert on public.delivery_orders for insert to authenticated
  with check (app.has_permission('deliveries.manage')
      or (app.has_permission('deliveries.request') and company_id in (select app.member_company_ids())));
create policy deliveries_update on public.delivery_orders for update to authenticated
  using (app.has_permission('deliveries.manage')) with check (app.has_permission('deliveries.manage'));

-- ---------------------------------------------------------------------
-- F) Finans
-- ---------------------------------------------------------------------

-- invoices — operatör tümü; müşteri kendi (salt okunur)
create policy invoices_read on public.invoices for select to authenticated
  using (app.has_permission('finance.manage') or company_id in (select app.member_company_ids()));
create policy invoices_write on public.invoices for all to authenticated
  using (app.has_permission('finance.manage')) with check (app.has_permission('finance.manage'));

create policy invoice_items_read on public.invoice_items for select to authenticated
  using (app.has_permission('finance.manage') or company_id in (select app.member_company_ids()));
create policy invoice_items_write on public.invoice_items for all to authenticated
  using (app.has_permission('finance.manage')) with check (app.has_permission('finance.manage'));

-- payments — operatör tümü; müşteri kendi (bildirim RPC ile; doğrudan insert de mümkün)
create policy payments_read on public.payments for select to authenticated
  using (app.has_permission('finance.manage') or company_id in (select app.member_company_ids()));
create policy payments_insert on public.payments for insert to authenticated
  with check (app.has_permission('finance.manage')
      or (app.has_permission('finance.report_payment') and company_id in (select app.member_company_ids()) and status = 'reported'));
create policy payments_update on public.payments for update to authenticated
  using (app.has_permission('finance.manage')) with check (app.has_permission('finance.manage'));

-- expenses — HASSAS: yalnızca operatör (gerçekleşen maliyet, tedarikçi/taşıyıcı borcu)
create policy expenses_all on public.expenses for all to authenticated
  using (app.has_permission('finance.record_expense') or app.has_permission('finance.view_reports'))
  with check (app.has_permission('finance.record_expense'));

-- ---------------------------------------------------------------------
-- G) İletişim ve bildirim
-- ---------------------------------------------------------------------

-- support_tickets — operatör tümü; kiracı kendi; ortak atanan
create policy tickets_read on public.support_tickets for select to authenticated
  using (app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or partner_company_id in (select app.member_company_ids()));
create policy tickets_insert on public.support_tickets for insert to authenticated
  with check (app.has_permission('tickets.create') and (company_id in (select app.member_company_ids()) or app.is_operator_staff()));
create policy tickets_update on public.support_tickets for update to authenticated
  using (app.has_permission('tickets.manage')
      or (company_id in (select app.member_company_ids()) and app.has_permission('tickets.create')))
  with check (app.has_permission('tickets.manage')
      or (company_id in (select app.member_company_ids()) and app.has_permission('tickets.create')));

-- messages — dahili notlar yalnızca operatör; kiracı kendi dosyası; ortak atanan
create policy messages_read on public.messages for select to authenticated
  using (
    (not is_internal or app.is_operator_staff())
    and (
      app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or shipment_id in (select app.partner_shipment_ids())
    )
  );
create policy messages_insert on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and app.has_permission('messages.send')
    and (not is_internal or app.has_permission('messages.internal'))
    and (
      app.is_operator_staff()
      or company_id in (select app.member_company_ids())
      or shipment_id in (select app.partner_shipment_ids())
    )
  );

create policy message_reads_self on public.message_reads for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- notifications — yalnızca sahibi
create policy notifications_read on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy notifications_update on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- consent_records — kullanıcı kendi kayıtları; operatör okur
create policy consent_read on public.consent_records for select to authenticated
  using (user_id = auth.uid() or app.is_operator_staff());
create policy consent_insert on public.consent_records for insert to authenticated
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- H) Yalnızca operatör / sistem tabloları
-- ---------------------------------------------------------------------

-- activity_logs — yalnızca izin sahibi okur, yazma tetikleyiciyle (definer)
create policy activity_logs_read on public.activity_logs for select to authenticated
  using (app.has_permission('activity_logs.view'));

-- webhook_endpoints / deliveries — yalnızca operatör ayarları
create policy webhook_endpoints_all on public.webhook_endpoints for all to authenticated
  using (app.has_permission('settings.manage')) with check (app.has_permission('settings.manage'));
create policy webhook_deliveries_read on public.webhook_deliveries for select to authenticated
  using (app.has_permission('settings.manage'));

-- sequence_counters — istemciye kapalı (yalnızca definer fonksiyonlar erişir)
-- (politika yok → authenticated erişemez; app.next_sequence security definer çalışır)

-- users — kendi profili + operatör; kendi profilini güncelleme
create policy users_read on public.users for select to authenticated
  using (
    id = auth.uid()
    or app.is_operator_staff()
    or exists (
      select 1 from public.company_users a
      join public.company_users b on a.company_id = b.company_id
      where a.user_id = auth.uid() and a.status = 'active'
        and b.user_id = public.users.id and b.status = 'active'
    )
  );
create policy users_update_self on public.users for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
