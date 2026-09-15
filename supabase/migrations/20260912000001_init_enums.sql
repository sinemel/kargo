-- =====================================================================
-- ChinaCargo Hub · Faz 1 · 0001
-- Uzantılar, yardımcı şema, Türkçe collation ve enum tipleri
-- =====================================================================

create extension if not exists pgcrypto;

-- Tetikleyici ve yardımcı fonksiyonlar için özel şema (PostgREST ile dışa açılmaz)
create schema if not exists app;

-- Türkçe sıralama (İ/ı, Ş, Ç, Ğ, Ü, Ö) için ICU collation
create collation if not exists public.tr_tr (provider = icu, locale = 'tr-TR');

-- ---------------------------------------------------------------------
-- Enum tipleri (UI etiketleri uygulama katmanında Türkçe gösterilir)
-- ---------------------------------------------------------------------
create type public.company_type as enum ('operator', 'customer', 'partner');
create type public.member_status as enum ('invited', 'active', 'suspended');
create type public.incoterm as enum ('EXW', 'FCA', 'FOB', 'CFR', 'CIF', 'DAP', 'DDP', 'OTHER');
create type public.transport_mode as enum ('sea_lcl', 'rail_lcl', 'air_cargo', 'express', 'system_suggestion');
create type public.currency_code as enum ('USD', 'EUR', 'TRY', 'CNY');

create type public.request_status as enum (
  'draft', 'submitted', 'precheck', 'quoted', 'approved',
  'revision_requested', 'rejected', 'converted', 'cancelled'
);
create type public.quotation_status as enum (
  'draft', 'sent', 'approved', 'revision_requested', 'rejected', 'expired', 'superseded'
);

-- Teklif kalemi türü: Kesin / Tahmini / Dahil / Hariç / Daha sonra hesaplanacak
create type public.cost_certainty as enum ('fixed', 'estimated', 'included', 'excluded', 'to_be_calculated');

-- Teklif ve masraf kalem kategorileri (spec bölüm 4 · Aşama 3)
create type public.cost_category as enum (
  'cn_pickup',              -- Çin içi toplama
  'cn_warehouse_receipt',   -- Çin depo kabulü
  'measurement_weighing',   -- Ölçüm ve tartım
  'photo_video_check',      -- Fotoğraf/video kontrolü
  'consolidation',          -- Konsolidasyon
  'repacking',              -- Yeniden paketleme
  'palletizing',            -- Paletleme
  'cn_export_clearance',    -- Çin çıkış işlemleri
  'export_documents',       -- İhracat evrakları
  'main_freight',           -- Ana taşıma navlunu
  'fuel_and_surcharges',    -- Yakıt ve hat ek ücretleri
  'insurance',              -- Sigorta
  'tr_port_cfs',            -- Türkiye liman/CFS masrafları
  'documentation_ordino',   -- Belge ve ordino masrafları
  'customs_brokerage',      -- Gümrük müşavirliği
  'taxes_and_duties',       -- Tahmini vergi ve mali yükler
  'tr_domestic_delivery',   -- Türkiye içi dağıtım
  'platform_fee',           -- Platform hizmet bedeli
  'other'
);

-- Ön uygunluk risk uyarıları (spec bölüm 4 · Aşama 2)
create type public.risk_flag_type as enum (
  'hs_code_verification', 'tareks_check', 'surveillance_measure', 'antidumping',
  'import_license', 'ce_conformity', 'dangerous_goods', 'ipr_brand', 'regulated_product'
);
create type public.severity_level as enum ('info', 'warning', 'critical');

create type public.package_type as enum ('carton', 'pallet', 'crate', 'bag', 'drum', 'roll', 'other');
create type public.receipt_status as enum (
  'expected', 'partially_received', 'received', 'inspected', 'discrepancy', 'ready', 'consolidated', 'cancelled'
);
create type public.damage_status as enum ('none', 'minor', 'major');
create type public.package_status as enum ('expected', 'received', 'repacked', 'palletized', 'loaded', 'delivered', 'missing');
create type public.consolidation_status as enum ('open', 'awaiting_cargo', 'ready', 'booked', 'loaded', 'shipped', 'closed', 'cancelled');

create type public.schedule_status as enum (
  'planned', 'open', 'cut_off_passed', 'departed', 'in_transit', 'transshipment',
  'arrived', 'discharged', 'completed', 'cancelled'
);
create type public.container_type as enum ('20GP', '40GP', '40HC', '45HC', 'LCL_CFS');
create type public.container_status as enum ('planned', 'booked', 'loading', 'loaded', 'sealed', 'shipped', 'arrived', 'unpacked', 'returned');
create type public.shipment_status as enum ('active', 'on_hold', 'delivered', 'cancelled');

-- Evrak kategorileri (spec bölüm 9)
create type public.document_type as enum (
  'proforma_invoice', 'commercial_invoice', 'packing_list', 'purchase_contract', 'certificate_of_origin',
  'bill_of_lading', 'hbl', 'mbl', 'insurance_policy', 'conformity_certificate', 'test_report', 'ce_certificate',
  'customs_declaration', 'tax_and_expense_receipt', 'warehouse_receipt_report', 'damage_report',
  'delivery_receipt', 'other'
);
create type public.document_status as enum ('pending_review', 'approved', 'rejected', 'superseded');

-- Polimorfik bağ (documents, media_assets, notifications, document_requirements)
create type public.entity_type as enum (
  'company', 'supplier', 'shipment_request', 'quotation', 'warehouse_receipt', 'package', 'inspection',
  'consolidation', 'sailing_schedule', 'container', 'shipment', 'customs_file', 'delivery_order',
  'invoice', 'payment', 'expense', 'support_ticket'
);

create type public.customs_status as enum (
  'pending_assignment', 'assigned', 'awaiting_documents', 'in_review', 'declared',
  'inspection', 'taxes_pending', 'cleared', 'released', 'blocked'
);
create type public.inspection_lane as enum ('green', 'blue', 'yellow', 'red');
create type public.delivery_status as enum ('requested', 'planned', 'dispatched', 'delivered', 'failed', 'cancelled');

create type public.invoice_type as enum ('proforma', 'service', 'additional', 'tax_pass_through', 'credit_note');
create type public.invoice_status as enum ('draft', 'issued', 'partially_paid', 'paid', 'overdue', 'cancelled');
-- Ödeme durumları (spec bölüm 10: ödeme bekleniyor / bildirildi / kontrol edildi / ödendi)
create type public.payment_status as enum ('pending', 'reported', 'verified', 'paid', 'rejected');
create type public.payment_method as enum ('bank_transfer', 'credit_card', 'cash', 'other');
create type public.payable_status as enum ('not_applicable', 'unpaid', 'paid');
create type public.vendor_type as enum ('carrier', 'warehouse', 'customs_partner', 'trucker', 'supplier', 'other');
create type public.carrier_type as enum ('sea', 'rail', 'air', 'express', 'trucking_cn', 'trucking_tr');

-- Mesaj ve destek (spec bölüm 11)
create type public.message_type as enum (
  'general', 'quote_revision', 'missing_documents', 'warehouse', 'damage_missing',
  'customs', 'payment', 'delivery', 'urgent'
);
create type public.ticket_status as enum ('open', 'in_review', 'waiting_customer', 'waiting_partner', 'resolved', 'closed');
create type public.priority_level as enum ('low', 'normal', 'high', 'urgent');
create type public.notification_channel as enum ('in_app', 'email', 'whatsapp', 'sms');
create type public.media_type as enum ('photo', 'video');
