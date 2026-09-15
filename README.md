# ChinaCargo Hub — Faz 1: Veri Modeli ve Roller

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
| `supabase/seed.sql` | Demo senaryosu (spec bölüm 18): Örnek İthalat A.Ş., 3 tedarikçi, eksik 2 koli, hasarlı palet, konsolide teklif (18 kalem), Shanghai → Ambarlı seferi, %64,7 dolu konteyner, gümrük dosyası, avans ödemesi, mesajlar |
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

## Faz planı

1. ✅ **Veri modeli + roller** — bu paket
2. Supabase Auth, RLS politikaları, Storage kuralları, kritik geçişler için RPC'ler (teklif onayı, ödeme bildirimi, milestone)
3. Next.js iskeleti (TypeScript, Tailwind, shadcn/ui, React Hook Form, Zod) + müşteri paneli: tedarikçi, talep, teklif onayı
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
