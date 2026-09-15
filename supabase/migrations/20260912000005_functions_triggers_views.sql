-- =====================================================================
-- ChinaCargo Hub · Faz 1 · 0005
-- Tetikleyiciler, hesaplama motoru, özet view'lar, RLS (varsayılan kapalı kapı)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) updated_at · updated_at sütunu olan tüm tablolara
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  for t in
    select c.table_name
    from information_schema.columns c
    join information_schema.tables tb
      on tb.table_schema = c.table_schema and tb.table_name = c.table_name
    where c.table_schema = 'public' and c.column_name = 'updated_at' and tb.table_type = 'BASE TABLE'
  loop
    execute format('drop trigger if exists trg_set_updated_at on public.%I', t);
    execute format('create trigger trg_set_updated_at before update on public.%I for each row execute function app.set_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2) Belge numaralandırma · ÖNEK-YIL-SIRA (kayıt numara ile gelmişse dokunmaz)
-- ---------------------------------------------------------------------
create or replace function app.assign_document_no() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  case tg_table_name
    when 'shipment_requests'  then if new.request_no is null       then new.request_no       := app.next_document_no('TLP', 6); end if;
    when 'quotations'         then if new.quotation_no is null     then new.quotation_no     := app.next_document_no('TKL', 5); end if;
    when 'warehouse_receipts' then if new.receipt_no is null       then new.receipt_no       := app.next_document_no('DPK', 5); end if;
    when 'consolidations'     then if new.consolidation_no is null then new.consolidation_no := app.next_document_no('KNS', 5); end if;
    when 'sailing_schedules'  then if new.schedule_code is null    then new.schedule_code    := app.next_document_no('SEF', 5); end if;
    when 'shipments'          then if new.shipment_no is null      then new.shipment_no      := app.next_document_no('SVK', 5); end if;
    when 'customs_files'      then if new.customs_file_no is null  then new.customs_file_no  := app.next_document_no('GMR', 5); end if;
    when 'delivery_orders'    then if new.delivery_no is null      then new.delivery_no      := app.next_document_no('TSL', 5); end if;
    when 'invoices'           then if new.invoice_no is null       then new.invoice_no       := app.next_document_no('FTR', 5); end if;
    when 'payments'           then if new.payment_no is null       then new.payment_no       := app.next_document_no('ODM', 5); end if;
    when 'expenses'           then if new.expense_no is null       then new.expense_no       := app.next_document_no('MSR', 5); end if;
    when 'support_tickets'    then if new.ticket_no is null        then new.ticket_no        := app.next_document_no('DST', 5); end if;
    else null;
  end case;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'shipment_requests', 'quotations', 'warehouse_receipts', 'consolidations', 'sailing_schedules',
    'shipments', 'customs_files', 'delivery_orders', 'invoices', 'payments', 'expenses', 'support_tickets']
  loop
    execute format('drop trigger if exists trg_assign_document_no on public.%I', t);
    execute format('create trigger trg_assign_document_no before insert on public.%I for each row execute function app.assign_document_no()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 3) Depo teslim kodu · CC-IST-2026-00428-S01
--    CC = ön ek, IST = varış merkezi (system_settings), 00428 = müşteri no,
--    S01 = müşterinin o yılki kabul sırası
-- ---------------------------------------------------------------------
create or replace function app.generate_delivery_code(p_customer_id uuid) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_customer_code text;
  v_prefix text;
  v_hub text;
  v_year int := extract(year from now())::int;
  v_seq int;
begin
  select customer_code into v_customer_code from public.customers where id = p_customer_id;
  if v_customer_code is null then
    raise exception 'Müşteri bulunamadı: %', p_customer_id;
  end if;
  select value #>> '{}' into v_prefix from public.system_settings where key = 'delivery_code_prefix';
  select value #>> '{}' into v_hub    from public.system_settings where key = 'destination_hub_code';
  v_seq := app.next_sequence('DLV-' || v_customer_code, v_year);
  return format('%s-%s-%s-%s-S%s', coalesce(v_prefix, 'CC'), coalesce(v_hub, 'IST'), v_year, v_customer_code, lpad(v_seq::text, 2, '0'));
end $$;

create or replace function app.assign_delivery_code() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.delivery_code is null then
    new.delivery_code := app.generate_delivery_code(new.customer_id);
  end if;
  return new;
end $$;

create trigger trg_assign_delivery_code before insert on public.warehouse_receipts
  for each row execute function app.assign_delivery_code();

-- Koli QR kodu · <teslim kodu>-Pnnn
create or replace function app.assign_package_qr() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.qr_code is null then
    select wr.delivery_code || '-P' || lpad(new.package_no::text, 3, '0')
      into new.qr_code
    from public.warehouse_receipts wr where wr.id = new.receipt_id;
  end if;
  return new;
end $$;

create trigger trg_assign_package_qr before insert on public.packages
  for each row execute function app.assign_package_qr();

-- ---------------------------------------------------------------------
-- 4) Rol kapsamı doğrulaması · roles.scope = companies.type
-- ---------------------------------------------------------------------
create or replace function app.check_company_user_role() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_scope company_type; v_type company_type;
begin
  select scope into v_scope from public.roles     where id = new.role_id;
  select type  into v_type  from public.companies where id = new.company_id;
  if v_scope is distinct from v_type then
    raise exception 'Rol kapsamı (%) şirket türüyle (%) uyuşmuyor', v_scope, v_type;
  end if;
  return new;
