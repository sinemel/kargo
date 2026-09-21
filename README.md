# ChinaCargo Hub — Veri Modeli · Güvenlik · Müşteri Paneli (Faz 1–3)

**Çin'den gelen tüm yükleriniz tek platformda.**

Spec'in 19. bölümündeki geliştirme sırasının ilk adımı: **veri modeli + kullanıcı rolleri**. PostgreSQL/Supabase üzerinde çalışır; Next.js uygulaması Faz 2'den itibaren bu şemanın üzerine kurulur. Bu paket lokal PostgreSQL 16 üzerinde baştan sona çalıştırılıp doğrulandı (5 migration + seed hatasız; tetikleyiciler, view'lar ve hesaplama fonksiyonları test edildi).

## Pakette ne var

| Dosya | İçerik |
|---|---|
| `supabase/migrations/20260912000001_init_enums.sql` | `app` şeması, Türkçe ICU collation, 38 enum tipi |
| `supabase/migrations/20260912000002_core_tables.sql` | users, companies, roles, permissions, role_permissions, company_users, customers, suppliers, warehouses, warehouse_locations, carriers, pricing_rules, system_settings, sequence_counters, milestone_types, legal_texts, consent_records + referans verisi (6 rol, 62 izin, 21 milestone tr/en/zh, 16 ayar, 4 fiyat kuralı) |
| `supabase/migrations/20260912000003_operations_tables.sql` | shipment_requests, shipment_items, precheck_flags, quotations, quotation_requests, quotation_items, quotation_item_costs, warehouse_receipts, packages, inspections, media_assets, consolidations, consolidation_items, sailing_schedules, containers, container_loads, shipments, shipment_milestones, documents, document_requirements, customs_files, delivery_orders |
| `supabase/migrations/20260912000004_finance_and_communication.sql` | invoices, invoice_items, payments, expenses, exchange_rates, support_tickets, messages, message_reads, notifications, webhook_endpoints, webhook_deliveries, activity_logs |
| `supabase/migrations/20260912000005_functions_triggers_views.sql` | Belge numaralandırma (TLP/TKL/SVK…), depo teslim kodu (CC-IST-2026-00428-S01), koli QR, rol-kapsam koruması, hesaplama motoru (CBM, W/M, hacimsel ağırlık, kural seçimi), teklif toplamı, milestone → güncel durum + müşteri bildirimi, işlem kaydı, 7 özet view, tüm tablolarda RLS açık |
| `supabase/migrations/20260915000006_auth_and_rls_helpers.sql` | **(Faz 2)** `auth.users → public.users` senkron tetikleyicisi, RLS yardımcı fonksiyonları, yetkiler (GRANT) |
| `supabase/migrations/20260915000007_rls_policies.sql` | **(Faz 2)** 51 tablo için 101 RLS politikası |
| `supabase/migrations/20260915000008_rpc_functions.sql` | **(Faz 2)** Kritik geçiş RPC'leri (teklif onayı/revizyon, ödeme bildirimi/doğrulama, milestone, gümrük atama) |
| `supabase/migrations/20260915000009_storage.sql` | **(Faz 2)** `documents` ve `media` kovaları + Storage politikaları (Supabase yoksa no-op) |
| `supabase/seed.sql` | Demo senaryosu (spec bölüm 18): Örnek İthalat A.Ş., 3 tedarikçi, eksik 2 koli, hasarlı palet, konsolide teklif (18 kalem), Shanghai → Ambarlı seferi, %64,7 dolu konteyner, gümrük dosyası, avans ödemesi, mesajlar |
| `supabase/tests/*.sql` | **(Faz 2)** RLS izolasyon ve RPC/yazma testleri (psql ile) |
| `docs/security-and-rls.md` | **(Faz 2)** Güvenlik modeli, politika özeti, RPC listesi, test sonuçları |
| `docs/project-assumptions.md` | **Proje Varsayımları** (40 madde) |
| `docs/roles-and-permissions.md` | Kullanıcı rolleri ve yetki tablosu |
| `docs/workflow.md` | Uygulama iş akışı, durum makineleri, 21 adım |
| `docs/data-model.mermaid` | ER diyagramı |

Toplam: **51 tablo, 7 view, 6 rol, 62 izin.**

## Çalıştırma (lokal Supabase)

Proje kökünde, tek satır halinde:

```
supabase init
supabase start
supabase db reset
```

`db reset` migration'ları sırayla uygular ve `supabase/seed.sql`'i yükler. TypeScript tiplerini üretmek için:

```
supabase gen types typescript --local > src/types/database.ts
```

Barındırılan projeye taşırken: `supabase link --project-ref <ref>` sonra `supabase db push`. Seed'deki `auth.users` satırları lokal içindir; barındırılan projede demo kullanıcıları Dashboard'dan aynı e-postalarla açın.

RLS ve RPC testlerini çalıştırmak (lokal): `psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" -f supabase/tests/01_rls_isolation.sql` ve `.../02_rpc_and_writes.sql`. Beklenen sonuçlar `docs/security-and-rls.md` içindedir.

## Demo hesaplar (şifre: `Demo1234!`)

| E-posta | Rol | Şirket |
|---|---|---|
| admin@chinacargohub.com | Süper Yönetici | ChinaCargo Hub Lojistik A.Ş. |
| operasyon@chinacargohub.com | Türkiye Operasyon | ChinaCargo Hub Lojistik A.Ş. |
| depo.shanghai@chinacargohub.com | Çin Depo Personeli | ChinaCargo Hub Lojistik A.Ş. |
| gumruk@bogazicigumruk.com | Gümrük Müşaviri | Boğaziçi Gümrük Müşavirliği |
| ayse@ornekithalat.com | Müşteri Yöneticisi | Örnek İthalat A.Ş. |
| mehmet@ornekithalat.com | Müşteri Kullanıcısı | Örnek İthalat A.Ş. |
| zeynep@marmaratekstil.com | Müşteri Yöneticisi | Marmara Tekstil Makine (ikinci müşteri, RLS testi için) |

## Demo senaryosunun anlık durumu (12 Eylül 2026)

- 3 talep → tek konsolide teklif **TKL-2026-00128**: 3.485,59 USD + vergiler (18 kalem; kesin / tahmini / dahil / hariç / sonra hesaplanacak). İç kârlılık: maliyet 2.275,12 USD, marj %34,7.
- Depo kabulleri: **S01** 38/40 koli (2 eksik, `discrepancy`), **S02** 18/18 palet (palet 7 yeniden sarıldı), **S03** 12/12 koli.
- **KNS-2026-00042** rezerve: 68 koli/palet, 4.863,6 kg, 28,46 CBM → **SEF-2026-00038** Shanghai → Ambarlı, cut-off 15 Eylül, ETD 18 Eylül, ETA 22 Ekim. Konteyner CSNU6021874 %64,7 dolu (iki müşteri).
- Sevkiyat **SVK-2026-00428** güncel adım: 11/21 "Konteyner rezervasyonu yapıldı". Müşteri kullanıcılarına 8 bildirim üretildi.
- Gümrük dosyası **GMR-2026-00214** çözüm ortağında, ticari fatura + menşe belgesi bekliyor (3 eksik evrak uyarısı).
- Finans: %50 avans ödendi (1.742,80 USD), %50 bakiye 18 Eylül vadeli. 4 gerçekleşen masraf, 1 beklenmeyen.

## Faz 3 — Next.js frontend (müşteri paneli)

Uçtan uca çalışan bir dikey dilim: **giriş → panel → tedarikçiler → taşıma talebi → teklif onayı**. Statik ekran değil; gerçek form doğrulama (Zod), canlı hesaplama (CBM ve hacim/ağırlık W-M) ve Supabase RPC çağrıları (`approve_quotation`, `request_quotation_revision`) içerir. Tüm veri erişimi Faz 2'deki RLS politikalarına tabidir; müşteri yalnızca kendi verisini ve satış kalemlerini görür, maliyet/masraf görmez.

**Stack:** Next.js 14 (App Router), TypeScript, Tailwind, shadcn/ui bileşenleri, React Hook Form + Zod, `@supabase/ssr` (sunucu/istemci/middleware), Lucide, sonner, next-themes (açık/koyu tema).

**Başlıca dosyalar:**

| Yol | Açıklama |
| --- | --- |
| `src/lib/supabase/{client,server,middleware}.ts` | Tarayıcı, sunucu ve middleware için Supabase istemcileri (anon anahtar + RLS; `service_role` kullanılmaz) |
| `src/lib/{calc,format,validators,constants,auth}.ts` | SQL hesaplama motorunun istemci ikizi, Türkçe biçimlendirme, Zod şemaları, enum etiketleri, oturum yardımcıları |
| `src/app/giris/` | Giriş ekranı (marka paneli + Suspense içinde form) |
| `src/app/(panel)/` | Korumalı panel düzeni (sidebar, üst bar, okunmamış bildirim) + dashboard |
| `src/app/(panel)/panel/tedarikcilerim/` | Tedarikçi CRUD (dialog form, soft-delete) |
| `src/app/(panel)/panel/taleplerim/` | Taşıma talebi listesi + çok kalemli yeni talep formu (canlı CBM/W-M) |
| `src/app/(panel)/panel/tekliflerim/` | Teklif listesi + detay (kalem dökümü) + onay/revizyon aksiyonları (RPC) |
| `src/app/actions/` | Server action'lar: kimlik, tedarikçi, talep |

**Çalıştırma:**

```bash
npm install
cp .env.example .env.local   # NEXT_PUBLIC_SUPABASE_URL ve NEXT_PUBLIC_SUPABASE_ANON_KEY doldurun
npm run dev                  # http://localhost:3000
```

Supabase tip üretimi (opsiyonel, tam tip için): `npm run gen:types`. Demo giriş: `ayse@ornekithalat.com` / `Demo1234!`.

**Doğrulama:** `npx tsc --noEmit` tertemiz; `npm run build` üretim derlemesi 10 rotayı hatasız üretir (`/giris` statik, panel rotaları dinamik).

> Not: Bu Next.js sürümü için bir güvenlik danışma uyarısı yayımlandı; üretim öncesi `next` yamalı bir sürüme yükseltilmeli.

## Faz planı

1. ✅ **Veri modeli + roller**
2. ✅ **Supabase Auth, RLS politikaları, Storage kuralları, kritik geçiş RPC'leri** — bu paket (101 politika, gerçek oturumlarla test edildi; `docs/security-and-rls.md`)
3. ✅ **Next.js iskeleti** (TypeScript, Tailwind, shadcn/ui, React Hook Form, Zod) + müşteri paneli: giriş, panel, tedarikçiler, taşıma talebi (canlı CBM/W-M hesabı), teklif onayı/revizyon — bu paket (`npm run build` ile üretim derlemesi doğrulandı)
4. Depo operasyonu: kabul ekranı, QR/koli, ölçüm, foto/video yükleme, eksik/hasar
5. Teklif motoru ve fiyatlandırma ekranları (maliyet dökümü, kârlılık, kur)
6. Konsolidasyon, sefer/konteyner yönetimi, doluluk göstergesi, yük takibi zaman çizelgesi
7. Finans: fatura, ödeme durumları, masraf, bakiye, raporlar (Recharts)
8. Herkese açık site, bildirim merkezi, webhook, test senaryoları, dağıtım

## Tasarım kararları (kısa)

- **Hassas finansal alanlar ayrı tablolarda** (`quotation_item_costs`, `expenses`): müşteri tablosuna sütun gizleme yerine tablo ayrımı; RLS ile daha güvenli.
- **RLS Faz 1'de açık ama politikasız**: istemci anahtarıyla hiçbir tablo okunamaz. Şema yanlışlıkla açık veri sızdırmaz.
- **Toplamlar view'da, kayıtta değil**: konsolidasyon/konteyner/sefer toplamları hesaplanır, tutarsızlık olmaz.
- **Numaralar ve kodlar tetikleyicide**: uygulama katmanı `request_no`, `delivery_code`, `qr_code` üretmez; elle verilirse tetikleyici dokunmaz.
- **21 adım tablo verisi, enum değil**: yeni adım eklemek veya etiket değiştirmek migration gerektirmez; tr/en/zh hazır.
- **Türkçe ICU collation** ad sütunlarında: İ/ı, Ş, Ç doğru sıralanır.

Ayrıntılar ve gerekçeler: `docs/project-assumptions.md`.
