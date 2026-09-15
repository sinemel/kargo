-- =====================================================================
-- ChinaCargo Hub · Faz 1 · 0003
-- Operasyon tabloları: talep → ön kontrol → teklif → depo kabul →
-- konsolidasyon → sefer/konteyner → sevkiyat → evrak → gümrük → teslimat
-- =====================================================================

-- ---------------------------------------------------------------------
-- shipment_requests · Aşama 1: talep (bir talep = bir tedarikçi/yükleme noktası)
-- ---------------------------------------------------------------------
create table public.shipment_requests (
  id                  uuid primary key default gen_random_uuid(),
  request_no          text unique,                         -- TLP-2026-000428 (tetikleyici atar)
  company_id          uuid not null references public.companies (id),
  customer_id         uuid not null references public.customers (id),
  supplier_id         uuid references public.suppliers (id),
  origin_country_code char(2) not null default 'CN',
  origin_city         text,
  pickup_address      text,
  incoterm            incoterm not null default 'EXW',
  delivery_address    text,
  delivery_city       text,
  delivery_district   text,
  requested_mode      transport_mode not null default 'system_suggestion',
  suggested_mode      transport_mode,                      -- sistem/operasyon önerisi
  cargo_ready_date    date,
  goods_value         numeric(14,2),
  currency            currency_code not null default 'USD',
  declared_packages   int,
  declared_gross_kg   numeric(12,3),
  declared_net_kg     numeric(12,3),
  declared_cbm        numeric(12,4),                       -- müşterinin tahmini toplam CBM'i
  is_dangerous        boolean not null default false,
  is_stackable        boolean not null default true,
  is_fragile          boolean not null default false,
  status              request_status not null default 'draft',
  customer_note       text,
  internal_note       text,
  submitted_at        timestamptz,
  shipment_id         uuid,                                -- sevkiyata dönüşünce (FK aşağıda)
  created_by          uuid references public.users (id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- ---------------------------------------------------------------------
-- shipment_items · ürün kalemleri; CBM ve ağırlık generated column
-- ---------------------------------------------------------------------
create table public.shipment_items (
  id                   uuid primary key default gen_random_uuid(),
  request_id           uuid not null references public.shipment_requests (id) on delete cascade,
  company_id           uuid not null references public.companies (id),
  line_no              int not null default 1,
  description          text not null,
  hs_code_estimated    text,                                -- tahmini GTİP
  package_type         package_type not null default 'carton',
  package_count        int not null check (package_count > 0),
  length_cm            numeric(8,2) not null check (length_cm > 0),
  width_cm             numeric(8,2) not null check (width_cm > 0),
  height_cm            numeric(8,2) not null check (height_cm > 0),
  gross_kg_per_package numeric(10,3) not null check (gross_kg_per_package >= 0),
  net_kg_per_package   numeric(10,3),
  unit_cbm             numeric(12,4) generated always as (round(length_cm * width_cm * height_cm / 1000000.0, 4)) stored,
  total_cbm            numeric(12,4) generated always as (round(length_cm * width_cm * height_cm / 1000000.0 * package_count, 4)) stored,
  total_gross_kg       numeric(12,3) generated always as (round(gross_kg_per_package * package_count, 3)) stored,
  goods_value          numeric(14,2),
  currency             currency_code not null default 'USD',
  is_dangerous         boolean not null default false,
  is_stackable         boolean not null default true,
  is_fragile           boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  unique (request_id, line_no)
);

-- ---------------------------------------------------------------------
-- precheck_flags · Aşama 2: otomatik/manuel risk uyarıları (hukuki karar değildir)
-- ---------------------------------------------------------------------
create table public.precheck_flags (
  id              uuid primary key default gen_random_uuid(),
  request_id      uuid not null references public.shipment_requests (id) on delete cascade,
  item_id         uuid references public.shipment_items (id) on delete cascade,
  company_id      uuid not null references public.companies (id),
  flag_type       risk_flag_type not null,
  severity        severity_level not null default 'warning',
  message_tr      text not null,
  source          text not null default 'auto' check (source in ('auto', 'manual')),
  resolved_at     timestamptz,
  resolved_by     uuid references public.users (id),
  resolution_note text,
  created_by      uuid references public.users (id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- quotations · Aşama 3: ayrıntılı teklif (bir teklif birden fazla talebi kapsayabilir)
-- ---------------------------------------------------------------------
create table public.quotations (
  id                        uuid primary key default gen_random_uuid(),
  quotation_no              text unique,                   -- TKL-2026-00128
  version                   int not null default 1,
  previous_version_id       uuid references public.quotations (id),
  company_id                uuid not null references public.companies (id),
  customer_id               uuid not null references public.customers (id),
  consolidation_id          uuid,                          -- FK aşağıda
  status                    quotation_status not null default 'draft',
  transport_mode            transport_mode not null,
  incoterm                  incoterm not null default 'EXW',
  currency                  currency_code not null default 'USD',
  exchange_rates            jsonb not null default '{}'::jsonb,   -- {"USD_TRY": 41.38, "rate_date": "2026-08-22", "source": "TCMB"}
  quote_date                date not null default current_date,
  valid_until               date not null,
  transit_days_min          int,
  transit_days_max          int,
  planned_departure_date    date,
  estimated_arrival_date    date,
  chargeable_wm             numeric(12,4),
  chargeable_kg             numeric(12,3),
  included_services         text[] not null default '{}',
  excluded_services         text[] not null default '{}',
  special_terms             text,
  payment_plan              text,
  cancellation_terms        text,
  delay_force_majeure_terms text,
  subtotal                  numeric(14,2) not null default 0,     -- kesin + tahmini kalemler (tetikleyici hesaplar)
  total                     numeric(14,2) not null default 0,
  prepared_by               uuid references public.users (id),
  sent_at                   timestamptz,
  approved_at               timestamptz,
  approved_by               uuid references public.users (id),
  rejected_at               timestamptz,
  customer_response_note    text,
  internal_note             text,
  created_by                uuid references public.users (id),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  deleted_at                timestamptz,
  check (valid_until >= quote_date),
  check (transit_days_max is null or transit_days_min is null or transit_days_max >= transit_days_min)
);

create table public.quotation_requests (
  quotation_id uuid not null references public.quotations (id) on delete cascade,
  request_id   uuid not null references public.shipment_requests (id) on delete cascade,
  primary key (quotation_id, request_id)
);

-- Müşterinin gördüğü satış kalemleri
create table public.quotation_items (
  id             uuid primary key default gen_random_uuid(),
  quotation_id   uuid not null references public.quotations (id) on delete cascade,
  company_id     uuid not null references public.companies (id),
  sort_order     int not null default 0,
  category       cost_category not null,
  description_tr text not null,
  certainty      cost_certainty not null default 'estimated',
  quantity       numeric(12,4) not null default 1,
  unit           text not null default 'shipment'
                 check (unit in ('shipment', 'wm', 'cbm', 'kg', 'package', 'pallet', 'hbl', 'pct', 'flat')),
  unit_price     numeric(14,4) not null default 0,
  amount         numeric(14,2) not null default 0,
  currency       currency_code not null default 'USD',
  note           text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- Yalnızca operatörün gördüğü alış maliyeti (hassas finansal alan, ayrı tablo)
create table public.quotation_item_costs (
  quotation_item_id uuid primary key references public.quotation_items (id) on delete cascade,
  company_id        uuid not null references public.companies (id),
  cost_amount       numeric(14,2) not null default 0,
  cost_currency     currency_code not null default 'USD',
  vendor_type       vendor_type,
  vendor_note       text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- warehouse_receipts · Çin depo kabulü; depo teslim kodu CC-IST-2026-00428-S01
-- ---------------------------------------------------------------------
create table public.warehouse_receipts (
  id                    uuid primary key default gen_random_uuid(),
  receipt_no            text unique,                       -- DPK-2026-00311
  delivery_code         text unique,                       -- CC-IST-2026-00428-S01 (tetikleyici atar)
  company_id            uuid not null references public.companies (id),
  customer_id           uuid not null references public.customers (id),
  request_id            uuid references public.shipment_requests (id),
  supplier_id           uuid references public.suppliers (id),
  warehouse_id          uuid not null references public.warehouses (id),
  consolidation_id      uuid,                              -- FK aşağıda
  status                receipt_status not null default 'expected',
  expected_arrival_date date,
  expected_packages     int,
  received_packages     int not null default 0,
  expected_gross_kg     numeric(12,3),
  actual_gross_kg       numeric(12,3),
  expected_cbm          numeric(12,4),
  actual_cbm            numeric(12,4),
  packaging_condition   text check (packaging_condition in ('good', 'acceptable', 'poor')),
  damage_status         damage_status not null default 'none',
  needs_repacking       boolean not null default false,
  needs_palletizing     boolean not null default false,
  repacked_at           timestamptz,
  palletized_at         timestamptz,
  location_id           uuid references public.warehouse_locations (id),
  received_by           uuid references public.users (id),
  received_at           timestamptz,
  ready_at              timestamptz,
  warehouse_note        text,
  created_by            uuid references public.users (id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  deleted_at            timestamptz
);

-- ---------------------------------------------------------------------
-- packages · tek tek koli/palet; QR kod = <teslim kodu>-Pnnn
-- ---------------------------------------------------------------------
create table public.packages (
  id            uuid primary key default gen_random_uuid(),
  company_id    uuid not null references public.companies (id),
  receipt_id    uuid not null references public.warehouse_receipts (id) on delete cascade,
  item_id       uuid references public.shipment_items (id),
  package_no    int not null,
  qr_code       text unique,
  package_type  package_type not null default 'carton',
  length_cm     numeric(8,2),
  width_cm      numeric(8,2),
  height_cm     numeric(8,2),
  gross_kg      numeric(10,3),
  cbm           numeric(12,4) generated always as
                (round(coalesce(length_cm, 0) * coalesce(width_cm, 0) * coalesce(height_cm, 0) / 1000000.0, 4)) stored,
  status        package_status not null default 'expected',
  damage_status damage_status not null default 'none',
  location_id   uuid references public.warehouse_locations (id),
  note          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (receipt_id, package_no)
);

-- ---------------------------------------------------------------------
-- inspections · ölçüm/tartım/hasar/eksik kayıtları (kabul veya koli düzeyinde)
-- ---------------------------------------------------------------------
create table public.inspections (
  id                 uuid primary key default gen_random_uuid(),
  company_id         uuid not null references public.companies (id),
  receipt_id         uuid not null references public.warehouse_receipts (id) on delete cascade,
  package_id         uuid references public.packages (id),
  inspected_by       uuid references public.users (id),
  inspected_at       timestamptz not null default now(),
  package_count      int,
  length_cm          numeric(8,2),
  width_cm           numeric(8,2),
  height_cm          numeric(8,2),
  gross_kg           numeric(10,3),
  measured_cbm       numeric(12,4),
  has_damage         boolean not null default false,
  damage_status      damage_status not null default 'none',
  damage_description text,
  is_missing         boolean not null default false,
  missing_count      int not null default 0,
  was_repacked       boolean not null default false,
  was_palletized     boolean not null default false,
  note               text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- media_assets · depo fotoğraf/video (resmî evraktan ayrı)
-- ---------------------------------------------------------------------
create table public.media_assets (
  id                  uuid primary key default gen_random_uuid(),
  company_id          uuid not null references public.companies (id),
  entity_type         entity_type not null,
  entity_id           uuid not null,
  media_type          media_type not null default 'photo',
  storage_bucket      text not null default 'media',
  storage_path        text not null,                      -- <company_id>/<entity_type>/<entity_id>/<dosya>
  file_name           text,
  mime_type           text,
  file_size_bytes     bigint,
  caption             text,
  taken_at            timestamptz,
  is_customer_visible boolean not null default true,
  uploaded_by         uuid references public.users (id),
  created_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

-- ---------------------------------------------------------------------
-- consolidations · aynı müşterinin farklı tedarikçi yüklerinin birleştirilmesi
-- (toplamlar consolidation_summary_v view'ından okunur)
-- ---------------------------------------------------------------------
create table public.consolidations (
  id                   uuid primary key default gen_random_uuid(),
  consolidation_no     text unique,                        -- KNS-2026-00042
  company_id           uuid not null references public.companies (id),
  customer_id          uuid not null references public.customers (id),
  warehouse_id         uuid not null references public.warehouses (id),
  status               consolidation_status not null default 'open',
  target_mode          transport_mode not null default 'sea_lcl',
  planned_schedule_id  uuid,                               -- FK aşağıda
  planned_container_id uuid,                               -- FK aşağıda
  needs_repacking      boolean not null default false,
  estimated_savings    numeric(14,2),                      -- ayrı ayrı göndermeye göre tahmini tasarruf
  savings_currency     currency_code default 'USD',
  ready_at             timestamptz,
  closed_at            timestamptz,
  note                 text,
  created_by           uuid references public.users (id),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  deleted_at           timestamptz
);

create table public.consolidation_items (
  id               uuid primary key default gen_random_uuid(),
  consolidation_id uuid not null references public.consolidations (id) on delete cascade,
  receipt_id       uuid not null unique references public.warehouse_receipts (id),
  company_id       uuid not null references public.companies (id),
  package_count    int not null default 0,
  gross_kg         numeric(12,3) not null default 0,
  cbm              numeric(12,4) not null default 0,
  note             text,
  created_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- sailing_schedules / containers / container_loads · sefer ve konteyner yönetimi
-- ---------------------------------------------------------------------
create table public.sailing_schedules (
  id                    uuid primary key default gen_random_uuid(),
  schedule_code         text unique,                       -- SEF-2026-00038
  transport_mode        transport_mode not null default 'sea_lcl',
  origin_warehouse_id   uuid references public.warehouses (id),
  origin_port           text not null,                     -- Shanghai
  origin_port_code      text,                              -- CNSHA
  destination_port      text not null,                     -- Ambarlı
  destination_port_code text,                              -- TRAMR
  carrier_id            uuid references public.carriers (id),
  vessel_name           text,
  voyage_no             text,
  cut_off_date          date,
  doc_cut_off_date      date,
  etd                   date,
  eta                   date,
  atd                   date,
  ata                   date,
  capacity_cbm          numeric(12,3),
  capacity_kg           numeric(12,3),
  status                schedule_status not null default 'planned',
  note                  text,
  created_by            uuid references public.users (id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  deleted_at            timestamptz
);

create table public.containers (
  id             uuid primary key default gen_random_uuid(),
  schedule_id    uuid not null references public.sailing_schedules (id),
  container_no   text check (container_no is null or container_no ~ '^[A-Z]{4}[0-9]{7}$'),  -- ISO 6346
  container_type container_type not null default '40HC',
  seal_no        text,
  mbl_no         text,
  capacity_cbm   numeric(12,3) not null default 68,
  capacity_kg    numeric(12,3) not null default 26000,
  status         container_status not null default 'planned',
  loaded_at      timestamptz,
  unpacked_at    timestamptz,
  note           text,
  created_by     uuid references public.users (id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

create table public.container_loads (
  id               uuid primary key default gen_random_uuid(),
  container_id     uuid not null references public.containers (id),
  consolidation_id uuid references public.consolidations (id),
  shipment_id      uuid,                                   -- FK aşağıda
  company_id       uuid not null references public.companies (id),
  hbl_no           text,
  package_count    int not null default 0,
  gross_kg         numeric(12,3) not null default 0,
  cbm              numeric(12,4) not null default 0,
  loaded_at        timestamptz,
  position_note    text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- shipments / shipment_milestones · sevkiyat dosyası ve 21 adımlık zaman çizelgesi
-- ---------------------------------------------------------------------
create table public.shipments (
  id                     uuid primary key default gen_random_uuid(),
  shipment_no            text unique,                      -- SVK-2026-00428
  company_id             uuid not null references public.companies (id),
  customer_id            uuid not null references public.customers (id),
  quotation_id           uuid references public.quotations (id),
  consolidation_id       uuid references public.consolidations (id),
  schedule_id            uuid references public.sailing_schedules (id),
  container_id           uuid references public.containers (id),
  hbl_no                 text,
  transport_mode         transport_mode not null,
  incoterm               incoterm not null default 'EXW',
  status                 shipment_status not null default 'active',
  current_milestone_code text references public.milestone_types (code),
  current_milestone_at   timestamptz,
  origin_port            text,
  destination_port       text,
  etd                    date,
  eta                    date,
  atd                    date,
  ata                    date,
  total_packages         int,
  total_gross_kg         numeric(12,3),
  total_cbm              numeric(12,4),
  chargeable_wm          numeric(12,4),
  delivery_address       text,
  delivery_city          text,
  delivery_district      text,
  insured_value          numeric(14,2),
  insurance_currency     currency_code,
  is_delayed             boolean not null default false,
  delay_reason           text,
  delivered_at           timestamptz,
  created_by             uuid references public.users (id),
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz
);

create table public.shipment_milestones (
  id                  uuid primary key default gen_random_uuid(),
  shipment_id         uuid not null references public.shipments (id) on delete cascade,
  company_id          uuid not null references public.companies (id),
  milestone_code      text not null references public.milestone_types (code),
  occurred_at         timestamptz not null default now(),
  recorded_by         uuid references public.users (id),
  description         text,
  location            text,
  document_id         uuid,                                -- FK aşağıda
  media_id            uuid references public.media_assets (id),
  next_expected_at    timestamptz,
  next_expected_note  text,
  is_customer_visible boolean not null default true,
  created_at          timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- documents / document_requirements · sürümlü evrak dosyası ve eksik evrak uyarısı
-- ---------------------------------------------------------------------
create table public.documents (
  id                     uuid primary key default gen_random_uuid(),
  company_id             uuid not null references public.companies (id),
  entity_type            entity_type not null,
  entity_id              uuid not null,
  document_type          document_type not null,
  title                  text not null,
  storage_bucket         text not null default 'documents',
  storage_path           text not null,                    -- <company_id>/<entity_type>/<entity_id>/<dosya>
  file_name              text not null,
  mime_type              text,
  file_size_bytes        bigint,
  version                int not null default 1,
  supersedes_document_id uuid references public.documents (id),
  status                 document_status not null default 'pending_review',
  is_customer_visible    boolean not null default true,
  uploaded_by            uuid references public.users (id),
  reviewed_by            uuid references public.users (id),
  reviewed_at            timestamptz,
  note                   text,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz
);

create table public.document_requirements (
  id                    uuid primary key default gen_random_uuid(),
  company_id            uuid not null references public.companies (id),
  entity_type           entity_type not null,
  entity_id             uuid not null,
  document_type         document_type not null,
  is_required           boolean not null default true,
  due_date              date,
  fulfilled_document_id uuid references public.documents (id),
  requested_by          uuid references public.users (id),
  note                  text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  unique (entity_type, entity_id, document_type)
);

-- ---------------------------------------------------------------------
-- customs_files · gümrük dosyası; çözüm ortağına atanır
-- ---------------------------------------------------------------------
create table public.customs_files (
  id                      uuid primary key default gen_random_uuid(),
  customs_file_no         text unique,                     -- GMR-2026-00214
  company_id              uuid not null references public.companies (id),
  shipment_id             uuid not null references public.shipments (id),
  partner_company_id      uuid references public.companies (id),
  assigned_to             uuid references public.users (id),
  status                  customs_status not null default 'pending_assignment',
  hs_code_proposed        text,
  hs_code_final           text,
  regulation_note         text,
  estimated_customs_duty  numeric(14,2),
  estimated_vat           numeric(14,2),
  estimated_other_charges numeric(14,2),
  estimate_currency       currency_code not null default 'TRY',
  declaration_no          text,
  declaration_date        date,
  lane                    inspection_lane,                 -- yeşil/mavi/sarı/kırmızı hat
  missing_documents_note  text,
  cleared_at              timestamptz,
  released_at             timestamptz,
  created_by              uuid references public.users (id),
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz
);

-- ---------------------------------------------------------------------
-- delivery_orders · Türkiye içi dağıtım ve teslim belgesi
-- ---------------------------------------------------------------------
create table public.delivery_orders (
  id                uuid primary key default gen_random_uuid(),
  delivery_no       text unique,                           -- TSL-2026-00187
  company_id        uuid not null references public.companies (id),
  shipment_id       uuid not null references public.shipments (id),
  requested_by      uuid references public.users (id),
  status            delivery_status not null default 'requested',
  delivery_address  text not null,
  delivery_city     text,
  delivery_district text,
  contact_name      text,
  contact_phone     text,
  requested_date    date,
  planned_date      date,
  time_window       text,
  vehicle_type      text,
  carrier_id        uuid references public.carriers (id),
  driver_name       text,
  vehicle_plate     text,
  package_count     int,
  gross_kg          numeric(12,3),
  cbm               numeric(12,4),
  dispatched_at     timestamptz,
  delivered_at      timestamptz,
  received_by_name  text,
  pod_document_id   uuid references public.documents (id), -- teslim belgesi
  note              text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz
);

-- ---------------------------------------------------------------------
-- Döngüsel yabancı anahtarlar
-- ---------------------------------------------------------------------
alter table public.shipment_requests   add constraint shipment_requests_shipment_fk        foreign key (shipment_id)          references public.shipments (id);
alter table public.quotations          add constraint quotations_consolidation_fk          foreign key (consolidation_id)     references public.consolidations (id);
alter table public.warehouse_receipts  add constraint warehouse_receipts_consolidation_fk  foreign key (consolidation_id)     references public.consolidations (id);
alter table public.consolidations      add constraint consolidations_schedule_fk           foreign key (planned_schedule_id)  references public.sailing_schedules (id);
alter table public.consolidations      add constraint consolidations_container_fk          foreign key (planned_container_id) references public.containers (id);
alter table public.container_loads     add constraint container_loads_shipment_fk          foreign key (shipment_id)          references public.shipments (id);
alter table public.shipment_milestones add constraint shipment_milestones_document_fk      foreign key (document_id)          references public.documents (id);

-- ---------------------------------------------------------------------
-- İndeksler
-- ---------------------------------------------------------------------
create index on public.shipment_requests (company_id, status);
create index on public.shipment_requests (customer_id);
create index on public.shipment_requests (supplier_id);
create index on public.shipment_items (request_id);
create index on public.precheck_flags (request_id);
create index on public.quotations (company_id, status);
create index on public.quotation_items (quotation_id);
create index on public.warehouse_receipts (company_id, status);
create index on public.warehouse_receipts (warehouse_id, status);
create index on public.warehouse_receipts (request_id);
create index on public.warehouse_receipts (consolidation_id);
create index on public.packages (receipt_id);
create index on public.inspections (receipt_id);
create index on public.media_assets (entity_type, entity_id);
create index on public.consolidations (company_id, status);
create index on public.consolidation_items (consolidation_id);
create index on public.sailing_schedules (status, etd);
create index on public.containers (schedule_id);
create index on public.container_loads (container_id);
create index on public.container_loads (company_id);
create index on public.shipments (company_id, status);
create index on public.shipments (schedule_id);
create index on public.shipment_milestones (shipment_id, occurred_at);
create index on public.documents (entity_type, entity_id);
create index on public.documents (company_id, document_type);
create index on public.document_requirements (entity_type, entity_id);
create index on public.customs_files (partner_company_id, status);
create index on public.customs_files (shipment_id);
create index on public.delivery_orders (shipment_id);
