-- =====================================================================
-- ChinaCargo Hub · Faz 2 · 0009
-- Supabase Storage kovaları ve erişim politikaları
-- Yol kuralı: <company_id>/<entity_type>/<entity_id>/<dosya>
-- storage.foldername(name)[1] = company_id
--
-- storage şeması yoksa (Supabase'siz lokal Postgres) tüm dosya no-op olur.
-- =====================================================================

do $$
begin
  if not exists (select 1 from information_schema.schemata where schema_name = 'storage') then
    raise notice 'storage şeması yok — Storage kurulumu atlandı (yalnızca gerçek Supabase''de çalışır).';
    return;
  end if;

  -- --- Kovalar (özel; imzalı URL ile erişim) ---
  insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values
    ('documents', 'documents', false, 26214400,
     array['application/pdf','image/jpeg','image/png',
           'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
           'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
    ('media', 'media', false, 209715200,
     array['image/jpeg','image/png','image/webp','video/mp4','video/quicktime'])
  on conflict (id) do update
    set file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

  -- Eski politikaları temizle (tekrar çalıştırılabilirlik)
  execute 'drop policy if exists cch_storage_read on storage.objects';
  execute 'drop policy if exists cch_storage_insert on storage.objects';
  execute 'drop policy if exists cch_storage_update on storage.objects';
  execute 'drop policy if exists cch_storage_delete on storage.objects';

  -- --- Okuma: operatör tümü; kullanıcı yalnızca kendi şirket klasörü ---
  execute $pol$
    create policy cch_storage_read on storage.objects for select to authenticated
    using (
      bucket_id in ('documents','media')
      and (
        app.is_operator_staff()
        or (storage.foldername(name))[1] in (select app.member_company_ids()::text)
      )
    )
  $pol$;

  -- --- Yükleme: operatör; ya da kullanıcı kendi şirket klasörüne ---
  execute $pol$
    create policy cch_storage_insert on storage.objects for insert to authenticated
    with check (
      bucket_id in ('documents','media')
      and (
        app.is_operator_staff()
        or (storage.foldername(name))[1] in (select app.member_company_ids()::text)
      )
    )
  $pol$;

  -- --- Güncelleme: yalnızca kendi şirket klasörü veya operatör ---
  execute $pol$
    create policy cch_storage_update on storage.objects for update to authenticated
    using (
      bucket_id in ('documents','media')
      and (
        app.is_operator_staff()
        or (storage.foldername(name))[1] in (select app.member_company_ids()::text)
      )
    )
  $pol$;

  -- --- Silme: yalnızca operatör (kalıcı silme kısıtlı) ---
  execute $pol$
    create policy cch_storage_delete on storage.objects for delete to authenticated
    using (bucket_id in ('documents','media') and app.is_operator_staff())
  $pol$;

  raise notice 'Storage kovaları ve politikaları kuruldu.';
end $$;