end $$;

create trigger trg_check_company_user_role before insert or update of role_id, company_id on public.company_users
  for each row execute function app.check_company_user_role();

-- ---------------------------------------------------------------------
-- 5) Hesaplama motoru (spec bölüm 5) · ölçüler cm, ağırlık kg, hacim m³
-- ---------------------------------------------------------------------
-- CBM = En × Boy × Yükseklik / 1.000.000 × adet
create or replace function public.calc_cbm(p_length_cm numeric, p_width_cm numeric, p_height_cm numeric, p_count int default 1)
returns numeric language sql immutable as $$
  select round(p_length_cm * p_width_cm * p_height_cm / 1000000.0 * p_count, 4)
$$;

-- Hava kargo hacimsel ağırlık = En × Boy × Yükseklik / bölen × adet (varsayılan 6000)
create or replace function public.calc_volumetric_kg(p_length_cm numeric, p_width_cm numeric, p_height_cm numeric, p_count int default 1, p_divisor numeric default 6000)
returns numeric language sql immutable as $$
  select round(p_length_cm * p_width_cm * p_height_cm / p_divisor * p_count, 3)
$$;

-- Deniz/demiryolu W/M = max(CBM, kg / kg_per_cbm, minimum)
create or replace function public.calc_chargeable_wm(p_cbm numeric, p_gross_kg numeric, p_kg_per_cbm numeric default 1000, p_min numeric default 1)
returns numeric language sql immutable as $$
  select round(greatest(coalesce(p_cbm, 0), coalesce(p_gross_kg, 0) / nullif(p_kg_per_cbm, 0), coalesce(p_min, 0)), 4)
$$;

-- Geçerli fiyat kuralı: taşıyıcıya özel kural genel kuralı ezer
create or replace function public.get_pricing_rule(p_mode transport_mode, p_carrier_id uuid default null)
returns public.pricing_rules language sql stable as $$
  select r.*
  from public.pricing_rules r
  where r.transport_mode = p_mode
    and r.is_active
    and (r.carrier_id is null or r.carrier_id = p_carrier_id)
    and r.valid_from <= current_date
    and (r.valid_to is null or r.valid_to >= current_date)
  order by (r.carrier_id is not null) desc, r.valid_from desc
  limit 1
$$;

-- Ücretlendirilebilir miktar: deniz/demiryolu → W/M, hava/ekspres → kg
create or replace function public.calc_chargeable(p_mode transport_mode, p_cbm numeric, p_gross_kg numeric, p_carrier_id uuid default null)
returns table (chargeable_qty numeric, chargeable_unit text, rule_id uuid)
language plpgsql stable as $$
declare r public.pricing_rules;
begin
  r := public.get_pricing_rule(p_mode, p_carrier_id);
  if p_mode in ('air_cargo', 'express') then
    return query select
      round(greatest(coalesce(p_gross_kg, 0), coalesce(p_cbm, 0) * 1000000 / coalesce(r.volumetric_divisor, 6000), coalesce(r.min_chargeable, 0)), 3),
      'kg'::text, r.id;
  else
    return query select
      public.calc_chargeable_wm(p_cbm, p_gross_kg, coalesce(r.wm_kg_per_cbm, 1000), coalesce(r.min_chargeable, 1)),
      'wm'::text, r.id;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 6) Teklif toplamı · yalnızca Kesin + Tahmini kalemler toplanır
