# Uygulama İş Akışı — ChinaCargo Hub

Talepten teslimata kadar akışın veri modeline karşılığı. Her adımda hangi tablo değişir, kim tetikler, müşteriye ne bildirilir.

## 1. Uçtan uca akış

| # | Adım | Kim | Tablo / durum | Otomatik sonuç |
|---|---|---|---|---|
| 1 | Tedarikçi ekle | Müşteri | `suppliers` | — |
| 2 | Taşıma talebi oluştur (kalemler, ölçüler, proforma, paketleme listesi, fotoğraf) | Müşteri | `shipment_requests` `draft → submitted`, `shipment_items`, `documents`, `media_assets` | `request_no` (TLP), CBM/kg generated column, talep toplamları `shipment_request_totals_v` |
| 3 | Ön uygunluk kontrolü | Sistem + TR Operasyon | `shipment_requests → precheck`, `precheck_flags` | Uyarıların yanında disclaimer (`system_settings`) |
| 4 | Teklif hazırla | TR Operasyon | `quotations draft`, `quotation_requests`, `quotation_items`, `quotation_item_costs` | Toplam tetikleyici ile; kârlılık `quotation_profitability_v` |
| 5 | Teklif gönder | TR Operasyon | `quotations → sent`, `shipment_requests → quoted` | Milestone `quote_prepared` → müşteri bildirimi |
| 6 | Teklif onayı / revizyon | Müşteri (admin) | `quotations → approved` veya `revision_requested` (yeni sürüm) | `quote_approved` milestone; `%50 avans` proforması (`invoices`) |
| 7 | Sevkiyat dosyası aç, teslim kodlarını üret | TR Operasyon | `shipments`, `shipment_requests → converted`, `warehouse_receipts expected` | `shipment_no` (SVK), `delivery_code` (CC-IST-…-Snn) |
| 8 | Tedarikçiyle iletişim, Çin içi nakliye | TR Operasyon / Depo | milestone `supplier_contacted`, `picked_up_from_factory` | Bildirim |
| 9 | Depo kabulü: koli sayımı, QR, ölçüm, tartım, foto/video | CN Depo | `warehouse_receipts → received/partially_received`, `packages`, `inspections`, `media_assets` | QR kod tetikleyici; milestone `arrived_cn_warehouse`, `inspection_completed` |
| 10 | Eksik / hasar | CN Depo | `warehouse_receipts → discrepancy`, `inspections.is_missing / damage_*`, `documents (damage_report)` | Milestone `discrepancy_found` (istisna) → bildirim; mesaj (`damage_missing`) |
| 11 | Yeniden paketleme / paletleme, konum | CN Depo | `warehouse_receipts.repacked_at / palletized_at / location_id`, `packages.status` | — |
| 12 | Konsolidasyon | TR Operasyon oluşturur, CN Depo hazırlar | `consolidations open → awaiting_cargo → ready`, `consolidation_items`, `warehouse_receipts → ready/consolidated` | `consolidation_summary_v`; milestone `ready_for_consolidation` |
| 13 | Sefer ve konteyner | Süper Yönetici (sefer), TR Operasyon (rezervasyon) | `sailing_schedules`, `containers`, `container_loads`, `consolidations → booked` | `container_utilization_v`, `schedule_capacity_v`; milestone `container_booked`; ikinci proforma (gemi hareketi vadeli) |
| 14 | Yükleme ve Çin çıkışı | CN Depo / TR Operasyon | `container_loads.loaded_at`, `containers → loaded/sealed`, `consolidations → loaded/shipped`, HBL/MBL `documents` | Milestone `loaded_into_container`, `cn_customs_cleared` |
| 15 | Deniz transit | TR Operasyon | `sailing_schedules → departed / in_transit / transshipment`, `shipments.atd` | Milestone `vessel_departed`, `at_transshipment_port` |
| 16 | Türkiye liman | TR Operasyon | `sailing_schedules → arrived / discharged`, `containers → arrived / unpacked`, `shipments.ata` | Milestone `arrived_tr_port`, `container_unpacked` |
| 17 | Gümrükleme | TR Operasyon atar, Gümrük Müşaviri işler | `customs_files pending_assignment → assigned → awaiting_documents → in_review → declared → (inspection) → taxes_pending → cleared → released`, `document_requirements` | Milestone `tr_customs_in_progress`, `tr_customs_completed`; vergi faturası (`invoice_type = tax_pass_through`) |
| 18 | Teslimat talebi ve yurtiçi dağıtım | Müşteri talep eder, TR Operasyon yönetir | `delivery_orders requested → planned → dispatched → delivered`, POD `documents (delivery_receipt)` | Milestone `out_for_delivery`, `delivered`; `shipments → delivered` |
| 19 | Masraf ve bakiye | TR Operasyon / Müşteri | `expenses` (gerçekleşen), `invoices`, `payments pending → reported → verified → paid` | `customer_balance_v`, `shipment_profit_v` |
| 20 | Mesajlaşma ve destek | Herkes | `messages`, `support_tickets open → in_review → waiting_* → resolved → closed` | — |

## 2. Durum makineleri

**Talep (`shipment_requests.status`)**
`draft → submitted → precheck → quoted → approved → converted`
Yan dallar: `quoted → revision_requested → quoted` · `quoted → rejected` · herhangi bir noktadan `cancelled` (sevkiyat açıldıktan sonra iptal sevkiyat üzerinden).

