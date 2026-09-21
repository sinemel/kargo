\pset pager off
\set ON_ERROR_STOP off
set client_min_messages to warning;

\echo '=== A) customer_user teklif onaylayamaz (Mehmet, quotations.respond YOK) → hata bekleniyor ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000006',false);
select approve_quotation('72000000-0000-4000-8000-000000000001');
reset role;

\echo ''
\echo '=== B) Başka müşteri (Zeynep) Örnek İthalat teklifini onaylayamaz → hata bekleniyor ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000007',false);
select approve_quotation('72000000-0000-4000-8000-000000000001');
reset role;

\echo ''
\echo '=== C) Yeni teklif oluştur, gönder, Ayşe onaylasın (customer_admin) → başarı ==='
-- operatör yeni teklif hazırlar
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',false);
insert into quotations (id, company_id, customer_id, status, transport_mode, valid_until, quote_date)
values ('72000000-0000-4000-8000-0000000000ff','10000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000001','sent','sea_lcl', current_date + 5, current_date);
reset role;
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
select quotation_no, status, approved_by is not null as onaylandi from approve_quotation('72000000-0000-4000-8000-0000000000ff','Uygundur, onaylıyoruz.');
reset role;

\echo ''
\echo '=== D) Ödeme bildirimi: Ayşe kendi faturasına (başarı), Zeynep aynı faturaya (hata) ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
select payment_no, status, amount from report_payment('79000000-0000-4000-8000-000000000002', 1742.79, 'bank_transfer', 'HVL-TEST-01');
reset role;
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000007',false);
select report_payment('79000000-0000-4000-8000-000000000002', 100, 'bank_transfer', 'HACK');
reset role;

\echo ''
\echo '=== E) Ödeme doğrulama: müşteri yapamaz (hata), operatör yapar (başarı, fatura paid olur) ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
select verify_payment((select id from payments where reference_no='HVL-TEST-01'));
reset role;
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',false);
select status from verify_payment((select id from payments where reference_no='HVL-TEST-01'), true);
select invoice_no, status, paid_amount, balance from invoices where id='79000000-0000-4000-8000-000000000002';
reset role;

\echo ''
\echo '=== F) Milestone: müşteri ekleyemez (hata), operatör ekler → durum ilerler + bildirim ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
select add_shipment_milestone('77000000-0000-4000-8000-000000000001','vessel_departed','Test');
reset role;
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',false);
select milestone_code from add_shipment_milestone('77000000-0000-4000-8000-000000000001','loaded_into_container','Konteynere yüklendi','Shanghai');
select shipment_no, current_milestone_code from shipments where id='77000000-0000-4000-8000-000000000001';
reset role;
\echo '-- Ayşe yeni bildirimi aldı mı? (loaded_into_container)'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000005',false);
select count(*) as yeni_bildirim from notifications where event_key='shipment.milestone.loaded_into_container';
reset role;

\echo ''
\echo '=== G) Müşteri doğrudan başka şirkete tedarikçi ekleyemez (WITH CHECK) → hata bekleniyor ==='
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000007',false);
insert into suppliers (company_id, name) values ('10000000-0000-4000-8000-000000000002','Sahte Tedarikçi');
reset role;
\echo '-- Kendi şirketine ekleyebilir → başarı'
set role authenticated; select set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000007',false);
insert into suppliers (company_id, name) values ('10000000-0000-4000-8000-000000000004','Marmara Tedarikçi') returning name;
reset role;