-- ---------------------------------------------------------------------
create or replace function app.recalc_quotation_totals() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_qid uuid := coalesce(new.quotation_id, old.quotation_id); v_sum numeric(14,2);
begin
  select coalesce(sum(amount), 0) into v_sum
  from public.quotation_items
  where quotation_id = v_qid and certainty in ('fixed', 'estimated');
  update public.quotations set subtotal = v_sum, total = v_sum where id = v_qid;
  return null;
end $$;

create trigger trg_quotation_items_totals after insert or update or delete on public.quotation_items
  for each row execute function app.recalc_quotation_totals();

-- ---------------------------------------------------------------------
-- 7) Milestone → sevkiyatın güncel durumu + müşteri bildirimi
-- ---------------------------------------------------------------------
create or replace function app.apply_shipment_milestone() returns trigger
language plpgsql security definer set search_path = public as $$
declare mt public.milestone_types; v_cur_sort int;
begin
  select * into mt from public.milestone_types where code = new.milestone_code;

  select coalesce(m.sort_order, 0) into v_cur_sort
  from public.shipments s
  left join public.milestone_types m on m.code = s.current_milestone_code
  where s.id = new.shipment_id;

  -- istisna adımları (eksik/hasar) zaman çizelgesinde görünür ama ilerlemeyi değiştirmez
  if not mt.is_exception and mt.sort_order >= coalesce(v_cur_sort, 0) then
    update public.shipments
    set current_milestone_code = new.milestone_code,
        current_milestone_at   = new.occurred_at,
        status       = case when new.milestone_code = 'delivered' then 'delivered'::shipment_status else status end,
        delivered_at = case when new.milestone_code = 'delivered' then new.occurred_at else delivered_at end
    where id = new.shipment_id;
  end if;

  if mt.notify_customer and new.is_customer_visible then
    insert into public.notifications (company_id, user_id, event_key, title_tr, body_tr, entity_type, entity_id, channel, payload)
    select cu.company_id, cu.user_id,
           'shipment.milestone.' || new.milestone_code,
           mt.name_tr, new.description, 'shipment', new.shipment_id, 'in_app',
           jsonb_build_object('shipment_id', new.shipment_id, 'milestone', new.milestone_code, 'occurred_at', new.occurred_at)
    from public.company_users cu
    where cu.company_id = new.company_id and cu.status = 'active';
  end if;
  return new;
end $$;

create trigger trg_apply_shipment_milestone after insert on public.shipment_milestones
  for each row execute function app.apply_shipment_milestone();

