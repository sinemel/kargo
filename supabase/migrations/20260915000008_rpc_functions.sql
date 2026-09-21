-- =====================================================================
-- ChinaCargo Hub · Faz 2 · 0008
-- Kritik geçişler için RPC'ler
-- Her fonksiyon SECURITY DEFINER'dır ve içeride yetki + kiracı kontrolü
-- yapar; böylece hangi sütunun kimin tarafından değişeceği garanti altındadır.
-- Doğrudan UPDATE yerine bu fonksiyonlar çağrılır.
-- =====================================================================

-- Yardımcı: aktif kullanıcı bu şirkete üye mi?
create or replace function app.is_member_of(p_company_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_users
    where user_id = auth.uid() and company_id = p_company_id and status = 'active'
  )
$$;

-- ---------------------------------------------------------------------
-- 1) Teklif onayı (müşteri) — quotations.respond + kendi şirketi
-- ---------------------------------------------------------------------
create or replace function public.approve_quotation(p_quotation_id uuid, p_note text default null)
returns public.quotations
language plpgsql security definer set search_path = public as $$
declare q public.quotations;
begin
  select * into q from public.quotations where id = p_quotation_id for update;
  if not found then raise exception 'Teklif bulunamadı' using errcode = 'P0002'; end if;

  if not (app.has_permission('quotations.respond') and app.is_member_of(q.company_id)) then
    raise exception 'Bu teklifi onaylama yetkiniz yok' using errcode = '42501';
  end if;
  if q.status not in ('sent', 'revision_requested') then
    raise exception 'Yalnızca gönderilmiş teklif onaylanabilir (mevcut durum: %)', q.status using errcode = 'P0001';
  end if;
  if q.valid_until < current_date then
    raise exception 'Teklifin geçerlilik süresi dolmuş (%). Revizyon isteyin.', q.valid_until using errcode = 'P0001';
  end if;

  update public.quotations
     set status = 'approved', approved_at = now(), approved_by = auth.uid(), customer_response_note = p_note
   where id = p_quotation_id
   returning * into q;

  -- kapsanan talepleri onaylı işaretle
  update public.shipment_requests
     set status = 'approved'
   where id in (select request_id from public.quotation_requests where quotation_id = p_quotation_id)
     and status in ('quoted', 'revision_requested');

  return q;
end $$;

-- ---------------------------------------------------------------------
-- 2) Teklif revizyon talebi (müşteri)
-- ---------------------------------------------------------------------
create or replace function public.request_quotation_revision(p_quotation_id uuid, p_note text)
returns public.quotations
language plpgsql security definer set search_path = public as $$
declare q public.quotations;
begin
  select * into q from public.quotations where id = p_quotation_id for update;
  if not found then raise exception 'Teklif bulunamadı' using errcode = 'P0002'; end if;
  if not (app.has_permission('quotations.respond') and app.is_member_of(q.company_id)) then
    raise exception 'Bu teklif için revizyon isteme yetkiniz yok' using errcode = '42501';
  end if;
  if q.status not in ('sent') then
    raise exception 'Yalnızca gönderilmiş teklif için revizyon istenebilir (mevcut durum: %)', q.status using errcode = 'P0001';
  end if;
  if p_note is null or length(trim(p_note)) < 3 then
    raise exception 'Revizyon gerekçesi zorunludur' using errcode = 'P0001';
  end if;

  update public.quotations
     set status = 'revision_requested', customer_response_note = p_note
   where id = p_quotation_id
   returning * into q;
  return q;
end $$;

-- ---------------------------------------------------------------------
-- 3) Ödeme bildirimi (müşteri) — finance.report_payment + kendi şirketi
--    "ödeme bildirildi" durumunda kayıt oluşturur.
-- ---------------------------------------------------------------------
create or replace function public.report_payment(
  p_invoice_id uuid,
  p_amount numeric,
  p_method payment_method default 'bank_transfer',
  p_reference_no text default null,
  p_receipt_document_id uuid default null,
  p_note text default null
)
returns public.payments
language plpgsql security definer set search_path = public as $$
declare inv public.invoices; pmt public.payments;
begin
  select * into inv from public.invoices where id = p_invoice_id;
  if not found then raise exception 'Fatura bulunamadı' using errcode = 'P0002'; end if;
  if not (app.has_permission('finance.report_payment') and app.is_member_of(inv.company_id)) then
    raise exception 'Bu fatura için ödeme bildirme yetkiniz yok' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Ödeme tutarı sıfırdan büyük olmalı' using errcode = 'P0001';
  end if;

  insert into public.payments (company_id, customer_id, invoice_id, shipment_id, amount, currency,
                               method, status, reference_no, receipt_document_id, reported_by, reported_at, note)
  values (inv.company_id, inv.customer_id, inv.id, inv.shipment_id, p_amount, inv.currency,
          p_method, 'reported', p_reference_no, p_receipt_document_id, auth.uid(), now(), p_note)
  returning * into pmt;
  return pmt;
end $$;

