-- =====================================================================
-- ChinaCargo Hub · Faz 1 · 0004
-- Finans ve iletişim: fatura, ödeme, masraf, kur, destek, mesaj,
-- bildirim, webhook, işlem kaydı
-- =====================================================================

-- ---------------------------------------------------------------------
-- invoices / invoice_items · müşteriye kesilen faturalar
-- ---------------------------------------------------------------------
create table public.invoices (
  id                  uuid primary key default gen_random_uuid(),
  invoice_no          text unique,                         -- FTR-2026-00097
  company_id          uuid not null references public.companies (id),
  customer_id         uuid not null references public.customers (id),
  shipment_id         uuid references public.shipments (id),
  quotation_id        uuid references public.quotations (id),
  invoice_type        invoice_type not null default 'service',
  status              invoice_status not null default 'draft',
  currency            currency_code not null default 'USD',
  exchange_rate_try   numeric(12,4),                       -- fatura tarihindeki kur
  subtotal            numeric(14,2) not null default 0,
  vat_rate            numeric(5,2) not null default 0,
  vat_amount          numeric(14,2) not null default 0,
  total               numeric(14,2) not null default 0,
  paid_amount         numeric(14,2) not null default 0,
  balance             numeric(14,2) generated always as (total - paid_amount) stored,
  issue_date          date not null default current_date,
  due_date            date,
  external_invoice_no text,                                -- e-Fatura/e-Arşiv numarası (sonraki faz)
  note                text,
  created_by          uuid references public.users (id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

create table public.invoice_items (
  id                uuid primary key default gen_random_uuid(),
  invoice_id        uuid not null references public.invoices (id) on delete cascade,
  company_id        uuid not null references public.companies (id),
  quotation_item_id uuid references public.quotation_items (id),
  sort_order        int not null default 0,
  category          cost_category not null default 'other',
  description_tr    text not null,
  quantity          numeric(12,4) not null default 1,
  unit_price        numeric(14,4) not null default 0,
  amount            numeric(14,2) not null default 0,
  created_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- payments · ödeme bekleniyor → bildirildi → kontrol edildi → ödendi
-- ---------------------------------------------------------------------
create table public.payments (
  id                  uuid primary key default gen_random_uuid(),
  payment_no          text unique,                         -- ODM-2026-00071
  company_id          uuid not null references public.companies (id),
  customer_id         uuid not null references public.customers (id),
  invoice_id          uuid references public.invoices (id),
  shipment_id         uuid references public.shipments (id),
  amount              numeric(14,2) not null check (amount > 0),
  currency            currency_code not null default 'USD',
  exchange_rate_try   numeric(12,4),
  method              payment_method not null default 'bank_transfer',
  status              payment_status not null default 'pending',
  reference_no        text,
  reported_by         uuid references public.users (id),
  reported_at         timestamptz,
  verified_by         uuid references public.users (id),
  verified_at         timestamptz,
  paid_at             timestamptz,
  receipt_document_id uuid references public.documents (id),   -- dekont
  note                text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- ---------------------------------------------------------------------
-- expenses · gerçekleşen maliyetler (yalnızca operatör görür); tedarikçi/taşıyıcı borçları
-- ---------------------------------------------------------------------
create table public.expenses (
  id                  uuid primary key default gen_random_uuid(),
  expense_no          text unique,                         -- MSR-2026-00312
  company_id          uuid not null references public.companies (id),   -- müşteri dosyası; sefer geneli ise operatör şirketi
  shipment_id         uuid references public.shipments (id),
  consolidation_id    uuid references public.consolidations (id),
  schedule_id         uuid references public.sailing_schedules (id),
  container_id        uuid references public.containers (id),
  category            cost_category not null,
  description         text not null,
  vendor_type         vendor_type not null default 'other',
  vendor_carrier_id   uuid references public.carriers (id),
  vendor_company_id   uuid references public.companies (id),
  vendor_supplier_id  uuid references public.suppliers (id),
  amount              numeric(14,2) not null,
  currency            currency_code not null default 'USD',
  exchange_rate_try   numeric(12,4),
  amount_try          numeric(14,2),
  expense_date        date not null default current_date,
  is_unexpected       boolean not null default false,      -- beklenmeyen ek masraf
  is_rebillable       boolean not null default false,      -- müşteriye yansıtılacak
  rebilled_invoice_id uuid references public.invoices (id),
  payable_status      payable_status not null default 'unpaid',
  payable_due_date    date,
  paid_at             timestamptz,
  document_id         uuid references public.documents (id),
  recorded_by         uuid references public.users (id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- ---------------------------------------------------------------------
-- exchange_rates · kur farkı raporları için tarihli kurlar (ilk sürümde manuel)
-- ---------------------------------------------------------------------
create table public.exchange_rates (
  id             uuid primary key default gen_random_uuid(),
  rate_date      date not null,
  base_currency  currency_code not null,
  quote_currency currency_code not null,
  rate           numeric(14,6) not null check (rate > 0),
  source         text not null default 'manual',
  created_by     uuid references public.users (id),
  created_at     timestamptz not null default now(),
  unique (rate_date, base_currency, quote_currency)
);

-- ---------------------------------------------------------------------
-- support_tickets / messages / message_reads
-- ---------------------------------------------------------------------
create table public.support_tickets (
  id                 uuid primary key default gen_random_uuid(),
  ticket_no          text unique,                          -- DST-2026-00056
  company_id         uuid not null references public.companies (id),
  shipment_id        uuid references public.shipments (id),
  request_id         uuid references public.shipment_requests (id),
  category           message_type not null default 'general',
  subject            text not null,
  status             ticket_status not null default 'open',
  priority           priority_level not null default 'normal',
  created_by         uuid references public.users (id),
  assigned_to        uuid references public.users (id),
  partner_company_id uuid references public.companies (id),
  first_response_at  timestamptz,
  resolved_at        timestamptz,
  closed_at          timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz
);

create table public.messages (
  id           uuid primary key default gen_random_uuid(),
  company_id   uuid not null references public.companies (id),
  shipment_id  uuid references public.shipments (id),
  request_id   uuid references public.shipment_requests (id),
  ticket_id    uuid references public.support_tickets (id),
  message_type message_type not null default 'general',
  sender_id    uuid not null references public.users (id),
  body         text not null,
  attachments  jsonb not null default '[]'::jsonb,         -- [{"document_id": "..."}, {"media_id": "..."}]
  is_internal  boolean not null default false,             -- yalnızca operatör ekibi görür
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  check (shipment_id is not null or request_id is not null or ticket_id is not null)
);

create table public.message_reads (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id    uuid not null references public.users (id) on delete cascade,
  read_at    timestamptz not null default now(),
  primary key (message_id, user_id)
);

-- ---------------------------------------------------------------------
-- notifications · uygulama içi / e-posta / WhatsApp (webhook) bildirim kuyruğu
-- ---------------------------------------------------------------------
create table public.notifications (
  id              uuid primary key default gen_random_uuid(),
  company_id      uuid references public.companies (id),
  user_id         uuid not null references public.users (id) on delete cascade,
  event_key       text not null,                           -- shipment.milestone.vessel_departed
  title_tr        text not null,
  body_tr         text,
  entity_type     entity_type,
  entity_id       uuid,
  channel         notification_channel not null default 'in_app',
  is_read         boolean not null default false,
  read_at         timestamptz,
  sent_at         timestamptz,
  delivery_status text not null default 'queued' check (delivery_status in ('queued', 'sent', 'failed', 'skipped')),
  payload         jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- webhook_endpoints / webhook_deliveries · WhatsApp vb. entegrasyona hazır çıkış noktası
-- ---------------------------------------------------------------------
create table public.webhook_endpoints (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  target_url text not null,
  secret     text not null,                                -- imza için (uygulama katmanında HMAC)
  events     text[] not null default '{}',                 -- ['shipment.milestone.*', 'quotation.sent']
  channel    notification_channel not null default 'whatsapp',
  is_active  boolean not null default true,
  created_by uuid references public.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.webhook_deliveries (
  id              uuid primary key default gen_random_uuid(),
  endpoint_id     uuid not null references public.webhook_endpoints (id) on delete cascade,
  event_key       text not null,
  payload         jsonb not null,
  status          text not null default 'pending' check (status in ('pending', 'delivered', 'failed')),
  attempts        int not null default 0,
  last_attempt_at timestamptz,
  response_status int,
  last_error      text,
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- activity_logs · kritik tablolarda otomatik işlem kaydı
-- ---------------------------------------------------------------------
create table public.activity_logs (
  id             bigint generated always as identity primary key,
  company_id     uuid references public.companies (id),
  user_id        uuid references public.users (id),
  action         text not null,                            -- insert / update / delete / login / status_change
  entity_type    text not null,
  entity_id      uuid,
  before_data    jsonb,
  after_data     jsonb,
  changed_fields text[],
  ip_address     inet,
  user_agent     text,
  created_at     timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- İndeksler
-- ---------------------------------------------------------------------
create index on public.invoices (company_id, status);
create index on public.invoices (customer_id, due_date);
create index on public.invoice_items (invoice_id);
create index on public.payments (company_id, status);
create index on public.payments (invoice_id);
create index on public.expenses (company_id, category);
create index on public.expenses (shipment_id);
create index on public.expenses (schedule_id);
create index on public.expenses (payable_status) where payable_status = 'unpaid';
create index on public.support_tickets (company_id, status);
create index on public.messages (shipment_id, created_at);
create index on public.messages (ticket_id, created_at);
create index on public.notifications (user_id, is_read, created_at desc);
create index on public.webhook_deliveries (status, created_at);
create index on public.activity_logs (entity_type, entity_id);
create index on public.activity_logs (company_id, created_at desc);
create index on public.activity_logs (user_id, created_at desc);
