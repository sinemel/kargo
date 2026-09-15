-- =====================================================================
-- ChinaCargo Hub · Faz 1 · 0002
-- Çekirdek tablolar: kullanıcı, şirket, rol/izin, müşteri, tedarikçi,
-- depo, taşıyıcı, fiyat kuralı, sistem ayarı, milestone tipleri, KVKK
-- =====================================================================

-- ---------------------------------------------------------------------
-- Ortak yardımcılar
-- ---------------------------------------------------------------------
create or replace function app.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- ---------------------------------------------------------------------
-- users · auth.users ile 1:1 profil
-- ---------------------------------------------------------------------
create table public.users (
  id            uuid primary key references auth.users (id) on delete cascade,
  email         text not null unique,
  full_name     text not null collate public.tr_tr,
  phone         text,
  avatar_url    text,
  locale        text not null default 'tr' check (locale in ('tr', 'en', 'zh')),
  is_active     boolean not null default true,
  last_login_at timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
comment on table public.users is 'Uygulama profili; kimlik doğrulama auth.users üzerinde (Faz 2).';

-- ---------------------------------------------------------------------
-- companies · çok kiracılı yapı: operator (platform), customer, partner
-- ---------------------------------------------------------------------
create table public.companies (
  id                    uuid primary key default gen_random_uuid(),
  type                  company_type not null,
  legal_name            text not null collate public.tr_tr,
  trade_name            text collate public.tr_tr,
  tax_number            text,
  tax_office            text,
  country_code          char(2) not null default 'TR',
  city                  text,
  district              text,
  address               text,
  phone                 text,
  email                 text,
  website               text,
  default_currency      currency_code not null default 'USD',
  kvkk_consent_at       timestamptz,
  kvkk_consent_version  text,
  is_active             boolean not null default true,
  status                text not null default 'active' check (status in ('pending', 'active', 'suspended', 'closed')),
  created_by            uuid references public.users (id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  deleted_at            timestamptz
);
create unique index companies_tax_number_uq on public.companies (tax_number)
  where tax_number is not null and deleted_at is null;

-- ---------------------------------------------------------------------
-- roles / permissions / role_permissions
-- ---------------------------------------------------------------------
create table public.roles (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name_tr     text not null,
  description text,
  scope       company_type not null,     -- rol hangi şirket türünde kullanılabilir
  is_system   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table public.permissions (
  id         uuid primary key default gen_random_uuid(),
  module     text not null,
  code       text not null unique,       -- örn. quotations.approve
  name_tr    text not null,
  created_at timestamptz not null default now()
);

create table public.role_permissions (
  role_id       uuid not null references public.roles (id) on delete cascade,
  permission_id uuid not null references public.permissions (id) on delete cascade,
  primary key (role_id, permission_id)
);

-- ---------------------------------------------------------------------
-- company_users · kullanıcı ↔ şirket ↔ rol
-- ---------------------------------------------------------------------
create table public.company_users (
  id                 uuid primary key default gen_random_uuid(),
  company_id         uuid not null references public.companies (id) on delete cascade,
  user_id            uuid not null references public.users (id) on delete cascade,
  role_id            uuid not null references public.roles (id),
  title              text,
  is_primary_contact boolean not null default false,
  status             member_status not null default 'active',
  invited_by         uuid references public.users (id),
  invited_at         timestamptz,
  accepted_at        timestamptz,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),
  unique (company_id, user_id)
);
create index company_users_user_idx on public.company_users (user_id, status);

-- ---------------------------------------------------------------------
-- customers · müşteri şirketinin ticari profili (operatör yönetir)
-- ---------------------------------------------------------------------
create table public.customers (
  id                        uuid primary key default gen_random_uuid(),
  company_id                uuid not null unique references public.companies (id),
  customer_code             text not null unique check (customer_code ~ '^[0-9]{5}$'),  -- 00428
  segment                   text check (segment in ('kobi', 'toptanci', 'kurumsal', 'ilk_ithalat', 'diger')),
  trade_center              text,                          -- İstoç, İkitelli, Güneşli, Masko...
  account_manager_id        uuid references public.users (id),
  payment_terms_days        int not null default 0,
  credit_limit              numeric(14,2),
  credit_currency           currency_code,
  default_delivery_address  text,
  default_delivery_city     text,
  default_delivery_district text,
  risk_level                text not null default 'normal' check (risk_level in ('low', 'normal', 'high')),
  notes                     text,
  status                    text not null default 'active' check (status in ('active', 'on_hold', 'closed')),
  created_by                uuid references public.users (id),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now(),
  deleted_at                timestamptz
);

-- ---------------------------------------------------------------------
-- suppliers · müşteriye ait Çinli tedarikçiler
-- ---------------------------------------------------------------------
create table public.suppliers (
  id               uuid primary key default gen_random_uuid(),
  company_id       uuid not null references public.companies (id),   -- sahibi müşteri şirketi
  name             text not null,
  contact_name     text,
  phone            text,
  email            text,
  wechat           text,
  country_code     char(2) not null default 'CN',
  province         text,
  city             text,
  address          text,
  address_type     text not null default 'factory' check (address_type in ('factory', 'warehouse', 'office')),
  default_incoterm incoterm not null default 'EXW',
  products_summary text,
  rating           smallint check (rating between 1 and 5),
  notes            text,
  is_active        boolean not null default true,
  status           text not null default 'active' check (status in ('active', 'inactive', 'blacklisted')),
  created_by       uuid references public.users (id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);
create unique index suppliers_company_name_uq on public.suppliers (company_id, lower(name)) where deleted_at is null;

-- ---------------------------------------------------------------------
-- warehouses / warehouse_locations · Çin toplama depoları
-- ---------------------------------------------------------------------
create table public.warehouses (
  id              uuid primary key default gen_random_uuid(),
  code            text not null unique,          -- CN-SHA
  name            text not null,
  country_code    char(2) not null default 'CN',
  city            text not null,
  address         text,
  contact_name    text,
  contact_phone   text,
  contact_email   text,
  timezone        text not null default 'Asia/Shanghai',
  receiving_hours text,
  is_public       boolean not null default true,  -- herkese açık "Çin depo noktaları" sayfası
  is_active       boolean not null default true,
  status          text not null default 'active' check (status in ('active', 'inactive')),
  created_by      uuid references public.users (id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

create table public.warehouse_locations (
  id           uuid primary key default gen_random_uuid(),
  warehouse_id uuid not null references public.warehouses (id) on delete cascade,
  code         text not null,                      -- A-01, P-01
  zone         text,
  rack         text,
  level        text,
  capacity_cbm numeric(10,3),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (warehouse_id, code)
);

-- ---------------------------------------------------------------------
-- carriers · taşıyıcı ve acenteler (kullanıcı değil, kayıt)
-- ---------------------------------------------------------------------
create table public.carriers (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  carrier_type  carrier_type not null,
  scac          text,
  contact_name  text,
  contact_phone text,
  contact_email text,
  notes         text,
  is_active     boolean not null default true,
  status        text not null default 'active' check (status in ('active', 'inactive')),
  created_by    uuid references public.users (id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

-- ---------------------------------------------------------------------
-- pricing_rules · W/M oranı ve hacimsel ağırlık böleni (mod + taşıyıcı bazında)
-- ---------------------------------------------------------------------
create table public.pricing_rules (
  id                  uuid primary key default gen_random_uuid(),
  transport_mode      transport_mode not null,
  carrier_id          uuid references public.carriers (id),   -- null = modun genel kuralı
  wm_kg_per_cbm       numeric(10,3),                          -- deniz/demiryolu: 1 CBM = X kg (varsayılan 1000)
  volumetric_divisor  numeric(10,3),                          -- hava/ekspres: En×Boy×Yükseklik / bölen (varsayılan 6000)
  min_chargeable      numeric(10,3) not null default 1,
  min_chargeable_unit text not null default 'wm' check (min_chargeable_unit in ('wm', 'kg')),
  valid_from          date not null default current_date,
  valid_to            date,
  is_active           boolean not null default true,
  notes               text,
  created_by          uuid references public.users (id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint pricing_rules_scope_uq unique nulls not distinct (transport_mode, carrier_id, valid_from)
);

-- ---------------------------------------------------------------------
-- system_settings · anahtar/değer (jsonb)
-- ---------------------------------------------------------------------
create table public.system_settings (
  key         text primary key,
  value       jsonb not null,
  description text,
  is_public   boolean not null default false,   -- müşteri/anonim istemci okuyabilir mi
  updated_by  uuid references public.users (id),
  updated_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- sequence_counters · yıl bazlı belge numaralandırma
-- ---------------------------------------------------------------------
create table public.sequence_counters (
  key        text not null,
  year       int  not null,
  last_value int  not null default 0,
  primary key (key, year)
);

create or replace function app.next_sequence(p_key text, p_year int default extract(year from now())::int)
returns int language plpgsql security definer set search_path = public as $$
declare v int;
begin
  insert into public.sequence_counters (key, year, last_value)
  values (p_key, p_year, 1)
  on conflict (key, year) do update set last_value = public.sequence_counters.last_value + 1
  returning last_value into v;
  return v;
end $$;

-- ÖNEK-YIL-SIRA · örn. TLP-2026-000428
create or replace function app.next_document_no(p_prefix text, p_width int default 5)
returns text language sql security definer set search_path = public as $$
  select p_prefix || '-' || extract(year from now())::int::text || '-'
         || lpad(app.next_sequence(p_prefix)::text, p_width, '0');
$$;

-- ---------------------------------------------------------------------
-- milestone_types · 21 adımlık yük takibi (tr/en/zh)
-- ---------------------------------------------------------------------
create table public.milestone_types (
  code                text primary key,
  sort_order          int  not null unique,
  phase               text not null check (phase in ('request', 'origin', 'transit', 'destination')),
  name_tr             text not null,
  name_en             text not null,
  name_zh             text,
  is_exception        boolean not null default false,   -- ilerlemeyi geriye almayan istisna adımı
  is_customer_visible boolean not null default true,
  notify_customer     boolean not null default true
);

-- ---------------------------------------------------------------------
-- legal_texts / consent_records · KVKK aydınlatma ve açık rıza
-- ---------------------------------------------------------------------
create table public.legal_texts (
  id           uuid primary key default gen_random_uuid(),
  key          text not null,                     -- kvkk_aydinlatma, acik_riza, hizmet_sozlesmesi
  version      text not null,
  title_tr     text not null,
  body_tr      text not null,
  is_active    boolean not null default false,
  published_at timestamptz,
  created_at   timestamptz not null default now(),
  unique (key, version)
);

create table public.consent_records (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users (id) on delete cascade,
  company_id     uuid references public.companies (id),
  legal_text_key text not null,
  version        text not null,
  accepted_at    timestamptz not null default now(),
  ip_address     inet,
  user_agent     text
);
create index consent_records_user_idx on public.consent_records (user_id, legal_text_key);

-- =====================================================================
-- Referans verisi (uygulamanın çalışması için zorunlu; demo değil)
-- =====================================================================

insert into public.roles (code, name_tr, description, scope) values
('super_admin',     'Süper Yönetici',                  'Tüm şirketleri, kullanıcıları, fiyat kurallarını, depoları, seferleri, finansal raporları ve sistem ayarlarını yönetir.', 'operator'),
('tr_operations',   'Türkiye Operasyon Personeli',     'Talepleri inceler, teklif hazırlar, rezervasyon yapar, gümrük ve yurtiçi dağıtımı yönetir, masraf ve evrak ekler.', 'operator'),
('cn_warehouse',    'Çin Depo Personeli',              'Depo kabul, ölçüm/tartım, fotoğraf-video, hasar/eksik bildirimi, paketleme ve konsolidasyona hazırlık.', 'operator'),
('customs_partner', 'Gümrük Müşaviri / Çözüm Ortağı',  'Yalnızca kendisine atanan gümrük dosyalarını görür; GTİP önerisi, vergi tahmini ve gümrük durumu girer.', 'partner'),
('customer_admin',  'Kurumsal Müşteri Yöneticisi',     'Firma hesabını ve personelini yönetir; teklif onaylar, ödeme bildirir, tüm müşteri işlemlerini yapar.', 'customer'),
('customer_user',   'Kurumsal Müşteri Kullanıcısı',    'Talep, tedarikçi, evrak ve takip işlemleri yapar; kullanıcı yönetimi, teklif onayı ve ödeme bildirimi yapamaz.', 'customer');

insert into public.permissions (module, code, name_tr) values
('admin',          'companies.manage',            'Şirketleri yönet'),
('admin',          'users.manage_all',            'Tüm kullanıcıları yönet'),
('admin',          'roles.manage',                'Rol ve yetkileri yönet'),
('admin',          'settings.manage',             'Sistem ayarlarını değiştir'),
('admin',          'activity_logs.view',          'İşlem kayıtlarını incele'),
('admin',          'warehouses.manage',           'Çin depolarını yönet'),
('admin',          'carriers.manage',             'Taşıyıcı ve acenteleri yönet'),
('admin',          'pricing_rules.manage',        'Fiyatlandırma kurallarını belirle'),
('admin',          'partners.manage',             'Çözüm ortaklarını yönet'),
('account',        'company.manage_own',          'Kendi firma bilgilerini yönet'),
('account',        'users.manage_own',            'Kendi firma kullanıcılarını yönet'),
('suppliers',      'suppliers.manage_own',        'Kendi tedarikçilerini ekle/düzenle'),
('suppliers',      'suppliers.view_all',          'Tüm tedarikçileri gör'),
('requests',       'requests.create',             'Taşıma talebi oluştur'),
('requests',       'requests.view_own',           'Kendi taleplerini gör'),
('requests',       'requests.view_all',           'Tüm talepleri gör'),
('requests',       'requests.review',             'Talepleri incele ve durum değiştir'),
('requests',       'precheck.manage',             'Ön uygunluk kontrolü ve görev oluştur'),
('quotations',     'quotations.prepare',          'Teklif hazırla'),
('quotations',     'quotations.send',             'Teklifi onaylayıp müşteriye gönder'),
('quotations',     'quotations.view_costs',       'Alış maliyeti ve kârı gör'),
('quotations',     'quotations.view_own',         'Kendi tekliflerini gör'),
('quotations',     'quotations.respond',          'Teklifi onayla veya revizyon iste'),
('warehouse',      'warehouse.receive',           'Depo kabulü yap'),
('warehouse',      'warehouse.inspect',           'Ölçüm, tartım ve kontrol gir'),
('warehouse',      'warehouse.upload_media',      'Fotoğraf ve video yükle'),
('warehouse',      'warehouse.report_discrepancy','Hasar veya eksik bildir'),
('warehouse',      'warehouse.mark_ready',        'Konsolidasyona hazır işaretle'),
('warehouse',      'warehouse.assign_location',   'Depo içi konum gir'),
('consolidations', 'consolidations.manage',       'Konsolidasyon oluştur, kapat, rezerve et'),
('consolidations', 'consolidations.prepare',      'Konsolidasyona yük ekle ve hazırla'),
('consolidations', 'consolidations.view_own',     'Kendi konsolidasyonlarını gör'),
('schedules',      'schedules.manage',            'Sefer oluştur ve düzenle'),
('schedules',      'containers.manage',           'Konteyner oluştur ve düzenle'),
('schedules',      'bookings.manage',             'Sefer/konteyner rezervasyonu yap'),
('shipments',      'shipments.update_status',     'Yük durumunu güncelle'),
('shipments',      'shipments.view_all',          'Tüm sevkiyatları gör'),
('shipments',      'shipments.view_own',          'Kendi sevkiyatlarını gör'),
('documents',      'documents.upload_own',        'Kendi dosyalarına evrak yükle'),
('documents',      'documents.upload_all',        'Tüm dosyalara evrak yükle'),
('documents',      'documents.view_own',          'Kendi evraklarını gör'),
('documents',      'documents.view_all',          'Tüm evrakları gör'),
('documents',      'documents.view_assigned',     'Atanan dosyaların evraklarını gör'),
('documents',      'documents.set_visibility',    'Evrak görünürlüğünü ayarla'),
('documents',      'documents.flag_missing',      'Evrak eksikliği bildir'),
('customs',        'customs.manage',              'Gümrük dosyalarını yönet ve ata'),
('customs',        'customs.view_assigned',       'Atanan gümrük dosyalarını gör'),
('customs',        'customs.update_assigned',     'GTİP önerisi, vergi tahmini ve durum gir'),
('deliveries',     'deliveries.request',          'Teslimat talebi oluştur'),
('deliveries',     'deliveries.manage',           'Yurtiçi dağıtımı yönet'),
('finance',        'finance.view_own_balance',    'Kendi bakiye ve ödemelerini gör'),
('finance',        'finance.report_payment',      'Ödeme bildir'),
('finance',        'finance.manage',              'Fatura, tahsilat ve masraf yönet'),
('finance',        'finance.record_expense',      'Masraf gir'),
('finance',        'finance.view_reports',        'Finansal raporları gör'),
('finance',        'finance.view_profit',         'Kârlılık verilerini gör'),
('communication',  'messages.send',               'Mesaj gönder'),
('communication',  'messages.internal',           'Dahili not yaz'),
('communication',  'tickets.create',              'Destek kaydı aç'),
('communication',  'tickets.manage',              'Destek kayıtlarını yönet'),
('reports',        'reports.operational',         'Operasyon raporlarını gör'),
('reports',        'dashboard.admin',             'Yönetici gösterge panelini gör');

-- super_admin: tüm izinler
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id from public.roles r cross join public.permissions p where r.code = 'super_admin';

-- diğer roller
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code = any (
  case r.code
    when 'tr_operations' then array[
      'suppliers.view_all', 'requests.view_all', 'requests.review', 'precheck.manage',
      'quotations.prepare', 'quotations.send', 'quotations.view_costs',
      'consolidations.manage', 'consolidations.prepare', 'bookings.manage',
      'shipments.update_status', 'shipments.view_all',
      'documents.upload_all', 'documents.view_all', 'documents.set_visibility', 'documents.flag_missing',
      'customs.manage', 'deliveries.manage', 'finance.manage', 'finance.record_expense',
      'messages.send', 'messages.internal', 'tickets.manage', 'reports.operational']
    when 'cn_warehouse' then array[
      'requests.view_all', 'shipments.view_all',
      'warehouse.receive', 'warehouse.inspect', 'warehouse.upload_media', 'warehouse.report_discrepancy',
      'warehouse.mark_ready', 'warehouse.assign_location', 'consolidations.prepare',
      'documents.upload_all', 'documents.view_assigned', 'messages.send', 'messages.internal']
    when 'customs_partner' then array[
      'customs.view_assigned', 'customs.update_assigned', 'documents.view_assigned', 'documents.upload_own',
      'documents.flag_missing', 'messages.send', 'tickets.create']
    when 'customer_admin' then array[
      'company.manage_own', 'users.manage_own', 'suppliers.manage_own',
      'requests.create', 'requests.view_own', 'quotations.view_own', 'quotations.respond',
      'consolidations.view_own', 'shipments.view_own', 'documents.upload_own', 'documents.view_own',
      'deliveries.request', 'finance.view_own_balance', 'finance.report_payment',
      'messages.send', 'tickets.create']
    when 'customer_user' then array[
      'suppliers.manage_own', 'requests.create', 'requests.view_own', 'quotations.view_own',
      'consolidations.view_own', 'shipments.view_own', 'documents.upload_own', 'documents.view_own',
      'deliveries.request', 'finance.view_own_balance', 'messages.send', 'tickets.create']
    else array[]::text[]
  end
)
where r.code <> 'super_admin';

insert into public.milestone_types (code, sort_order, phase, name_tr, name_en, name_zh, is_exception, is_customer_visible, notify_customer) values
('request_created',         1,  'request',     'Talep oluşturuldu',                 'Request created',                       '需求已创建',       false, true, false),
('precheck_in_progress',    2,  'request',     'Ön kontrol yapılıyor',              'Pre-check in progress',                 '预审进行中',       false, true, false),
('quote_prepared',          3,  'request',     'Teklif hazırlandı',                 'Quotation prepared',                    '报价已准备',       false, true, true),
('quote_approved',          4,  'request',     'Teklif onaylandı',                  'Quotation approved',                    '报价已确认',       false, true, false),
('supplier_contacted',      5,  'origin',      'Tedarikçiyle iletişim kuruldu',     'Supplier contacted',                    '已联系供应商',     false, true, true),
('picked_up_from_factory',  6,  'origin',      'Fabrikadan teslim alındı',          'Picked up from factory',                '已从工厂提货',     false, true, true),
('arrived_cn_warehouse',    7,  'origin',      'Çin deposuna ulaştı',               'Arrived at China warehouse',            '已到达中国仓库',   false, true, true),
('inspection_completed',    8,  'origin',      'Ölçüm ve kontrol tamamlandı',       'Measurement and inspection completed',  '测量与检验完成',   false, true, true),
('discrepancy_found',       9,  'origin',      'Eksiklik/hasar tespit edildi',      'Shortage or damage found',              '发现短缺或损坏',   true,  true, true),
('ready_for_consolidation', 10, 'origin',      'Konsolidasyona hazır',              'Ready for consolidation',               '可拼箱',           false, true, true),
('container_booked',        11, 'origin',      'Konteyner rezervasyonu yapıldı',    'Container booked',                      '已订舱',           false, true, true),
('loaded_into_container',   12, 'origin',      'Konteynere yüklendi',               'Loaded into container',                 '已装柜',           false, true, true),
('cn_customs_cleared',      13, 'origin',      'Çin gümrük işlemleri tamamlandı',   'China export customs cleared',          '中国出口报关完成', false, true, false),
('vessel_departed',         14, 'transit',     'Gemi hareket etti',                 'Vessel departed',                       '船舶已离港',       false, true, true),
('at_transshipment_port',   15, 'transit',     'Aktarma limanında',                 'At transshipment port',                 '中转港',           false, true, false),
('arrived_tr_port',         16, 'destination', 'Türkiye limanına ulaştı',           'Arrived at Turkish port',               '已抵达土耳其港口', false, true, true),
('container_unpacked',      17, 'destination', 'Konteyner açıldı',                  'Container unpacked',                    '已拆柜',           false, true, false),
('tr_customs_in_progress',  18, 'destination', 'Gümrük işlemleri devam ediyor',     'Turkish customs in progress',           '土耳其清关进行中', false, true, true),
('tr_customs_completed',    19, 'destination', 'Gümrük işlemleri tamamlandı',       'Turkish customs completed',             '土耳其清关完成',   false, true, true),
('out_for_delivery',        20, 'destination', 'Yurtiçi dağıtıma çıktı',            'Out for domestic delivery',             '国内派送中',       false, true, true),
('delivered',               21, 'destination', 'Teslim edildi',                     'Delivered',                             '已交付',           false, true, true);

insert into public.system_settings (key, value, description, is_public) values
('platform_name',               '"ChinaCargo Hub"',  'Platform adı', true),
('platform_tagline',            '"Çin''den gelen tüm yükleriniz tek platformda."', 'Ana slogan', true),
('default_locale',              '"tr"',              'Varsayılan arayüz dili', true),
('supported_locales',           '["tr", "en", "zh"]','Desteklenen diller (en/zh arayüzü sonraki faz)', true),
('delivery_code_prefix',        '"CC"',              'Depo teslim kodu ön eki', false),
('destination_hub_code',        '"IST"',             'Depo teslim kodundaki varış merkezi kodu', false),
('default_quotation_currency',  '"USD"',             'Teklif para birimi', true),
('quotation_validity_days',     '7',                 'Teklif geçerlilik süresi (gün)', false),
('default_wm_kg_per_cbm',       '1000',              'Deniz/demiryolu W/M varsayılanı: 1 CBM = 1000 kg', true),
('default_volumetric_divisor',  '6000',              'Hava kargo hacimsel ağırlık böleni', true),
('precheck_disclaimer_tr',      '"Bu bilgi ön değerlendirmedir. Kesin işlem öncesinde yetkili gümrük müşaviri tarafından doğrulanmalıdır."', 'Ön uygunluk uyarılarının yanında gösterilen ibare', true),
('max_upload_mb',               '25',                'Dosya yükleme üst sınırı (MB)', true),
('allowed_document_mime_types', '["application/pdf", "image/jpeg", "image/png", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]', 'İzin verilen evrak dosya türleri', true),
('allowed_media_mime_types',    '["image/jpeg", "image/png", "image/webp", "video/mp4", "video/quicktime"]', 'İzin verilen fotoğraf/video türleri', true),
('notification_channels',       '{"in_app": true, "email": true, "whatsapp": false, "sms": false}', 'Aktif bildirim kanalları (WhatsApp webhook ile sonraki faz)', false),
('kvkk_current_version',        '"1.0"',             'Yürürlükteki aydınlatma/açık rıza metni sürümü', true);

insert into public.pricing_rules (transport_mode, carrier_id, wm_kg_per_cbm, volumetric_divisor, min_chargeable, min_chargeable_unit, notes) values
('sea_lcl',   null, 1000, null, 1,   'wm', 'Varsayılan LCL kuralı: 1 CBM = 1.000 kg, en az 1 W/M'),
('rail_lcl',  null, 1000, null, 1,   'wm', 'Demiryolu parsiyel varsayılanı; yönetim panelinden düzenlenebilir'),
('air_cargo', null, null, 6000, 45,  'kg', 'Hava kargo: hacimsel ağırlık = En×Boy×Yükseklik/6000, en az 45 kg'),
('express',   null, null, 5000, 0.5, 'kg', 'Ekspres kargo: bölen 5000, taşıyıcı bazında değiştirilebilir');

insert into public.legal_texts (key, version, title_tr, body_tr, is_active, published_at) values
('kvkk_aydinlatma',   '1.0', 'KVKK Aydınlatma Metni',        'TASLAK — 6698 sayılı KVKK kapsamında aydınlatma metni. Yayın öncesi hukuk danışmanı tarafından tamamlanacaktır.', true, now()),
('acik_riza',         '1.0', 'Açık Rıza Metni',              'TASLAK — Kişisel verilerin işlenmesine ilişkin açık rıza metni. Yayın öncesi hukuk danışmanı tarafından tamamlanacaktır.', true, now()),
('hizmet_sozlesmesi', '1.0', 'Platform Hizmet Sözleşmesi',   'TASLAK — Platform kullanım ve hizmet şartları.', true, now());