-- ---------------------------------------------------------------------
-- 4) Ödeme doğrulama (operatör) — finance.manage
--    reported → verified → paid; fatura paid_amount ve durumunu günceller.
-- ---------------------------------------------------------------------
create or replace function public.verify_payment(p_payment_id uuid, p_paid boolean default true)
returns public.payments
language plpgsql security definer set search_path = public as $$
declare pmt public.payments; inv public.invoices; v_paid numeric;
begin
  if not app.has_permission('finance.manage') then
    raise exception 'Ödeme doğrulama yetkiniz yok' using errcode = '42501';
  end if;
  select * into pmt from public.payments where id = p_payment_id for update;
  if not found then raise exception 'Ödeme bulunamadı' using errcode = 'P0002'; end if;
  if pmt.status not in ('reported', 'verified') then
    raise exception 'Yalnızca bildirilen ödeme doğrulanabilir (mevcut durum: %)', pmt.status using errcode = 'P0001';
  end if;

  update public.payments
     set status = (case when p_paid then 'paid' else 'verified' end)::payment_status,
         verified_by = auth.uid(), verified_at = now(),
         paid_at = case when p_paid then now() else paid_at end
   where id = p_payment_id
   returning * into pmt;

  -- fatura ödendi tutarını güncelle
  if p_paid and pmt.invoice_id is not null then
    select coalesce(sum(amount), 0) into v_paid
    from public.payments where invoice_id = pmt.invoice_id and status = 'paid';

    select * into inv from public.invoices where id = pmt.invoice_id for update;
    update public.invoices
       set paid_amount = v_paid,
           status = (case
                      when v_paid >= inv.total then 'paid'
                      when v_paid > 0 then 'partially_paid'
                      else inv.status::text
                    end)::invoice_status
     where id = pmt.invoice_id;
  end if;
  return pmt;
end $$;

-- ---------------------------------------------------------------------
-- 5) Milestone ekleme (operatör) — shipments.update_status
--    Tetikleyici güncel durumu ilerletir ve müşteri bildirimi üretir.
-- ---------------------------------------------------------------------
create or replace function public.add_shipment_milestone(
  p_shipment_id uuid,
  p_milestone_code text,
  p_description text default null,
  p_location text default null,
  p_occurred_at timestamptz default now(),
  p_next_expected_at timestamptz default null,
  p_next_expected_note text default null,
  p_document_id uuid default null,
  p_media_id uuid default null,
  p_customer_visible boolean default true
)
returns public.shipment_milestones
language plpgsql security definer set search_path = public as $$
declare s public.shipments; m public.shipment_milestones;
begin
  if not app.has_permission('shipments.update_status') then
    raise exception 'Yük durumu güncelleme yetkiniz yok' using errcode = '42501';
  end if;
  select * into s from public.shipments where id = p_shipment_id;
  if not found then raise exception 'Sevkiyat bulunamadı' using errcode = 'P0002'; end if;
  if not exists (select 1 from public.milestone_types where code = p_milestone_code) then
    raise exception 'Geçersiz milestone kodu: %', p_milestone_code using errcode = 'P0001';
  end if;

  insert into public.shipment_milestones (shipment_id, company_id, milestone_code, occurred_at, recorded_by,
                                          description, location, document_id, media_id,
                                          next_expected_at, next_expected_note, is_customer_visible)
  values (p_shipment_id, s.company_id, p_milestone_code, p_occurred_at, auth.uid(),
          p_description, p_location, p_document_id, p_media_id,
          p_next_expected_at, p_next_expected_note, p_customer_visible)
  returning * into m;
  return m;
end $$;

-- ---------------------------------------------------------------------
-- 6) Gümrük dosyası atama (operatör) — customs.manage
-- ---------------------------------------------------------------------
create or replace function public.assign_customs_file(
  p_customs_file_id uuid,
  p_partner_company_id uuid,
  p_assigned_to uuid default null
)
returns public.customs_files
language plpgsql security definer set search_path = public as $$
declare cf public.customs_files;
begin
  if not app.has_permission('customs.manage') then
    raise exception 'Gümrük dosyası atama yetkiniz yok' using errcode = '42501';
  end if;
  if not exists (select 1 from public.companies where id = p_partner_company_id and type = 'partner') then
    raise exception 'Geçersiz çözüm ortağı şirketi' using errcode = 'P0001';
  end if;

  update public.customs_files
     set partner_company_id = p_partner_company_id,
         assigned_to = p_assigned_to,
         status = case when status = 'pending_assignment' then 'assigned' else status end
   where id = p_customs_file_id
   returning * into cf;
  if not found then raise exception 'Gümrük dosyası bulunamadı' using errcode = 'P0002'; end if;
  return cf;
end $$;

-- ---------------------------------------------------------------------
-- 7) Bildirimi okundu işaretle (kullanıcı)
-- ---------------------------------------------------------------------
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  update public.notifications
     set is_read = true, read_at = now()
   where user_id = auth.uid() and is_read = false
     and (p_ids is null or id = any(p_ids));
  get diagnostics n = row_count;
  return n;
end $$;

-- RPC'ler yalnızca giriş yapmış kullanıcıya
revoke execute on function
  public.approve_quotation(uuid, text),
  public.request_quotation_revision(uuid, text),
  public.report_payment(uuid, numeric, payment_method, text, uuid, text),
  public.verify_payment(uuid, boolean),
  public.add_shipment_milestone(uuid, text, text, text, timestamptz, timestamptz, text, uuid, uuid, boolean),
  public.assign_customs_file(uuid, uuid, uuid),
  public.mark_notifications_read(uuid[])
from anon;
