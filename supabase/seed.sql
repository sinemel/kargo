-- =====================================================================
-- ChinaCargo Hub · Demo verileri (spec bölüm 18)
-- Lokal Supabase için: `supabase db reset` migration'lardan sonra bu dosyayı yükler.
-- Barındırılan projede auth.users satırlarını Dashboard/CLI ile açıp aynı e-postaları kullanın.
-- Tüm kur, fiyat ve GTİP değerleri temsilidir.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Numaralandırma sayaçları (seed'deki sabit numaralarla çakışmasın)
-- ---------------------------------------------------------------------
insert into public.sequence_counters (key, year, last_value) values
('TLP', 2026, 428), ('TKL', 2026, 128), ('DPK', 2026, 325), ('KNS', 2026, 42), ('SEF', 2026, 39),
('SVK', 2026, 431), ('GMR', 2026, 214), ('TSL', 2026, 0),  ('FTR', 2026, 98), ('ODM', 2026, 71),
('MSR', 2026, 314), ('DST', 2026, 56), ('DLV-00428', 2026, 3)
on conflict (key, year) do update set last_value = greatest(public.sequence_counters.last_value, excluded.last_value);

-- ---------------------------------------------------------------------
-- Kimlik: demo hesaplar (şifre: Demo1234!)
-- ---------------------------------------------------------------------
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change)
select u.id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', u.email,
       crypt('Demo1234!', gen_salt('bf')), now(),
       '{"provider": "email", "providers": ["email"]}'::jsonb, jsonb_build_object('full_name', u.full_name),
       now(), now(), '', '', '', ''
from (values
  ('20000000-0000-4000-8000-000000000001'::uuid, 'admin@chinacargohub.com',         'Selin Kaya'),
  ('20000000-0000-4000-8000-000000000002'::uuid, 'operasyon@chinacargohub.com',     'Burak Demir'),
  ('20000000-0000-4000-8000-000000000003'::uuid, 'depo.shanghai@chinacargohub.com', 'Li Wei'),
  ('20000000-0000-4000-8000-000000000004'::uuid, 'gumruk@bogazicigumruk.com',       'Emre Yıldız'),
  ('20000000-0000-4000-8000-000000000005'::uuid, 'ayse@ornekithalat.com',           'Ayşe Yılmaz'),
  ('20000000-0000-4000-8000-000000000006'::uuid, 'mehmet@ornekithalat.com',         'Mehmet Kaya'),
  ('20000000-0000-4000-8000-000000000007'::uuid, 'zeynep@marmaratekstil.com',       'Zeynep Arslan')
) as u (id, email, full_name)
on conflict (id) do nothing;

insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), au.id, au.id::text, 'email',
       jsonb_build_object('sub', au.id::text, 'email', au.email, 'email_verified', true),
       now(), now(), now()
from auth.users au
where au.email in ('admin@chinacargohub.com', 'operasyon@chinacargohub.com', 'depo.shanghai@chinacargohub.com',
                   'gumruk@bogazicigumruk.com', 'ayse@ornekithalat.com', 'mehmet@ornekithalat.com', 'zeynep@marmaratekstil.com')
on conflict do nothing;

insert into public.users (id, email, full_name, phone, locale) values
('20000000-0000-4000-8000-000000000001', 'admin@chinacargohub.com',         'Selin Kaya',    '+90 532 000 00 01', 'tr'),
('20000000-0000-4000-8000-000000000002', 'operasyon@chinacargohub.com',     'Burak Demir',   '+90 532 000 00 02', 'tr'),
('20000000-0000-4000-8000-000000000003', 'depo.shanghai@chinacargohub.com', 'Li Wei',        '+86 138 0000 0003', 'zh'),
('20000000-0000-4000-8000-000000000004', 'gumruk@bogazicigumruk.com',       'Emre Yıldız',   '+90 532 000 00 04', 'tr'),
('20000000-0000-4000-8000-000000000005', 'ayse@ornekithalat.com',           'Ayşe Yılmaz',   '+90 532 000 00 05', 'tr'),
('20000000-0000-4000-8000-000000000006', 'mehmet@ornekithalat.com',         'Mehmet Kaya',   '+90 532 000 00 06', 'tr'),
('20000000-0000-4000-8000-000000000007', 'zeynep@marmaratekstil.com',       'Zeynep Arslan', '+90 532 000 00 07', 'tr')
on conflict (id) do update set full_name = excluded.full_name, phone = excluded.phone, locale = excluded.locale;

-- ---------------------------------------------------------------------
-- Şirketler ve üyelikler
-- ---------------------------------------------------------------------
insert into public.companies (id, type, legal_name, trade_name, tax_number, tax_office, country_code, city, district, address, phone, email, website, default_currency, kvkk_consent_at, kvkk_consent_version) values
('10000000-0000-4000-8000-000000000001', 'operator', 'ChinaCargo Hub Lojistik A.Ş.',          'ChinaCargo Hub',     '1234567890', 'Bakırköy',   'TR', 'İstanbul', 'Bakırköy',  'Yenibosna Merkez Mah. Lojistik Cad. No: 12', '+90 212 000 00 00', 'info@chinacargohub.com',    'https://chinacargohub.com', 'USD', '2026-06-01 09:00+03', '1.0'),
('10000000-0000-4000-8000-000000000002', 'customer', 'Örnek İthalat A.Ş.',                    'Örnek İthalat',      '9876543210', 'Bağcılar',   'TR', 'İstanbul', 'Bağcılar',  'İstoç Ticaret Merkezi 28. Ada No: 112',      '+90 212 000 00 10', 'info@ornekithalat.com',     null,                        'USD', '2026-08-18 14:22+03', '1.0'),
('10000000-0000-4000-8000-000000000003', 'partner',  'Boğaziçi Gümrük Müşavirliği Ltd. Şti.', 'Boğaziçi Gümrük',    '5556667778', 'Beyoğlu',    'TR', 'İstanbul', 'Beyoğlu',   'Karaköy Rıhtım Cad. No: 4',                  '+90 212 000 00 20', 'info@bogazicigumruk.com',   null,                        'TRY', '2026-06-15 10:00+03', '1.0'),
('10000000-0000-4000-8000-000000000004', 'customer', 'Marmara Tekstil Makine Ltd. Şti.',      'Marmara Tekstil',    '4443332221', 'Güngören',   'TR', 'İstanbul', 'Güngören',  'Merter Tekstil Sitesi No: 45',               '+90 212 000 00 30', 'info@marmaratekstil.com',   null,                        'USD', '2026-07-02 11:30+03', '1.0');

insert into public.company_users (company_id, user_id, role_id, title, is_primary_contact, status, accepted_at)
select c.company_id, c.user_id, r.id, c.title, c.is_primary, 'active', now()
from (values
  ('10000000-0000-4000-8000-000000000001'::uuid, '20000000-0000-4000-8000-000000000001'::uuid, 'super_admin',     'Genel Müdür',           true),
  ('10000000-0000-4000-8000-000000000001'::uuid, '20000000-0000-4000-8000-000000000002'::uuid, 'tr_operations',   'Operasyon Uzmanı',      false),
  ('10000000-0000-4000-8000-000000000001'::uuid, '20000000-0000-4000-8000-000000000003'::uuid, 'cn_warehouse',    'Shanghai Depo Sorumlusu', false),
  ('10000000-0000-4000-8000-000000000003'::uuid, '20000000-0000-4000-8000-000000000004'::uuid, 'customs_partner', 'Gümrük Müşaviri',       true),
  ('10000000-0000-4000-8000-000000000002'::uuid, '20000000-0000-4000-8000-000000000005'::uuid, 'customer_admin',  'Satın Alma Müdürü',     true),
  ('10000000-0000-4000-8000-000000000002'::uuid, '20000000-0000-4000-8000-000000000006'::uuid, 'customer_user',   'Dış Ticaret Uzmanı',    false),
  ('10000000-0000-4000-8000-000000000004'::uuid, '20000000-0000-4000-8000-000000000007'::uuid, 'customer_admin',  'Firma Sahibi',          true)
) as c (company_id, user_id, role_code, title, is_primary)
join public.roles r on r.code = c.role_code;