-- ---------------------------------------------------------------------
-- 8) İşlem kaydı · kritik tablolarda insert/update/delete (update'te yalnızca değişen alanlar)
-- ---------------------------------------------------------------------
create or replace function app.log_activity() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_company uuid; v_entity uuid;
  v_before jsonb; v_after jsonb; v_changed text[];
begin
  if tg_op = 'DELETE' then
    v_company := (to_jsonb(old) ->> 'company_id')::uuid;
    v_entity  := (to_jsonb(old) ->> 'id')::uuid;
    insert into public.activity_logs (company_id, user_id, action, entity_type, entity_id, before_data)
    values (v_company, auth.uid(), 'delete', tg_table_name, v_entity, to_jsonb(old));
    return old;
  end if;

  v_company := (to_jsonb(new) ->> 'company_id')::uuid;
  v_entity  := (to_jsonb(new) ->> 'id')::uuid;

  if tg_op = 'INSERT' then
    insert into public.activity_logs (company_id, user_id, action, entity_type, entity_id, after_data)
    values (v_company, auth.uid(), 'insert', tg_table_name, v_entity, to_jsonb(new));
    return new;
  end if;

  select jsonb_object_agg(n.key, o.value), jsonb_object_agg(n.key, n.value), array_agg(n.key)
    into v_before, v_after, v_changed
  from jsonb_each(to_jsonb(new)) n
  join jsonb_each(to_jsonb(old)) o on o.key = n.key
  where n.value is distinct from o.value and n.key <> 'updated_at';

  if v_changed is null then
    return new;
  end if;

  insert into public.activity_logs (company_id, user_id, action, entity_type, entity_id, before_data, after_data, changed_fields)
  values (v_company, auth.uid(),
          case when 'status' = any (v_changed) then 'status_change' else 'update' end,
          tg_table_name, v_entity, v_before, v_after, v_changed);
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array[
    'companies', 'company_users', 'customers', 'suppliers', 'shipment_requests', 'quotations', 'quotation_items',
    'warehouse_receipts', 'inspections', 'consolidations', 'sailing_schedules', 'containers', 'container_loads',
    'shipments', 'customs_files', 'delivery_orders', 'invoices', 'payments', 'expenses', 'documents',
    'pricing_rules', 'system_settings']
  loop
    execute format('drop trigger if exists trg_log_activity on public.%I', t);
    execute format('create trigger trg_log_activity after insert or update or delete on public.%I for each row execute function app.log_activity()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 9) Özet view'lar · security_invoker: okuyanın RLS'i geçerli (Faz 2)
-- ---------------------------------------------------------------------

-- Talep toplamları (kalemlerden hesaplanır; müşterinin beyanı ile karşılaştırılır)
create view public.shipment_request_totals_v with (security_invoker = true) as
select r.id as request_id,
       r.company_id,
       count(i.id)                              as item_count,
       coalesce(sum(i.package_count), 0)        as total_packages,
       coalesce(sum(i.total_gross_kg), 0)       as total_gross_kg,
       coalesce(sum(i.total_cbm), 0)            as total_cbm,
       public.calc_chargeable_wm(coalesce(sum(i.total_cbm), 0), coalesce(sum(i.total_gross_kg), 0)) as chargeable_wm_default,
       coalesce(sum(i.goods_value), 0)          as total_goods_value
from public.shipment_requests r
left join public.shipment_items i on i.request_id = r.id
group by r.id, r.company_id;

-- Konsolidasyon ekranı kartları (spec bölüm 6)
create view public.consolidation_summary_v with (security_invoker = true) as
select c.id as consolidation_id,
       c.company_id,
       c.consolidation_no,
       c.status,
       count(ci.id)                                                                  as receipt_count,
       count(distinct wr.supplier_id)                                                as supplier_count,
       coalesce(sum(ci.package_count), 0)                                            as total_packages,
       coalesce(sum(ci.gross_kg), 0)                                                 as total_gross_kg,
       coalesce(sum(ci.cbm), 0)                                                      as total_cbm,
       count(*) filter (where wr.status = 'expected')                                as expected_receipts,
       count(*) filter (where wr.status in ('partially_received', 'received', 'inspected', 'discrepancy', 'ready', 'consolidated')) as arrived_receipts,
       count(*) filter (where wr.status in ('partially_received', 'discrepancy'))    as receipts_with_discrepancy,
       count(*) filter (where wr.status in ('ready', 'consolidated'))                as ready_receipts,
       coalesce(sum(wr.expected_packages), 0) - coalesce(sum(wr.received_packages), 0) as missing_packages,
       coalesce(bool_or(wr.needs_repacking), false)                                  as needs_repacking,
       c.estimated_savings,
       c.planned_schedule_id,
       c.planned_container_id
from public.consolidations c
left join public.consolidation_items ci on ci.consolidation_id = c.id
left join public.warehouse_receipts wr on wr.id = ci.receipt_id
group by c.id;

-- Konteyner doluluk göstergesi (spec bölüm 7)
create view public.container_utilization_v with (security_invoker = true) as
select ct.id as container_id,
       ct.schedule_id,
       ct.container_no,
       ct.container_type,
       ct.status,
       ct.capacity_cbm,
       ct.capacity_kg,
       coalesce(sum(cl.cbm), 0)                     as reserved_cbm,
       coalesce(sum(cl.gross_kg), 0)                as reserved_kg,
       ct.capacity_cbm - coalesce(sum(cl.cbm), 0)   as remaining_cbm,
       case when ct.capacity_cbm > 0 then round(coalesce(sum(cl.cbm), 0) / ct.capacity_cbm * 100, 1) else 0 end as fill_pct_cbm,
       case when ct.capacity_kg  > 0 then round(coalesce(sum(cl.gross_kg), 0) / ct.capacity_kg * 100, 1) else 0 end as fill_pct_kg,
       count(cl.id)                                 as load_count
from public.containers ct
left join public.container_loads cl on cl.container_id = ct.id
group by ct.id;

-- Sefer kapasitesi
create view public.schedule_capacity_v with (security_invoker = true) as
select s.id as schedule_id,
       s.schedule_code,
       s.status,
       s.cut_off_date,
       s.etd,
       s.eta,
       s.capacity_cbm,
       s.capacity_kg,
       coalesce(sum(cl.cbm), 0)                   as reserved_cbm,
       coalesce(sum(cl.gross_kg), 0)              as reserved_kg,
       s.capacity_cbm - coalesce(sum(cl.cbm), 0)  as remaining_cbm,
       case when s.capacity_cbm > 0 then round(coalesce(sum(cl.cbm), 0) / s.capacity_cbm * 100, 1) else 0 end as fill_pct_cbm,
       count(distinct ct.id)                      as container_count,
       count(distinct cl.company_id)              as customer_count
from public.sailing_schedules s
left join public.containers ct on ct.schedule_id = s.id and ct.deleted_at is null
left join public.container_loads cl on cl.container_id = ct.id
group by s.id;

-- Teklif kârlılığı (yalnızca operatör; Faz 2'de RLS ile korunur)
create view public.quotation_profitability_v with (security_invoker = true) as
select q.id as quotation_id,
       q.company_id,
       q.quotation_no,
       q.currency,
       coalesce(sum(i.amount) filter (where i.certainty in ('fixed', 'estimated')), 0) as sales_total,
       coalesce(sum(i.amount) filter (where i.category = 'platform_fee'), 0)           as platform_fee,
       coalesce(sum(c.cost_amount), 0)                                                 as cost_total,
       coalesce(sum(i.amount) filter (where i.certainty in ('fixed', 'estimated')), 0)
         - coalesce(sum(c.cost_amount), 0)                                             as estimated_profit,
       case when coalesce(sum(i.amount) filter (where i.certainty in ('fixed', 'estimated')), 0) > 0
            then round((coalesce(sum(i.amount) filter (where i.certainty in ('fixed', 'estimated')), 0) - coalesce(sum(c.cost_amount), 0))
                       / sum(i.amount) filter (where i.certainty in ('fixed', 'estimated')) * 100, 1)
            else null end                                                              as margin_pct
from public.quotations q
left join public.quotation_items i on i.quotation_id = q.id
left join public.quotation_item_costs c on c.quotation_item_id = i.id
group by q.id;

-- Müşteri bakiyesi (para birimi bazında)
create view public.customer_balance_v with (security_invoker = true) as
select cu.id as customer_id,
       cu.company_id,
       i.currency,
       coalesce(sum(i.total), 0)        as invoiced_total,
       coalesce(sum(i.paid_amount), 0)  as paid_total,
       coalesce(sum(i.balance), 0)      as open_balance,
       coalesce(sum(i.balance) filter (where i.due_date < current_date), 0) as overdue_balance,
       coalesce(sum(i.balance) filter (where i.due_date between current_date and current_date + 7), 0) as due_within_7_days
from public.customers cu
left join public.invoices i
  on i.customer_id = cu.id and i.deleted_at is null and i.status in ('issued', 'partially_paid', 'overdue', 'paid')
group by cu.id, cu.company_id, i.currency;

-- Dosya bazında kâr: teklif maliyeti (tahmini) vs gerçekleşen masraf
create view public.shipment_profit_v with (security_invoker = true) as
select s.id as shipment_id,
       s.company_id,
       s.shipment_no,
       (select coalesce(sum(i.total), 0) from public.invoices i
         where i.shipment_id = s.id and i.deleted_at is null and i.status not in ('draft', 'cancelled')) as invoiced_total,
       (select coalesce(sum(c.cost_amount), 0) from public.quotation_items qi
         join public.quotation_item_costs c on c.quotation_item_id = qi.id
         where qi.quotation_id = s.quotation_id)                                                          as estimated_cost_total,
       (select coalesce(sum(e.amount), 0) from public.expenses e
         where e.shipment_id = s.id and e.deleted_at is null)                                             as actual_cost_total,
       (select coalesce(sum(e.amount), 0) from public.expenses e
         where e.shipment_id = s.id and e.deleted_at is null and e.is_unexpected)                         as unexpected_cost_total
from public.shipments s;

-- ---------------------------------------------------------------------
-- 10) RLS · tüm tablolarda açık, politika yok → istemci anahtarıyla erişim kapalı.
--     Politikalar Faz 2'de eklenir; o zamana kadar yalnızca service role çalışır.
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  for t in
    select table_name from information_schema.tables
    where table_schema = 'public' and table_type = 'BASE TABLE'
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

grant usage on schema app to authenticated, anon, service_role;
