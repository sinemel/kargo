\pset pager off
\set ON_ERROR_STOP off
set client_min_messages to warning;

\echo '================ 1) MÜŞTERİ İZOLASYONU — Zeynep (Marmara Tekstil) ================'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000007',false);
\echo '-- Görünen sevkiyatlar (beklenen: yalnızca SVK-2026-00431)'
select shipment_no from shipments order by 1;
\echo '-- Örnek İthalat teklifi (beklenen 0) | konteynerdeki diğer müşteri yükü (beklenen: yalnızca kendi CCH-SHA-26-0431) | Örnek depo kabulü (beklenen 0)'
select (select count(*) from quotations where company_id='10000000-0000-4000-8000-000000000002') as baska_teklif,
       (select string_agg(hbl_no,',') from container_loads) as gorunen_yukler,
       (select count(*) from warehouse_receipts) as gorunen_kabul;
reset role; select set_config('request.jwt.claim.sub','',false);

\echo ''
\echo '================ 2) MÜŞTERİ KENDİ VERİSİ — Ayşe (Örnek İthalat) ================'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
\echo '-- Kendi sevkiyatı (beklenen SVK-2026-00428) | satış kalemi (18) | ALIŞ MALİYETİ gizli mi (0) | masraf gizli mi (0)'
select (select string_agg(shipment_no,',') from shipments) as sevkiyat,
       (select count(*) from quotation_items) as satis_kalemi,
       (select count(*) from quotation_item_costs) as gorunen_maliyet,
       (select count(*) from expenses) as gorunen_masraf;
\echo '-- Kendi bakiyesi | bildirimleri | dahili not gizli mi'
select (select open_balance from customer_balance_v where currency='USD') as bakiye,
       (select count(*) from notifications) as bildirim,
       (select count(*) filter (where is_internal) from messages) as gorunen_dahili_not,
       (select count(*) filter (where not is_internal) from messages) as gorunen_normal_mesaj;
reset role; select set_config('request.jwt.claim.sub','',false);

\echo ''
\echo '================ 3) ÇÖZÜM ORTAĞI — Emre (Boğaziçi Gümrük) ================'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000004',false);
\echo '-- Atanan gümrük dosyası (GMR-2026-00214) | atanan sevkiyat (SVK-2026-00428) | teklif gizli (0) | fatura gizli (0)'
select (select string_agg(customs_file_no,',') from customs_files) as gumruk_dosyasi,
       (select string_agg(shipment_no,',') from shipments) as gorunen_sevkiyat,
       (select count(*) from quotations) as teklif,
       (select count(*) from invoices) as fatura;
reset role; select set_config('request.jwt.claim.sub','',false);

\echo ''
\echo '================ 4) OPERATÖR — Burak (TR Operasyon) ================'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',false);
\echo '-- Tüm sevkiyat (2) | maliyet (13) | masraf (4) | tüm depo kabulü (3)'
select (select count(*) from shipments) as sevkiyat,
       (select count(*) from quotation_item_costs) as maliyet,
       (select count(*) from expenses) as masraf,
       (select count(*) from warehouse_receipts) as kabul;
reset role; select set_config('request.jwt.claim.sub','',false);

\echo ''
\echo '================ 5) ANON (herkese açık site) ================'
set role anon; select set_config('request.jwt.claim.sub','',false);
select (select count(*) from warehouses) as public_depo,
       (select count(*) from system_settings) as public_ayar,
       (select count(*) from shipments) as sevkiyat_gizli,
       (select count(*) from customers) as musteri_gizli;
reset role;