insert into public.customers (id, company_id, customer_code, segment, trade_center, account_manager_id, payment_terms_days, credit_limit, credit_currency, default_delivery_address, default_delivery_city, default_delivery_district, notes) values
('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', '00428', 'toptanci', 'İstoç',  '20000000-0000-4000-8000-000000000002', 0, 25000, 'USD', 'İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar', 'İstanbul', 'Bağcılar', 'Aydınlatma ve mobilya aksesuarı toptancısı; Çin''den ilk konsolide ithalatı.'),
('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', '00431', 'kobi',     'Merter', '20000000-0000-4000-8000-000000000002', 0, 10000, 'USD', 'Merter Tekstil Sitesi No: 45, Güngören',           'İstanbul', 'Güngören', 'Tekstil makine yedek parçası; düzenli küçük hacim.');

insert into public.consent_records (user_id, company_id, legal_text_key, version, accepted_at, ip_address) values
('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'kvkk_aydinlatma', '1.0', '2026-08-18 14:22+03', '85.100.10.20'),
('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'acik_riza',       '1.0', '2026-08-18 14:22+03', '85.100.10.20'),
('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'kvkk_aydinlatma', '1.0', '2026-08-19 09:05+03', '85.100.10.21'),
('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000004', 'kvkk_aydinlatma', '1.0', '2026-07-02 11:30+03', '78.180.5.9');

-- ---------------------------------------------------------------------
-- Çin depoları, konumlar, taşıyıcılar
-- ---------------------------------------------------------------------
insert into public.warehouses (id, code, name, city, address, contact_name, contact_phone, contact_email, receiving_hours) values
('50000000-0000-4000-8000-000000000001', 'CN-SHA', 'Shanghai Konsolidasyon Deposu', 'Shanghai', 'No. 88 Huaxin Rd, Qingpu District, Shanghai 201708', 'Li Wei',    '+86 138 0000 0003', 'depo.shanghai@chinacargohub.com', 'Pzt–Cmt 09:00–18:00 (CST)'),
('50000000-0000-4000-8000-000000000002', 'CN-SZX', 'Shenzhen Toplama Deposu',       'Shenzhen', 'Bldg 3, Longgang Logistics Park, Shenzhen 518116',   'Zhang Min', '+86 138 0000 0008', 'depo.shenzhen@chinacargohub.com', 'Pzt–Cmt 09:00–18:00 (CST)'),
('50000000-0000-4000-8000-000000000003', 'CN-YIW', 'Yiwu Toplama Deposu',           'Yiwu',     'Yiwu International Trade City, Zone 5, Yiwu 322000',   'Chen Hao',  '+86 138 0000 0009', 'depo.yiwu@chinacargohub.com',     'Pzt–Cmt 09:00–18:00 (CST)');

insert into public.warehouse_locations (id, warehouse_id, code, zone, rack, level, capacity_cbm) values
('51000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'A-01', 'A', '01', '1', 12),
('51000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000001', 'A-02', 'A', '02', '1', 12),
('51000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000001', 'P-01', 'P', null, null, 40),
('51000000-0000-4000-8000-000000000004', '50000000-0000-4000-8000-000000000001', 'B-01', 'B', '01', '1', 12);

insert into public.carriers (id, name, carrier_type, scac, contact_email, notes) values
('60000000-0000-4000-8000-000000000001', 'COSCO Shipping Lines',          'sea',         'COSU', 'booking@cosco-demo.com',  'Shanghai → Ambarlı haftalık LCL servisi'),
('60000000-0000-4000-8000-000000000002', 'Shanghai Huayun Logistics',     'trucking_cn', null,   'ops@huayun-demo.cn',      'Guangdong → Shanghai Çin içi nakliye'),
('60000000-0000-4000-8000-000000000003', 'İstanbul Yurtiçi Nakliyat',     'trucking_tr', null,   'sevk@iyn-demo.com',       'Ambarlı → İstoç/İkitelli dağıtım'),
('60000000-0000-4000-8000-000000000004', 'Turkish Cargo',                 'air',         'TK',   'cargo@tk-demo.com',       'PVG/CAN → IST hava kargo');

-- Taşıyıcıya özel kural örneği: Turkish Cargo hacimsel bölen 6000, minimum 100 kg
insert into public.pricing_rules (transport_mode, carrier_id, wm_kg_per_cbm, volumetric_divisor, min_chargeable, min_chargeable_unit, notes) values
('air_cargo', '60000000-0000-4000-8000-000000000004', null, 6000, 100, 'kg', 'Turkish Cargo genel kargo tarifesi (demo)');

-- ---------------------------------------------------------------------
-- Tedarikçiler (Örnek İthalat A.Ş.)
-- ---------------------------------------------------------------------
insert into public.suppliers (id, company_id, name, contact_name, phone, email, wechat, province, city, address, address_type, default_incoterm, products_summary, rating, created_by) values
('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Guangzhou Lighting Co.',      'Mr. Chen Jian', '+86 139 1111 0001', 'sales@gzlighting-demo.com', 'gzl_chen',   'Guangdong', 'Guangzhou', 'Huadu District, Xinhua Industrial Zone No. 21',   'factory',   'EXW', 'LED panel, downlight ve armatür', 4, '20000000-0000-4000-8000-000000000005'),
('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Foshan Hardware Ltd.',        'Ms. Liu Yan',   '+86 139 1111 0002', 'export@fshardware-demo.com', 'fs_liuyan', 'Guangdong', 'Foshan',    'Shunde District, Longjiang Town, Furniture Ave 8', 'factory',   'FOB', 'Menteşe, kulp, ray ve mobilya aksesuarı', 5, '20000000-0000-4000-8000-000000000005'),
('40000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'Shenzhen Smart Systems Co.',  'Mr. Wang Lei',  '+86 139 1111 0003', 'oem@szsmart-demo.com',      'sz_wanglei', 'Guangdong', 'Shenzhen',  'Bao''an District, Fuyong Tech Park Bldg C',       'warehouse', 'EXW', 'Akıllı priz, sensör ve ev otomasyonu', 4, '20000000-0000-4000-8000-000000000006');

-- ---------------------------------------------------------------------
-- Kurlar (temsili)
-- ---------------------------------------------------------------------
insert into public.exchange_rates (rate_date, base_currency, quote_currency, rate, source) values
('2026-08-22', 'USD', 'TRY', 41.3800, 'manual'),
('2026-08-22', 'EUR', 'TRY', 48.2100, 'manual'),
('2026-09-12', 'USD', 'TRY', 41.9200, 'manual'),
('2026-09-12', 'EUR', 'TRY', 48.7500, 'manual'),
('2026-09-12', 'CNY', 'TRY', 5.8300,  'manual');

-- ---------------------------------------------------------------------
-- Aşama 1 · Taşıma talepleri (bir talep = bir tedarikçi)
-- ---------------------------------------------------------------------
insert into public.shipment_requests (id, request_no, company_id, customer_id, supplier_id, origin_city, pickup_address, incoterm, delivery_address, delivery_city, delivery_district, requested_mode, suggested_mode, cargo_ready_date, goods_value, currency, declared_packages, declared_gross_kg, declared_net_kg, declared_cbm, is_fragile, status, customer_note, submitted_at, created_by, created_at) values
('70000000-0000-4000-8000-000000000001', 'TLP-2026-000426', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', 'Guangzhou', 'Huadu District, Xinhua Industrial Zone No. 21',   'EXW', 'İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar', 'İstanbul', 'Bağcılar', 'system_suggestion', 'sea_lcl', '2026-08-27', 18500, 'USD', 40, 480,  432,  3.84,  true,  'converted', 'LED panellerin kırılgan olduğunu depoya belirtin lütfen.', '2026-08-20 09:15+03', '20000000-0000-4000-8000-000000000005', '2026-08-20 09:15+03'),
('70000000-0000-4000-8000-000000000002', 'TLP-2026-000427', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000002', 'Foshan',    'Shunde District, Longjiang Town, Furniture Ave 8', 'FOB', 'İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar', 'İstanbul', 'Bağcılar', 'sea_lcl',           'sea_lcl', '2026-08-30', 27000, 'USD', 18, 4320, 4140, 23.76, false, 'converted', null, '2026-08-20 09:32+03', '20000000-0000-4000-8000-000000000005', '2026-08-20 09:32+03'),
('70000000-0000-4000-8000-000000000003', 'TLP-2026-000428', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000003', 'Shenzhen',  'Bao''an District, Fuyong Tech Park Bldg C',       'EXW', 'İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar', 'İstanbul', 'Bağcılar', 'system_suggestion', 'sea_lcl', '2026-09-03', 9800,  'USD', 12, 108,  96,   0.84,  false, 'converted', 'Ürünler Wi-Fi modüllü; gerekli belgeleri tedarikçiden isteyebilirsiniz.', '2026-08-20 09:48+03', '20000000-0000-4000-8000-000000000006', '2026-08-20 09:48+03');

insert into public.shipment_items (id, request_id, company_id, line_no, description, hs_code_estimated, package_type, package_count, length_cm, width_cm, height_cm, gross_kg_per_package, net_kg_per_package, goods_value, currency, is_fragile) values
('71000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 1, 'LED panel armatür 60×60 cm 40W, 4000K (koli başı 10 adet)', '9405.11', 'carton', 40, 60,  40,  40,  12,  10.8, 18500, 'USD', true),
('71000000-0000-4000-8000-000000000002', '70000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 1, 'Mobilya aksesuarı: yavaşlatıcı menteşe, teleskopik ray, kulp (paletli)', '8302.42', 'pallet', 18, 120, 100, 110, 240, 230,  27000, 'USD', false),
('71000000-0000-4000-8000-000000000003', '70000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 1, 'Akıllı ev ürünleri: Wi-Fi priz, kapı/pencere sensörü, hub (koli başı 50 adet)', '8517.62', 'carton', 12, 50,  40,  35,  9,   8,    9800,  'USD', false);

-- Aşama 2 · Ön uygunluk uyarıları (ön değerlendirme; hukuki karar değildir)
insert into public.precheck_flags (request_id, item_id, company_id, flag_type, severity, message_tr, source, created_by, created_at) values
('70000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'ce_conformity',        'warning',  'LED aydınlatma armatürleri için CE işareti ile LVD/EMC uygunluk beyanı ve test raporu gerekebilir.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'tareks_check',         'warning',  'Aydınlatma ürünleri ithalatta TAREKS (Ürün Güvenliği ve Denetimi) kapsamında olabilir.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'hs_code_verification', 'info',     'Tahmini GTİP 9405.11; 12 haneli Türk tarife kodu gümrük müşaviri tarafından doğrulanmalı.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'antidumping',          'critical', 'Çin menşeli mobilya aksesuarlarında (menteşe vb.) antidamping önlemi riski var; kalem bazında GTİP kontrolü gerekli.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'hs_code_verification', 'info',     'Tahmini GTİP 8302.42; ray ve kulplar farklı alt pozisyonlara girebilir.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000003', '71000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'ce_conformity',        'warning',  'Wi-Fi modüllü ürünler telsiz ekipmanı (RED) kapsamında; CE ve RED test raporu gerekebilir.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000003', '71000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'tareks_check',         'warning',  'Telsiz ekipmanları TAREKS denetimine tabi olabilir.', 'auto', null, '2026-08-21 10:00+03'),
('70000000-0000-4000-8000-000000000003', '71000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'ipr_brand',            'warning',  'Ürün ve ambalajda marka/logo varsa fikrî mülkiyet (marka tescili) kontrolü yapılmalı.', 'manual', '20000000-0000-4000-8000-000000000002', '2026-08-21 11:20+03');

-- ---------------------------------------------------------------------
-- Sefer, konteyner, konsolidasyon
-- ---------------------------------------------------------------------
insert into public.sailing_schedules (id, schedule_code, transport_mode, origin_warehouse_id, origin_port, origin_port_code, destination_port, destination_port_code, carrier_id, vessel_name, voyage_no, cut_off_date, doc_cut_off_date, etd, eta, capacity_cbm, capacity_kg, status, created_by) values
('75000000-0000-4000-8000-000000000001', 'SEF-2026-00038', 'sea_lcl', '50000000-0000-4000-8000-000000000001', 'Shanghai', 'CNSHA', 'Ambarlı', 'TRAMR', '60000000-0000-4000-8000-000000000001', 'COSCO SHIPPING ARIES', '0412W', '2026-09-15', '2026-09-14', '2026-09-18', '2026-10-22', 68, 26000, 'open',    '20000000-0000-4000-8000-000000000001'),
('75000000-0000-4000-8000-000000000002', 'SEF-2026-00039', 'sea_lcl', '50000000-0000-4000-8000-000000000001', 'Shanghai', 'CNSHA', 'Ambarlı', 'TRAMR', '60000000-0000-4000-8000-000000000001', 'COSCO SHIPPING TAURUS', '0419W', '2026-09-22', '2026-09-21', '2026-09-25', '2026-10-29', 68, 26000, 'planned', '20000000-0000-4000-8000-000000000001');

insert into public.containers (id, schedule_id, container_no, container_type, mbl_no, capacity_cbm, capacity_kg, status, created_by) values
('76000000-0000-4000-8000-000000000001', '75000000-0000-4000-8000-000000000001', 'CSNU6021874', '40HC', 'COSU6412345678', 68, 26000, 'booked', '20000000-0000-4000-8000-000000000002');

insert into public.consolidations (id, consolidation_no, company_id, customer_id, warehouse_id, status, target_mode, planned_schedule_id, planned_container_id, needs_repacking, estimated_savings, savings_currency, ready_at, note, created_by, created_at) values
('74000000-0000-4000-8000-000000000001', 'KNS-2026-00042', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', 'booked', 'sea_lcl', '75000000-0000-4000-8000-000000000001', '76000000-0000-4000-8000-000000000001', true, 640, 'USD', '2026-09-09 08:30+00', 'S01''in eksik 2 kolisi bir sonraki sefere (SEF-2026-00039) kalacak; müşteri onayı mesaj kaydında.', '20000000-0000-4000-8000-000000000002', '2026-09-01 07:00+00');

-- ---------------------------------------------------------------------
-- Aşama 3 · Konsolide teklif (3 talebi kapsar)
-- ---------------------------------------------------------------------
insert into public.quotations (id, quotation_no, version, company_id, customer_id, consolidation_id, status, transport_mode, incoterm, currency, exchange_rates, quote_date, valid_until, transit_days_min, transit_days_max, planned_departure_date, estimated_arrival_date, chargeable_wm, chargeable_kg, included_services, excluded_services, special_terms, payment_plan, cancellation_terms, delay_force_majeure_terms, prepared_by, sent_at, approved_at, approved_by, created_by, created_at) values
('72000000-0000-4000-8000-000000000001', 'TKL-2026-00128', 1, '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', 'approved', 'sea_lcl', 'EXW', 'USD',
 '{"USD_TRY": 41.38, "rate_date": "2026-08-22", "source": "TCMB"}'::jsonb,
 '2026-08-22', '2026-08-29', 32, 38, '2026-09-18', '2026-10-22', 28.44, 4908,
 array['Çin içi toplama (3 nokta)', 'Depo kabulü, ölçüm ve tartım', 'Fotoğraf/video kontrolü', 'Konsolidasyon (tek HBL)', 'Çin çıkış işlemleri ve ihracat evrakları', 'Deniz navlunu Shanghai → Ambarlı', 'Nakliye sigortası (fatura değeri × 1,1)', 'Ambarlı CFS, ordino ve belge masrafları', 'Gümrük müşavirliği koordinasyonu', 'İstoç/İkitelli teslimat'],
 array['Gümrük vergisi, KDV, ÖTV ve diğer mali yükler (GTİP onayı sonrası ayrıca faturalanır)', 'TAREKS/uygunluk testi ücretleri', 'Ardiye ve demuraj (cut-off sonrası gecikmeler)', 'Tedarikçi mal bedeli ödemesi'],
 'Teklif 28,44 W/M ve 3 tedarikçi/3 kabul üzerinden hazırlanmıştır. Gerçek ölçüm farkı ±%5''i aşarsa navlun kalemi gerçekleşen W/M ile yeniden hesaplanır.',
 '%50 teklif onayında (proforma), %50 gemi hareketinde. Vergiler gümrükleme öncesi nakden.',
 'Depo kabulü öncesi iptal ücretsizdir. Depo kabulünden sonra iptalde gerçekleşen Çin içi masraflar ve depo ücretleri yansıtılır. Konteyner rezervasyonundan sonra iptalde navlunun %50''si tahsil edilir.',
 'Transit süre tahminidir; liman yoğunluğu, hat değişikliği, gümrük muayenesi ve mücbir sebepler (doğal afet, grev, salgın, savaş) kaynaklı gecikmelerden platform sorumlu tutulamaz. Gecikme halinde müşteri anlık bilgilendirilir.',
 '20000000-0000-4000-8000-000000000002', '2026-08-22 16:40+03', '2026-08-24 10:05+03', '20000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '2026-08-22 15:10+03');

insert into public.quotation_requests (quotation_id, request_id) values
('72000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001'),
('72000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000002'),
('72000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000003');

-- Satış kalemleri (müşteri görür) — toplam tetikleyici ile hesaplanır: 3.485,59 USD
insert into public.quotation_items (id, quotation_id, company_id, sort_order, category, description_tr, certainty, quantity, unit, unit_price, amount, currency, note) values
('72100000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 1,  'cn_pickup',            'Çin içi toplama (Guangzhou, Foshan, Shenzhen → Shanghai depo)', 'fixed',            1,     'flat',     380,    380.00,  'USD', null),
('72100000-0000-4000-8000-000000000002', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 2,  'cn_warehouse_receipt', 'Çin depo kabulü (3 tedarikçi)',                                'fixed',            3,     'shipment', 30,     90.00,   'USD', null),
('72100000-0000-4000-8000-000000000003', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 3,  'measurement_weighing', 'Ölçüm ve tartım',                                              'included',         1,     'flat',     0,      0.00,    'USD', 'Depo kabul hizmetine dahil'),
('72100000-0000-4000-8000-000000000004', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 4,  'photo_video_check',    'Fotoğraf/video kontrolü',                                      'included',         1,     'flat',     0,      0.00,    'USD', 'Depo kabul hizmetine dahil'),
('72100000-0000-4000-8000-000000000005', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 5,  'consolidation',        'Konsolidasyon (tek HBL altında birleştirme)',                  'fixed',            1,     'hbl',      120,    120.00,  'USD', null),
('72100000-0000-4000-8000-000000000006', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 6,  'repacking',            'Yeniden paketleme (ihtiyaç halinde)',                          'estimated',        1,     'flat',     60,     60.00,   'USD', 'Gerçekleşen adet üzerinden'),
('72100000-0000-4000-8000-000000000007', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 7,  'palletizing',          'Paletleme (LED kolileri, kırılgan)',                           'estimated',        1,     'flat',     90,     90.00,   'USD', null),
('72100000-0000-4000-8000-000000000008', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 8,  'cn_export_clearance',  'Çin çıkış işlemleri',                                          'fixed',            1,     'hbl',      110,    110.00,  'USD', null),
('72100000-0000-4000-8000-000000000009', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 9,  'export_documents',     'İhracat evrakları',                                            'included',         1,     'flat',     0,      0.00,    'USD', 'Çıkış işlemlerine dahil'),
('72100000-0000-4000-8000-000000000010', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 10, 'main_freight',         'Deniz navlunu LCL Shanghai → Ambarlı',                         'fixed',            28.44, 'wm',       38,     1080.72, 'USD', '28,44 W/M × 38 USD'),
('72100000-0000-4000-8000-000000000011', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 11, 'fuel_and_surcharges',  'Yakıt ve hat ek ücretleri (BAF/CAF)',                          'fixed',            28.44, 'wm',       6,      170.64,  'USD', null),
('72100000-0000-4000-8000-000000000012', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 12, 'insurance',            'Nakliye sigortası (%0,35 × 55.300 USD)',                       'estimated',        55300, 'pct',      0.0035, 193.55,  'USD', 'Ticari fatura değerine göre kesinleşir'),
('72100000-0000-4000-8000-000000000013', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 13, 'tr_port_cfs',          'Ambarlı liman/CFS masrafları',                                 'estimated',        28.44, 'wm',       22,     625.68,  'USD', 'Liman tarifesi TRY; kur farkı yansıtılır'),
('72100000-0000-4000-8000-000000000014', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 14, 'documentation_ordino', 'Belge ve ordino masrafları',                                   'estimated',        1,     'hbl',      95,     95.00,   'USD', null),
('72100000-0000-4000-8000-000000000015', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 15, 'customs_brokerage',    'Gümrük müşavirliği (3 GTİP kalemi)',                           'estimated',        1,     'hbl',      180,    180.00,  'USD', null),
('72100000-0000-4000-8000-000000000016', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 16, 'taxes_and_duties',     'Gümrük vergisi, KDV ve mali yükler',                           'to_be_calculated', 1,     'flat',     0,      0.00,    'USD', 'GTİP onayı sonrası gümrük müşaviri tahmini ile'),
('72100000-0000-4000-8000-000000000017', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 17, 'tr_domestic_delivery', 'Türkiye içi dağıtım — İkitelli/İstoç',                         'estimated',        1,     'shipment', 140,    140.00,  'USD', 'Tek araç, tek adres'),
('72100000-0000-4000-8000-000000000018', '72000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 18, 'platform_fee',         'Platform hizmet bedeli',                                       'fixed',            1,     'flat',     150,    150.00,  'USD', null);

-- Alış maliyetleri (yalnızca operatör görür) — toplam 2.275,12 USD → tahmini kâr 1.210,47 USD
insert into public.quotation_item_costs (quotation_item_id, company_id, cost_amount, cost_currency, vendor_type, vendor_note) values
('72100000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 260.00, 'USD', 'trucker',         'Shanghai Huayun, 3 nokta'),
('72100000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 45.00,  'USD', 'warehouse',       'CN-SHA kabul ücreti'),
('72100000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 40.00,  'USD', 'warehouse',       null),
('72100000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 35.00,  'USD', 'warehouse',       null),
('72100000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000002', 55.00,  'USD', 'warehouse',       null),
('72100000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', 70.00,  'USD', 'other',           'Çin acentesi'),
('72100000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002', 739.44, 'USD', 'carrier',         'COSCO 26 USD/W/M'),
('72100000-0000-4000-8000-000000000011', '10000000-0000-4000-8000-000000000002', 142.20, 'USD', 'carrier',         '5 USD/W/M'),
('72100000-0000-4000-8000-000000000012', '10000000-0000-4000-8000-000000000002', 130.00, 'USD', 'other',           'Sigorta şirketi'),
('72100000-0000-4000-8000-000000000013', '10000000-0000-4000-8000-000000000002', 483.48, 'USD', 'other',           'Ambarlı CFS 17 USD/W/M'),
('72100000-0000-4000-8000-000000000014', '10000000-0000-4000-8000-000000000002', 60.00,  'USD', 'other',           null),
('72100000-0000-4000-8000-000000000015', '10000000-0000-4000-8000-000000000002', 120.00, 'USD', 'customs_partner', 'Boğaziçi Gümrük'),
('72100000-0000-4000-8000-000000000017', '10000000-0000-4000-8000-000000000002', 95.00,  'USD', 'trucker',         'İstanbul Yurtiçi Nakliyat');

-- ---------------------------------------------------------------------
-- Çin depo kabulleri · S01 eksik koli senaryosu, S02 hasar/yeniden sarma, S03 tam
-- ---------------------------------------------------------------------
insert into public.warehouse_receipts (id, receipt_no, delivery_code, company_id, customer_id, request_id, supplier_id, warehouse_id, consolidation_id, status, expected_arrival_date, expected_packages, received_packages, expected_gross_kg, actual_gross_kg, expected_cbm, actual_cbm, packaging_condition, damage_status, needs_repacking, needs_palletizing, repacked_at, palletized_at, location_id, received_by, received_at, ready_at, warehouse_note, created_by, created_at) values
('73000000-0000-4000-8000-000000000001', 'DPK-2026-00311', 'CC-IST-2026-00428-S01', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '50000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', 'discrepancy', '2026-09-01', 40, 38, 480,  458.4,  3.84,  3.6480,  'good',       'none',  false, true,  null,                     '2026-09-02 03:30+00', '51000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', '2026-09-01 02:20+00', '2026-09-02 04:00+00', '38/40 koli. 2 koli eksik; tedarikçiye bildirildi, sonraki sefere kalacak. Kırılgan: 2 palete alındı.', '20000000-0000-4000-8000-000000000002', '2026-08-25 08:00+00'),
('73000000-0000-4000-8000-000000000002', 'DPK-2026-00318', 'CC-IST-2026-00428-S02', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', '50000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', 'ready',       '2026-09-04', 18, 18, 4320, 4296.0, 23.76, 23.9760, 'acceptable', 'minor', true,  false, '2026-09-05 02:15+00', null,                     '51000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', '2026-09-04 06:40+00', '2026-09-05 03:00+00', '18/18 palet. Palet 7 streç film yırtık, içerik sağlam; yeniden sarıldı. Ölçülen yükseklik 111 cm.', '20000000-0000-4000-8000-000000000002', '2026-08-25 08:00+00'),
('73000000-0000-4000-8000-000000000003', 'DPK-2026-00325', 'CC-IST-2026-00428-S03', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000003', '50000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', 'ready',       '2026-09-08', 12, 12, 108,  109.2,  0.84,  0.8400,  'good',       'none',  false, false, null,                     null,                     '51000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000003', '2026-09-08 01:50+00', '2026-09-08 02:30+00', '12/12 koli, tam ve sağlam.', '20000000-0000-4000-8000-000000000002', '2026-08-25 08:00+00');

-- Koliler (QR kod tetikleyici ile: CC-IST-2026-00428-S01-P001 ...)
insert into public.packages (company_id, receipt_id, item_id, package_no, package_type, length_cm, width_cm, height_cm, gross_kg, status, location_id)
select '10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000001', '71000000-0000-4000-8000-000000000001', n, 'carton', 60, 40, 40, 12.06,
       case when n <= 38 then 'received'::package_status else 'missing'::package_status end,
       case when n <= 38 then '51000000-0000-4000-8000-000000000001'::uuid else null end
from generate_series(1, 40) as n;

insert into public.packages (company_id, receipt_id, item_id, package_no, package_type, length_cm, width_cm, height_cm, gross_kg, status, damage_status, location_id, note)
select '10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000002', '71000000-0000-4000-8000-000000000002', n, 'pallet', 120, 100, 111, 238.67,
       case when n = 7 then 'repacked'::package_status else 'received'::package_status end,
       case when n = 7 then 'minor'::damage_status else 'none'::damage_status end,
       '51000000-0000-4000-8000-000000000003',
       case when n = 7 then 'Streç film yırtık; yeniden sarıldı, içerik sağlam' else null end
from generate_series(1, 18) as n;

insert into public.packages (company_id, receipt_id, item_id, package_no, package_type, length_cm, width_cm, height_cm, gross_kg, status, location_id)
select '10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000003', '71000000-0000-4000-8000-000000000003', n, 'carton', 50, 40, 35, 9.1, 'received', '51000000-0000-4000-8000-000000000002'
from generate_series(1, 12) as n;

insert into public.inspections (company_id, receipt_id, inspected_by, inspected_at, package_count, length_cm, width_cm, height_cm, gross_kg, measured_cbm, has_damage, damage_status, damage_description, is_missing, missing_count, was_repacked, was_palletized, note) values
('10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', '2026-09-01 03:10+00', 38, 60,  40,  40,  458.4,  3.6480,  false, 'none',  null, true,  2, false, true,  'Beklenen 40, gelen 38 koli. Tedarikçi irsaliyesinde 40 yazıyor; sürücü 38 teslim etti. Kırılgan koliler 2 palete alındı.'),
('10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000003', '2026-09-04 07:30+00', 18, 120, 100, 111, 4296.0, 23.9760, true,  'minor', 'Palet 7: streç film yırtık, kutular sağlam. Yeniden sarıldı.', false, 0, true,  false, 'Beyan 110 cm, ölçülen 111 cm.'),
('10000000-0000-4000-8000-000000000002', '73000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000003', '2026-09-08 02:20+00', 12, 50,  40,  35,  109.2,  0.8400,  false, 'none',  null, false, 0, false, false, 'Tam ve sağlam.');

insert into public.media_assets (id, company_id, entity_type, entity_id, media_type, storage_path, file_name, mime_type, file_size_bytes, caption, taken_at, uploaded_by) values
('7d000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000001', 'photo', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000001/kabul-01.jpg', 'kabul-01.jpg', 'image/jpeg', 2140000, 'S01 araç boşaltma — 38 koli',                '2026-09-01 02:25+00', '20000000-0000-4000-8000-000000000003'),
('7d000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000001', 'photo', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000001/etiket-01.jpg', 'etiket-01.jpg', 'image/jpeg', 1820000, 'Koli etiketi ve QR kod',                         '2026-09-01 02:40+00', '20000000-0000-4000-8000-000000000003'),
('7d000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000001', 'video', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000001/sayim.mp4',     'sayim.mp4',     'video/mp4',  38400000, 'Koli sayım videosu (38 koli)',                  '2026-09-01 02:50+00', '20000000-0000-4000-8000-000000000003'),
('7d000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000002', 'photo', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000002/palet-07-hasar.jpg', 'palet-07-hasar.jpg', 'image/jpeg', 2310000, 'Palet 7 streç film yırtığı',          '2026-09-04 06:55+00', '20000000-0000-4000-8000-000000000003'),
('7d000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000002', 'photo', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000002/palet-07-sarildi.jpg', 'palet-07-sarildi.jpg', 'image/jpeg', 2050000, 'Palet 7 yeniden sarıldı',         '2026-09-05 02:20+00', '20000000-0000-4000-8000-000000000003'),
('7d000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000003', 'photo', '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000003/kabul-01.jpg', 'kabul-01.jpg', 'image/jpeg', 1990000, 'S03 12 koli, A-02 rafı',                     '2026-09-08 02:00+00', '20000000-0000-4000-8000-000000000003');

insert into public.consolidation_items (consolidation_id, receipt_id, company_id, package_count, gross_kg, cbm, note) values
('74000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 38, 458.4,  3.6480,  '2 koli eksik, sonraki sefere'),
('74000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 18, 4296.0, 23.9760, null),
('74000000-0000-4000-8000-000000000001', '73000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 12, 109.2,  0.8400,  null);

-- ---------------------------------------------------------------------
-- Sevkiyat dosyaları ve konteyner yükleri
-- ---------------------------------------------------------------------
insert into public.shipments (id, shipment_no, company_id, customer_id, quotation_id, consolidation_id, schedule_id, container_id, hbl_no, transport_mode, incoterm, status, origin_port, destination_port, etd, eta, total_packages, total_gross_kg, total_cbm, chargeable_wm, delivery_address, delivery_city, delivery_district, insured_value, insurance_currency, created_by, created_at) values
('77000000-0000-4000-8000-000000000001', 'SVK-2026-00428', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', '75000000-0000-4000-8000-000000000001', '76000000-0000-4000-8000-000000000001', 'CCH-SHA-26-0428', 'sea_lcl', 'EXW', 'active', 'Shanghai', 'Ambarlı', '2026-09-18', '2026-10-22', 68, 4863.6, 28.4640, 28.4640, 'İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar', 'İstanbul', 'Bağcılar', 60830, 'USD', '20000000-0000-4000-8000-000000000002', '2026-08-24 10:10+03'),
('77000000-0000-4000-8000-000000000002', 'SVK-2026-00431', '10000000-0000-4000-8000-000000000004', '30000000-0000-4000-8000-000000000002', null, null, '75000000-0000-4000-8000-000000000001', '76000000-0000-4000-8000-000000000001', 'CCH-SHA-26-0431', 'sea_lcl', 'FOB', 'active', 'Shanghai', 'Ambarlı', '2026-09-18', '2026-10-22', 22, 6200.0, 15.5000, 15.5000, 'Merter Tekstil Sitesi No: 45, Güngören', 'İstanbul', 'Güngören', 41000, 'USD', '20000000-0000-4000-8000-000000000002', '2026-09-03 11:00+03');

insert into public.container_loads (container_id, consolidation_id, shipment_id, company_id, hbl_no, package_count, gross_kg, cbm, position_note) values
('76000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', '77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'CCH-SHA-26-0428', 68, 4863.6, 28.4640, 'Kırılgan LED paletleri üste, ağır paletler kapı tarafına'),
('76000000-0000-4000-8000-000000000001', null,                                   '77000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', 'CCH-SHA-26-0431', 22, 6200.0, 15.5000, null);

update public.shipment_requests set shipment_id = '77000000-0000-4000-8000-000000000001'
where id in ('70000000-0000-4000-8000-000000000001', '70000000-0000-4000-8000-000000000002', '70000000-0000-4000-8000-000000000003');

-- Zaman çizelgesi (tetikleyici: güncel durum + müşteri bildirimleri)
insert into public.shipment_milestones (shipment_id, company_id, milestone_code, occurred_at, recorded_by, description, location, next_expected_at, next_expected_note) values
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'request_created',         '2026-08-20 09:48+03', '20000000-0000-4000-8000-000000000005', 'Üç tedarikçi için taşıma talepleri oluşturuldu (TLP-2026-000426/427/428).', 'İstanbul', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'precheck_in_progress',    '2026-08-21 10:00+03', '20000000-0000-4000-8000-000000000002', 'GTİP, CE/TAREKS ve antidamping ön kontrolü yapıldı; 8 uyarı oluşturuldu.', 'İstanbul', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'quote_prepared',          '2026-08-22 16:40+03', '20000000-0000-4000-8000-000000000002', 'TKL-2026-00128 hazırlandı ve gönderildi (3.485,59 USD + vergiler).', 'İstanbul', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'quote_approved',          '2026-08-24 10:05+03', '20000000-0000-4000-8000-000000000005', 'Teklif dijital olarak onaylandı; %50 avans proforması düzenlendi.', 'İstanbul', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'supplier_contacted',      '2026-08-25 11:00+08', '20000000-0000-4000-8000-000000000002', 'Üç tedarikçiye depo teslim kodları (S01/S02/S03) ve yükleme talimatı iletildi.', 'Shanghai', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'picked_up_from_factory',  '2026-09-06 14:00+08', '20000000-0000-4000-8000-000000000003', 'Son tedarikçi (Shenzhen) fabrikadan alındı; Guangzhou 29 Ağustos, Foshan 2 Eylül.', 'Shenzhen', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'discrepancy_found',       '2026-09-01 11:10+08', '20000000-0000-4000-8000-000000000003', 'S01 Guangzhou Lighting: 40 koli beklenirken 38 koli geldi; 2 koli eksik.', 'Shanghai CN-SHA', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'arrived_cn_warehouse',    '2026-09-08 09:50+08', '20000000-0000-4000-8000-000000000003', 'Üç tedarikçinin yükü de Shanghai deposunda (S01 1 Eyl, S02 4 Eyl, S03 8 Eyl).', 'Shanghai CN-SHA', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'inspection_completed',    '2026-09-08 10:30+08', '20000000-0000-4000-8000-000000000003', 'Tüm yükler ölçüldü, tartıldı ve fotoğraflandı. Gerçek: 68 koli/palet, 4.863,6 kg, 28,46 CBM.', 'Shanghai CN-SHA', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'ready_for_consolidation', '2026-09-09 16:30+08', '20000000-0000-4000-8000-000000000003', 'KNS-2026-00042 hazır; palet 7 yeniden sarıldı, LED kolileri 2 palete alındı.', 'Shanghai CN-SHA', null, null),
('77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'container_booked',        '2026-09-10 09:20+03', '20000000-0000-4000-8000-000000000002', 'SEF-2026-00038 Shanghai → Ambarlı; konteyner CSNU6021874, MBL COSU6412345678.', 'İstanbul', '2026-09-15 18:00+08', 'Konteynere yükleme (cut-off 15 Eylül)'),
('77000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', 'container_booked',        '2026-09-10 09:25+03', '20000000-0000-4000-8000-000000000002', 'SEF-2026-00038 seferinde CSNU6021874 konteynerine rezerve edildi.', 'İstanbul', '2026-09-15 18:00+08', 'Konteynere yükleme');

-- ---------------------------------------------------------------------
-- Evraklar (yalnızca meta veri; dosyalar Storage''a Faz 2''de yüklenir)
-- ---------------------------------------------------------------------
insert into public.documents (id, company_id, entity_type, entity_id, document_type, title, storage_path, file_name, mime_type, file_size_bytes, status, is_customer_visible, uploaded_by, reviewed_by, reviewed_at, created_at) values
('7c000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000001', 'proforma_invoice',         'Proforma Fatura — Guangzhou Lighting (PI-GZL-26-0817)',   '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000001/pi-gzl-26-0817.pdf',  'pi-gzl-26-0817.pdf',  'application/pdf', 184000, 'approved',       true, '20000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:40+03', '2026-08-20 09:20+03'),
('7c000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000001', 'packing_list',             'Paketleme Listesi — Guangzhou Lighting',                  '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000001/pl-gzl-26-0817.pdf',  'pl-gzl-26-0817.pdf',  'application/pdf', 96000,  'approved',       true, '20000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:41+03', '2026-08-20 09:21+03'),
('7c000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000002', 'proforma_invoice',         'Proforma Fatura — Foshan Hardware (PI-FHW-26-0392)',      '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000002/pi-fhw-26-0392.pdf',  'pi-fhw-26-0392.pdf',  'application/pdf', 201000, 'approved',       true, '20000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:45+03', '2026-08-20 09:35+03'),
('7c000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000002', 'packing_list',             'Paketleme Listesi — Foshan Hardware',                     '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000002/pl-fhw-26-0392.pdf',  'pl-fhw-26-0392.pdf',  'application/pdf', 110000, 'approved',       true, '20000000-0000-4000-8000-000000000005', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:46+03', '2026-08-20 09:36+03'),
('7c000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000003', 'proforma_invoice',         'Proforma Fatura — Shenzhen Smart Systems (PI-SSS-26-1105)','10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000003/pi-sss-26-1105.pdf', 'pi-sss-26-1105.pdf',  'application/pdf', 176000, 'approved',       true, '20000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:50+03', '2026-08-20 09:50+03'),
('7c000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000003', 'packing_list',             'Paketleme Listesi — Shenzhen Smart Systems',              '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000003/pl-sss-26-1105.pdf',  'pl-sss-26-1105.pdf',  'application/pdf', 88000,  'approved',       true, '20000000-0000-4000-8000-000000000006', '20000000-0000-4000-8000-000000000002', '2026-08-21 09:51+03', '2026-08-20 09:51+03'),
('7c000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000001', 'ce_certificate',           'CE Uygunluk Beyanı — LED Panel 40W',                      '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000001/ce-led-panel-40w.pdf', 'ce-led-panel-40w.pdf', 'application/pdf', 640000, 'pending_review', true, '20000000-0000-4000-8000-000000000005', null, null, '2026-09-02 15:10+03'),
('7c000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000002', 'shipment_request',  '70000000-0000-4000-8000-000000000003', 'test_report',              'RED/EMC Test Raporu — Wi-Fi Priz',                        '10000000-0000-4000-8000-000000000002/shipment_request/70000000-0000-4000-8000-000000000003/red-emc-wifi-plug.pdf', 'red-emc-wifi-plug.pdf', 'application/pdf', 1450000, 'pending_review', true, '20000000-0000-4000-8000-000000000006', null, null, '2026-09-05 12:30+03'),
('7c000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000001', 'warehouse_receipt_report', 'Depo Kabul Tutanağı — S01 (38/40 koli, 2 eksik)',         '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000001/kabul-tutanagi-s01.pdf', 'kabul-tutanagi-s01.pdf', 'application/pdf', 320000, 'approved', true, '20000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000002', '2026-09-01 08:00+03', '2026-09-01 05:40+03'),
('7c000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002', 'warehouse_receipt', '73000000-0000-4000-8000-000000000002', 'damage_report',            'Hasar Tutanağı — S02 Palet 7 (streç film)',               '10000000-0000-4000-8000-000000000002/warehouse_receipt/73000000-0000-4000-8000-000000000002/hasar-tutanagi-s02.pdf', 'hasar-tutanagi-s02.pdf', 'application/pdf', 410000, 'approved', true, '20000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000002', '2026-09-04 12:00+03', '2026-09-04 10:10+03');

-- Eksik evrak uyarıları (müşteri paneli "Eksik evraklar" kartı)
insert into public.document_requirements (company_id, entity_type, entity_id, document_type, is_required, due_date, fulfilled_document_id, requested_by, note) values
('10000000-0000-4000-8000-000000000002', 'shipment', '77000000-0000-4000-8000-000000000001', 'commercial_invoice',    true, '2026-09-14', null, '20000000-0000-4000-8000-000000000004', 'Gümrük müşaviri talebi: 8302.42 kalemi ayrı faturada'),
('10000000-0000-4000-8000-000000000002', 'shipment', '77000000-0000-4000-8000-000000000001', 'certificate_of_origin', true, '2026-09-14', null, '20000000-0000-4000-8000-000000000004', 'Antidamping kontrolü için zorunlu'),
('10000000-0000-4000-8000-000000000002', 'shipment', '77000000-0000-4000-8000-000000000001', 'insurance_policy',      true, '2026-09-17', null, '20000000-0000-4000-8000-000000000002', 'Ticari fatura değerine göre düzenlenecek'),
('10000000-0000-4000-8000-000000000002', 'shipment', '77000000-0000-4000-8000-000000000001', 'packing_list',          true, '2026-09-14', '7c000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', 'Üç tedarikçinin listesi talep dosyalarında');

-- ---------------------------------------------------------------------
-- Gümrük dosyası (çözüm ortağına atandı, evrak bekliyor)
-- ---------------------------------------------------------------------
insert into public.customs_files (id, customs_file_no, company_id, shipment_id, partner_company_id, assigned_to, status, hs_code_proposed, regulation_note, estimated_customs_duty, estimated_vat, estimated_other_charges, estimate_currency, missing_documents_note, created_by, created_at) values
('78000000-0000-4000-8000-000000000001', 'GMR-2026-00214', '10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000004', 'awaiting_documents',
 '9405.11.40.00.00; 8302.42.00.00.00; 8517.62.00.00.19',
 'LED armatür ve telsiz ekipmanı için TAREKS başvurusu gerekli. 8302.42 menteşe kalemi antidamping listesinde; menşe belgesi ve üretici beyanı ile kontrol edilecek. Tahminler CIF ≈ 2.350.000 TRY üzerinden; GTİP kesinleşince güncellenir.',
 70500, 484000, 12500, 'TRY', 'Ticari fatura (kalem bazında) ve menşe belgesi bekleniyor.', '20000000-0000-4000-8000-000000000002', '2026-09-10 10:00+03');

-- ---------------------------------------------------------------------
-- Finans · %50 avans ödendi, %50 bakiye gemi hareketinde
-- ---------------------------------------------------------------------
insert into public.invoices (id, invoice_no, company_id, customer_id, shipment_id, quotation_id, invoice_type, status, currency, exchange_rate_try, subtotal, vat_rate, vat_amount, total, paid_amount, issue_date, due_date, note, created_by) values
('79000000-0000-4000-8000-000000000001', 'FTR-2026-00097', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '77000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', 'proforma', 'paid',   'USD', 41.38, 1742.80, 0, 0, 1742.80, 1742.80, '2026-08-24', '2026-08-27', 'TKL-2026-00128 · %50 avans', '20000000-0000-4000-8000-000000000002'),
('79000000-0000-4000-8000-000000000002', 'FTR-2026-00098', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '77000000-0000-4000-8000-000000000001', '72000000-0000-4000-8000-000000000001', 'proforma', 'issued', 'USD', 41.92, 1742.79, 0, 0, 1742.79, 0,       '2026-09-10', '2026-09-18', 'TKL-2026-00128 · %50 bakiye (gemi hareketi)', '20000000-0000-4000-8000-000000000002');

insert into public.invoice_items (invoice_id, company_id, sort_order, category, description_tr, quantity, unit_price, amount) values
('79000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 1, 'other', 'TKL-2026-00128 konsolide taşıma hizmeti — %50 avans',  1, 1742.80, 1742.80),
('79000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 1, 'other', 'TKL-2026-00128 konsolide taşıma hizmeti — %50 bakiye', 1, 1742.79, 1742.79);

insert into public.payments (id, payment_no, company_id, customer_id, invoice_id, shipment_id, amount, currency, exchange_rate_try, method, status, reference_no, reported_by, reported_at, verified_by, verified_at, paid_at, note) values
('7a000000-0000-4000-8000-000000000001', 'ODM-2026-00071', '10000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000001', '79000000-0000-4000-8000-000000000001', '77000000-0000-4000-8000-000000000001', 1742.80, 'USD', 41.41, 'bank_transfer', 'paid', 'HVL-2026-0825-113', '20000000-0000-4000-8000-000000000005', '2026-08-25 14:30+03', '20000000-0000-4000-8000-000000000002', '2026-08-26 09:15+03', '2026-08-26 09:15+03', 'Dekont müşteri tarafından yüklendi.');

insert into public.expenses (id, expense_no, company_id, shipment_id, consolidation_id, schedule_id, container_id, category, description, vendor_type, vendor_carrier_id, amount, currency, exchange_rate_try, amount_try, expense_date, is_unexpected, is_rebillable, payable_status, payable_due_date, paid_at, recorded_by) values
('7e000000-0000-4000-8000-000000000001', 'MSR-2026-00311', '10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', null, null, 'cn_pickup',            'Çin içi nakliye — 3 tedarikçi → Shanghai depo (Shanghai Huayun)', 'trucker',   '60000000-0000-4000-8000-000000000002', 255.00,  'USD', 41.85, 10671.75,  '2026-09-08', false, false, 'paid',   '2026-09-10', '2026-09-09 10:00+03', '20000000-0000-4000-8000-000000000002'),
('7e000000-0000-4000-8000-000000000002', 'MSR-2026-00312', '10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', null, null, 'cn_warehouse_receipt', 'Depo kabul + ölçüm/tartım (3 kabul)',                              'warehouse', null,                                   45.00,   'USD', 41.85, 1883.25,   '2026-09-08', false, false, 'unpaid', '2026-09-30', null, '20000000-0000-4000-8000-000000000002'),
('7e000000-0000-4000-8000-000000000003', 'MSR-2026-00313', '10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '74000000-0000-4000-8000-000000000001', null, null, 'repacking',            'Ek streç film ve palet değişimi (palet 7)',                        'warehouse', null,                                   18.00,   'USD', 41.85, 753.30,    '2026-09-05', true,  false, 'unpaid', '2026-09-30', null, '20000000-0000-4000-8000-000000000002'),
('7e000000-0000-4000-8000-000000000004', 'MSR-2026-00314', '10000000-0000-4000-8000-000000000001', null, null, '75000000-0000-4000-8000-000000000001', '76000000-0000-4000-8000-000000000001', 'main_freight',         'Konteyner navlunu — MBL COSU6412345678 (40HC, sefer geneli)',      'carrier',   '60000000-0000-4000-8000-000000000001', 2650.00, 'USD', 41.92, 111088.00, '2026-09-10', false, false, 'unpaid', '2026-09-20', null, '20000000-0000-4000-8000-000000000002');

-- ---------------------------------------------------------------------
-- Destek ve mesajlaşma
-- ---------------------------------------------------------------------
insert into public.support_tickets (id, ticket_no, company_id, shipment_id, category, subject, status, priority, created_by, assigned_to, partner_company_id, first_response_at, created_at) values
('7b000000-0000-4000-8000-000000000001', 'DST-2026-00056', '10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', 'missing_documents', 'Ticari fatura ve menşe belgesi (SVK-2026-00428)', 'waiting_customer', 'high', '20000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000003', '2026-09-10 09:20+03', '2026-09-10 09:18+03');

insert into public.messages (company_id, shipment_id, ticket_id, message_type, sender_id, body, attachments, is_internal, created_at) values
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', null, 'warehouse',      '20000000-0000-4000-8000-000000000003', 'S01 (Guangzhou Lighting) için 38 koli teslim alındı; 40 koli bekleniyordu, 2 koli eksik. Kabul fotoğrafları ve sayım videosu eklendi.', '[{"document_id": "7c000000-0000-4000-8000-000000000009"}, {"media_id": "7d000000-0000-4000-8000-000000000003"}]'::jsonb, false, '2026-09-01 05:45+03'),
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', null, 'damage_missing', '20000000-0000-4000-8000-000000000002', 'Eksik 2 koli için tedarikçiyle görüştük; 20 Eylül''e kadar depoya gönderilecek ve SEF-2026-00039 seferine bağlanacak. Ana yükün mevcut seferle gitmesini onaylıyor musunuz?', '[]'::jsonb, false, '2026-09-01 09:10+03'),
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', null, 'damage_missing', '20000000-0000-4000-8000-000000000005', 'Onaylıyoruz, ana yük mevcut seferle gitsin. Eksik koliler sonraki sefere kalsın.', '[]'::jsonb, false, '2026-09-01 10:30+03'),
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', null, 'general',        '20000000-0000-4000-8000-000000000002', 'Tedarikçi eksik koliler için ek nakliye ücreti talep etmedi. S01 için alt kabul açılacak.', '[]'::jsonb, true, '2026-09-01 10:45+03'),
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '7b000000-0000-4000-8000-000000000001', 'customs', '20000000-0000-4000-8000-000000000004', 'Antidamping kontrolü için 8302.42 kalemli (mobilya aksesuarı) ticari faturanın ayrı düzenlenmesi gerekiyor. Ticari fatura ve menşe belgesini 14 Eylül evrak cut-off''una kadar yükler misiniz?', '[]'::jsonb, false, '2026-09-10 09:15+03'),
('10000000-0000-4000-8000-000000000002', '77000000-0000-4000-8000-000000000001', '7b000000-0000-4000-8000-000000000001', 'missing_documents', '20000000-0000-4000-8000-000000000002', 'Gümrük müşavirimizin talebi yukarıda; evraklar yüklendiğinde dosya "İnceleniyor" durumuna alınacak.', '[]'::jsonb, false, '2026-09-10 09:20+03');

-- Operasyon bildirimleri (müşteri bildirimleri milestone tetikleyicisinden otomatik oluştu)
insert into public.notifications (company_id, user_id, event_key, title_tr, body_tr, entity_type, entity_id, channel, created_at) values
('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', 'schedule.cutoff_approaching', 'Cut-off yaklaşıyor: SEF-2026-00038', 'Shanghai → Ambarlı seferi cut-off 15 Eylül. CSNU6021874 doluluk %64,7 (44,0 / 68 CBM).', 'sailing_schedule', '75000000-0000-4000-8000-000000000001', 'in_app', '2026-09-12 08:00+03'),
('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', 'documents.missing',           'Eksik evrak: SVK-2026-00428',        'Ticari fatura, menşe belgesi ve sigorta poliçesi bekleniyor (son tarih 14 Eylül).', 'shipment', '77000000-0000-4000-8000-000000000001', 'in_app', '2026-09-12 08:00+03'),
('10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 'finance.invoice_due',         'Vadesi yaklaşan tahsilat: FTR-2026-00098', 'Örnek İthalat A.Ş. — 1.742,79 USD, vade 18 Eylül (gemi hareketi).', 'invoice', '79000000-0000-4000-8000-000000000002', 'in_app', '2026-09-12 08:00+03');