**Teklif (`quotations.status`)**
`draft → sent → approved` · `sent → revision_requested` (yeni sürüm `draft` açılır, eski `superseded`) · `sent → rejected` · `sent → expired` (geçerlilik tarihi geçince, uygulama katmanı).

**Depo kabulü (`warehouse_receipts.status`)**
`expected → received | partially_received → inspected → ready → consolidated`
`partially_received` ya da hasar → `discrepancy` (müşteri kararı sonrası `ready`'ye dönebilir). `cancelled` her aşamada.

**Konsolidasyon (`consolidations.status`)**
`open → awaiting_cargo → ready → booked → loaded → shipped → closed` · `cancelled`.

**Sefer (`sailing_schedules.status`)**
`planned → open → cut_off_passed → departed → in_transit → (transshipment) → arrived → discharged → completed` · `cancelled`.

**Konteyner (`containers.status`)**
`planned → booked → loading → loaded → sealed → shipped → arrived → unpacked → returned`.

**Gümrük dosyası (`customs_files.status`)**
`pending_assignment → assigned → awaiting_documents → in_review → declared → (inspection) → taxes_pending → cleared → released` · `blocked` (evrak/mevzuat engeli; çözülünce kaldığı yerden).

**Ödeme (`payments.status`)** — spec'teki dört durum
`pending` (ödeme bekleniyor) → `reported` (ödeme bildirildi, müşteri) → `verified` (kontrol edildi, operasyon) → `paid` (ödendi) · `rejected`.

**Destek kaydı (`support_tickets.status`)**
`open → in_review → waiting_customer | waiting_partner → resolved → closed`.

## 3. Yük takibi: 21 adım ve bildirim

| Sıra | Kod | Kim girer | Müşteri bildirimi |
|---|---|---|---|
| 1 | `request_created` | Sistem (talep gönderilince) | — |
| 2 | `precheck_in_progress` | TR Operasyon | — |
| 3 | `quote_prepared` | Sistem (teklif gönderilince) | ✓ |
| 4 | `quote_approved` | Sistem (müşteri onayında) | — |
| 5 | `supplier_contacted` | TR Operasyon | ✓ |
| 6 | `picked_up_from_factory` | CN Depo / TR Operasyon | ✓ |
| 7 | `arrived_cn_warehouse` | Sistem (depo kabulünde) | ✓ |
| 8 | `inspection_completed` | Sistem (kontrol kaydında) | ✓ |
| 9 | `discrepancy_found` *(istisna)* | Sistem (eksik/hasar kaydında) | ✓ |
| 10 | `ready_for_consolidation` | CN Depo | ✓ |
| 11 | `container_booked` | TR Operasyon | ✓ |
| 12 | `loaded_into_container` | CN Depo | ✓ |
| 13 | `cn_customs_cleared` | TR Operasyon | — |
| 14 | `vessel_departed` | TR Operasyon | ✓ |
| 15 | `at_transshipment_port` | TR Operasyon | — |
| 16 | `arrived_tr_port` | TR Operasyon | ✓ |
| 17 | `container_unpacked` | TR Operasyon | — |
| 18 | `tr_customs_in_progress` | Sistem (gümrük dosyası `in_review`) | ✓ |
| 19 | `tr_customs_completed` | Sistem (gümrük dosyası `released`) | ✓ |
| 20 | `out_for_delivery` | TR Operasyon | ✓ |
| 21 | `delivered` | TR Operasyon (POD ile) | ✓ |

Her milestone satırı tarih-saat, kaydeden kullanıcı, açıklama, konum, belge/fotoğraf bağı ve tahmini sonraki adım tarihi taşır (`shipment_milestones`). Tetikleyici sevkiyatın güncel durumunu ilerletir ve `notify_customer = true` ise müşteri şirketinin tüm aktif kullanıcılarına uygulama içi bildirim yazar; e-posta/WhatsApp kanalları aynı satırdan `webhook_deliveries` ile beslenir (Faz 8).

"Sistem" yazan adımlar Faz 3–6'da uygulama katmanındaki iş kurallarıyla otomatik eklenir; Faz 1'de tümü elle girilebilir.

## 4. Numaralandırma özeti

| Kayıt | Önek | Örnek |
|---|---|---|
| Taşıma talebi | TLP | TLP-2026-000428 |
| Teklif | TKL | TKL-2026-00128 |
| Depo kabulü | DPK | DPK-2026-00311 |
| Depo teslim kodu | CC-IST | CC-IST-2026-00428-S01 |
| Koli QR | — | CC-IST-2026-00428-S01-P001 |
| Konsolidasyon | KNS | KNS-2026-00042 |
| Sefer | SEF | SEF-2026-00038 |
| Sevkiyat / HBL | SVK | SVK-2026-00428 · CCH-SHA-26-0428 |
| Gümrük dosyası | GMR | GMR-2026-00214 |
| Teslimat | TSL | TSL-2026-00187 |
| Fatura | FTR | FTR-2026-00097 |
| Ödeme | ODM | ODM-2026-00071 |
| Masraf | MSR | MSR-2026-00312 |
| Destek kaydı | DST | DST-2026-00056 |
