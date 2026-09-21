-- =====================================================================
-- ChinaCargo Hub · Faz 2 · 0006
-- Kimlik senkronizasyonu, RLS yardımcı fonksiyonları ve yetkiler
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) auth.users → public.users senkronizasyonu
--    Yeni kayıt açıldığında profil satırı otomatik oluşur.
-- ---------------------------------------------------------------------
create or replace function app.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, email, full_name, phone)
  values (
    new.id,
    new.email,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(new.email, '@', 1)),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), '')
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = coalesce(public.users.full_name, excluded.full_name);
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_auth_user();

-- E-posta güncellenirse profile yansı
create or replace function app.handle_auth_user_email_change() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.email is distinct from old.email then
    update public.users set email = new.email where id = new.id;
  end if;
  return new;
end $$;

drop trigger if exists on_auth_user_email_change on auth.users;
create trigger on_auth_user_email_change
  after update of email on auth.users
  for each row execute function app.handle_auth_user_email_change();

-- ---------------------------------------------------------------------
-- 2) RLS yardımcıları — hepsi SECURITY DEFINER (RLS'i baypas ederek
--    company_users okur; böylece politika içinde özyineleme olmaz)
-- ---------------------------------------------------------------------

-- Kullanıcının aktif üye olduğu şirketler
create or replace function app.member_company_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select company_id from public.company_users
  where user_id = auth.uid() and status = 'active'
$$;

-- Operatör (platform) personeli mi?
create or replace function app.is_operator_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_users cu
    join public.companies c on c.id = cu.company_id
    where cu.user_id = auth.uid() and cu.status = 'active' and c.type = 'operator'
  )
$$;

-- Süper yönetici mi?
create or replace function app.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_users cu
    join public.roles r on r.id = cu.role_id
    where cu.user_id = auth.uid() and cu.status = 'active' and r.code = 'super_admin'
  )
$$;

-- Kullanıcının rollerinin herhangi biri bu izni veriyor mu?
create or replace function app.has_permission(p_code text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.company_users cu
    join public.role_permissions rp on rp.role_id = cu.role_id
    join public.permissions p on p.id = rp.permission_id
    where cu.user_id = auth.uid() and cu.status = 'active' and p.code = p_code
  )
$$;

-- Kullanıcının çözüm ortağı (partner) olarak üye olduğu şirketler
create or replace function app.partner_company_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select cu.company_id from public.company_users cu
  join public.companies c on c.id = cu.company_id
  where cu.user_id = auth.uid() and cu.status = 'active' and c.type = 'partner'
$$;

-- Çözüm ortağına atanmış sevkiyatlar (gümrük dosyası üzerinden)
create or replace function app.partner_shipment_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select cf.shipment_id from public.customs_files cf
  where cf.partner_company_id in (select app.partner_company_ids())
$$;

-- ---------------------------------------------------------------------
-- 3) Yetkiler (Supabase modeli: geniş GRANT + RLS kapısı)
--    RLS politikası olmayan tabloda erişim yine kapalıdır.
-- ---------------------------------------------------------------------
grant usage on schema public to anon, authenticated, service_role;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;
grant usage, select on all sequences in schema public to authenticated, anon;
grant execute on all functions in schema public to anon, authenticated, service_role;

alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant select on tables to anon;
alter default privileges in schema public grant execute on functions to anon, authenticated, service_role;

-- app şemasındaki yardımcılar politika içinden çağrılır
grant execute on all functions in schema app to anon, authenticated, service_role;
