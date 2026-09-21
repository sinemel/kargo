# Güvenlik ve Yetkilendirme (Faz 2) — ChinaCargo Hub

Faz 1'de şema kuruldu ve RLS tüm tablolarda açıldı ama politika yoktu (kapalı kapı). Faz 2 politikaları, kimlik senkronizasyonunu, Storage kurallarını ve kritik geçiş RPC'lerini ekler. Tümü lokal PostgreSQL 16'da gerçek kullanıcı oturumları taklit edilerek test edildi (aşağıda sonuçlar).

## Migration'lar

| Dosya | İçerik |
|---|---|
| `..._0006_auth_and_rls_helpers.sql` | `auth.users → public.users` senkron tetikleyicisi, RLS yardımcı fonksiyonları, GRANT'ler |
| `..._0007_rls_policies.sql` | 51 tablo için 101 politika |
| `..._0008_rpc_functions.sql` | Kritik geçişler için 7 `security definer` RPC |
| `..._0009_storage.sql` | `documents` ve `media` kovaları + Storage politikaları (Supabase yoksa no-op) |

## Kimlik senkronizasyonu

Supabase Auth'ta kayıt açılınca `auth.users`'a satır düşer; `on_auth_user_created` tetikleyicisi `public.users` profilini otomatik oluşturur (ad `raw_user_meta_data.full_name`'den). E-posta değişince profile yansır. Uygulama katmanı profil satırı oluşturmakla uğraşmaz.

## RLS modeli

Erişim, kullanıcının `company_users` üzerinden bağlı olduğu şirket(ler) ve rollerin verdiği izinlerle belirlenir. Politikalar şu yardımcı fonksiyonları kullanır (hepsi `security definer`; `company_users`'ı RLS'i baypas ederek okur, böylece politika içinde özyineleme olmaz):

| Fonksiyon | Döndürür |
|---|---|
| `app.member_company_ids()` | Kullanıcının aktif üye olduğu şirket kimlikleri |
| `app.is_operator_staff()` | Operatör (platform) personeli mi |
| `app.is_super_admin()` | Süper yönetici mi |
| `app.has_permission(code)` | Rollerinden herhangi biri bu izni veriyor mu |
| `app.partner_company_ids()` | Çözüm ortağı olarak üye olduğu şirketler |
| `app.partner_shipment_ids()` | Kendisine atanmış gümrük dosyalarının sevkiyatları |
| `app.is_member_of(company_id)` | Belirli şirkete aktif üye mi (RPC'lerde) |

### Temel erişim desenleri

- **Kiracı okuma:** `app.is_operator_staff() OR company_id IN (app.member_company_ids())` — müşteri yalnızca kendi şirketinin satırlarını görür.
- **Yetkiye bağlı yazma:** `WITH CHECK (app.has_permission('...') AND company_id IN (app.member_company_ids()))` — hem izin hem kiracı doğrulanır.
- **Çözüm ortağı:** gümrük dosyası, atanan sevkiyat ve o sevkiyatın evrakları/mesajları ile sınırlı.
- **Hassas finans** (`quotation_item_costs`, `expenses`): yalnızca izinli operatör rolleri; müşteri sorgularsa 0 satır döner.
- **Herkese açık (anon):** yalnızca `is_public` sistem ayarları, aktif yasal metinler, aktif+public depolar, fiyat kuralları (maliyet hesaplama aracı için).

### Tablo bazında özet

| Grup | Okuma | Yazma |
|---|---|---|
| roles, permissions, milestone_types | authenticated | `roles.manage` / `settings.manage` |
| system_settings, legal_texts, warehouses | anon (public kayıtlar) | `settings.manage` / `warehouses.manage` |
| pricing_rules, exchange_rates | authenticated | `pricing_rules.manage` / `finance.manage` |
| companies, company_users, customers | operatör + kendi şirketi | `companies.manage` / `users.manage_own` |
| suppliers | operatör + kendi | `suppliers.manage_own` + kendi şirketi |
| shipment_requests, items, precheck_flags | operatör + kendi | `requests.*` / `precheck.manage` |
| quotations, quotation_items | operatör + kendi | `quotations.prepare` (onay/revizyon RPC) |
| **quotation_item_costs** | — | **`quotations.view_costs`** (müşteriye kapalı) |
| warehouse_receipts, packages, inspections | operatör + kendi | `warehouse.*` |
| media_assets | operatör + kendi (görünür) | `warehouse.upload_media` |
| consolidations, items | operatör + kendi | `consolidations.*` |
| sailing_schedules, containers | operatör + kendi sevkiyatının seferi | `schedules.manage` / `containers.manage` |
| **container_loads** | operatör + **kendi yükü** | `bookings.manage` (başka müşteri sızmaz) |
| shipments, milestones | operatör + kendi + ortak-atanan | `shipments.update_status` (RPC) |
| documents, document_requirements | operatör + kendi (görünür) + ortak-atanan | `documents.upload_*` |
| customs_files | operatör + kendi + atanan ortak | `customs.manage` / `customs.update_assigned` |
| delivery_orders | operatör + kendi | `deliveries.manage` / `deliveries.request` |
| invoices, invoice_items, payments | operatör + kendi | `finance.manage`; müşteri ödeme bildirir (RPC) |
| **expenses** | — | **`finance.record_expense` / `finance.view_reports`** (müşteriye kapalı) |
| support_tickets | operatör + kendi + atanan ortak | `tickets.create` / `tickets.manage` |
| messages | operatör + kendi + ortak; **dahili not yalnızca operatör** | `messages.send` (+`messages.internal`) |
| notifications, message_reads, consent_records | yalnızca sahibi | yalnızca sahibi |
| activity_logs | `activity_logs.view` | tetikleyici (definer) |
| webhook_endpoints/deliveries | `settings.manage` | `settings.manage` |
| sequence_counters | — (politikasız) | yalnızca `security definer` fonksiyonlar |
| users | kendi + operatör + aynı şirketten meslektaş | kendi profilini günceller |

## Kritik geçiş RPC'leri

Doğrudan `UPDATE` yerine bu `security definer` fonksiyonlar çağrılır; her biri içeride izin ve kiracı kontrolü yapar, hangi sütunun değişebileceğini denetler.

| Fonksiyon | Kim | Ne yapar |
|---|---|---|
| `approve_quotation(id, note)` | Müşteri (`quotations.respond`) | Teklifi `approved`; kapsanan talepleri `approved`; geçerlilik/durum doğrular |
| `request_quotation_revision(id, note)` | Müşteri | `revision_requested`; gerekçe zorunlu |
| `report_payment(invoice, amount, method, ref, doc, note)` | Müşteri (`finance.report_payment`) | `reported` durumunda ödeme kaydı |
| `verify_payment(payment, paid)` | Operatör (`finance.manage`) | `verified`/`paid`; fatura `paid_amount` ve durumunu günceller |
| `add_shipment_milestone(...)` | Operatör (`shipments.update_status`) | Milestone ekler; tetikleyici durumu ilerletir + bildirim |
| `assign_customs_file(file, partner, user)` | Operatör (`customs.manage`) | Dosyayı çözüm ortağına atar |
| `mark_notifications_read(ids)` | Kullanıcı | Kendi bildirimlerini okundu işaretler |

## Storage

İki özel kova: `documents` (25 MB, pdf/jpeg/png/office) ve `media` (200 MB, jpeg/png/webp/mp4/mov). Yol kuralı `<company_id>/<entity_type>/<entity_id>/<dosya>`; politika ilk klasörü (`storage.foldername(name)[1]`) kullanıcının şirketiyle karşılaştırır. Operatör tümüne erişir; müşteri yalnızca kendi şirket klasörüne yükler/okur; silme yalnızca operatör. Erişim imzalı URL ile (kovalar public değil).

## Test sonuçları (lokal, gerçek oturumlar)

101 politika, 51 tabloda RLS. Beş rol için oturum taklit edilerek doğrulandı:

**Müşteri izolasyonu (kritik):** Marmara Tekstil kullanıcısı yalnızca kendi sevkiyatını gördü; Örnek İthalat'ın teklifi, depo kabulleri ve **aynı konteynerdeki yükü** görünmedi (yalnızca kendi HBL'i). "Müşteri başka müşteriyi göremez" kuralı konteyner paylaşımına rağmen sağlandı.

**Hassas finans:** Müşteri 18 satış kalemini gördü ama alış maliyeti ve gerçekleşen masraf 0 satır; dahili notlar gizli.

**Çözüm ortağı:** Yalnızca atanan gümrük dosyası ve sevkiyat; teklif/fatura 0.

**RPC yetki denetimi:** `customer_user` (onay izni yok) ve başka müşteri teklif onayı → reddedildi; `customer_admin` onayı → başarı. Başka müşteri fatura ödemesi bildirimi → reddedildi. Müşteri ödeme doğrulama/milestone ekleme → reddedildi; operatör → başarı, fatura otomatik `paid`, durum ilerledi, müşteriye bildirim düştü.

**Yazma politikası:** Müşteri başka şirkete tedarikçi ekleyemedi (WITH CHECK); kendi şirketine ekledi.

**Anon:** Yalnızca public depo ve sistem ayarları; sevkiyat/müşteri 0.

## Faz 3'e devir

- RLS politikaları menü/buton görünürlüğünü değil erişimi yönetir; UI `role_permissions` okuyarak butonları gösterir, asıl kapı RLS'tedir.
- Next.js istemcisi `anon` anahtarıyla çalışır (RLS aktif); yalnızca güvenli sunucu işlemleri `service_role` kullanır.
- Kritik yazma işlemleri doğrudan `UPDATE` yerine RPC çağırır.
