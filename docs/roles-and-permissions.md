# Kullanıcı Rolleri ve Yetki Tablosu — ChinaCargo Hub

Roller `roles`, izinler `permissions`, eşleme `role_permissions` tablosundadır. Kullanıcı ↔ şirket ↔ rol bağı `company_users` üzerinden kurulur; bir rol yalnızca kapsamındaki şirket türüne atanabilir.

## Roller

| Kod | Ad | Şirket türü | Özet |
|---|---|---|---|
| `super_admin` | Süper Yönetici | operator | Tüm şirketler, kullanıcılar, fiyat kuralları, depolar, taşıyıcılar, seferler, finansal raporlar, sistem ayarları, işlem kayıtları. 62/62 izin. |
| `tr_operations` | Türkiye Operasyon Personeli | operator | Talep inceleme, ön kontrol, teklif hazırlama/gönderme, rezervasyon, gümrük ve yurtiçi dağıtım koordinasyonu, masraf/evrak, mesajlaşma. 24 izin. |
| `cn_warehouse` | Çin Depo Personeli | operator | Depo kabul, koli/QR, ölçüm-tartım, fotoğraf-video, hasar/eksik bildirimi, paketleme-paletleme, konum, konsolidasyona hazırlama. 13 izin. |
| `customs_partner` | Gümrük Müşaviri / Çözüm Ortağı | partner | Yalnızca atanan gümrük dosyaları: evrak görme/eksik bildirme, GTİP önerisi, vergi tahmini, gümrük durumu, mesaj. 7 izin. |
| `customer_admin` | Kurumsal Müşteri Yöneticisi | customer | Firma ve kullanıcı yönetimi + tüm müşteri işlemleri (teklif onayı ve ödeme bildirimi dahil). 16 izin. |
| `customer_user` | Kurumsal Müşteri Kullanıcısı | customer | Talep, tedarikçi, evrak, takip, teslimat talebi, mesaj, destek. Kullanıcı yönetimi, teklif onayı ve ödeme bildirimi yok. 12 izin. |

## Modül bazında yetki matrisi

Kısaltmalar: **Tam** = oluştur/düzenle/gör (tüm şirketler) · **Kendi** = yalnızca kendi şirketinin kayıtları · **Atanan** = yalnızca atanan dosyalar · **Gör** = salt okunur · **—** = erişim yok

| Modül | Süper Yönetici | TR Operasyon | CN Depo | Gümrük Müşaviri | Müşteri Yöneticisi | Müşteri Kullanıcısı |
|---|---|---|---|---|---|---|
| Şirketler ve kullanıcılar | Tam | Gör | — | — | Kendi (firma + personel) | — |
| Rol ve yetkiler | Tam | — | — | — | — | — |
| Sistem ayarları, fiyat kuralları | Tam | Gör | — | — | — | — |
| Çin depoları, taşıyıcılar, çözüm ortakları | Tam | Gör | Gör (depo) | — | Gör (herkese açık depo listesi) | Gör |
| Tedarikçiler | Tam | Gör | Gör | — | Kendi | Kendi |
| Taşıma talepleri | Tam | İncele, durum değiştir | Gör | — | Kendi (oluştur) | Kendi (oluştur) |
| Ön uygunluk kontrolü | Tam | Tam | — | — | Gör (uyarılar) | Gör |
| Teklifler | Tam + maliyet/kâr | Hazırla, gönder, maliyet gör | — | — | Kendi: gör, **onayla / revizyon iste** | Kendi: gör |
| Depo kabul, koli, ölçüm, foto/video | Tam | Gör | **Tam** | — | Kendi: gör | Kendi: gör |
| Konsolidasyon | Tam | Oluştur, kapat, rezerve et | Hazırla (yük ekle, hazır işaretle) | — | Kendi: gör | Kendi: gör |
| Sefer ve konteyner | Tam | Rezervasyon | Gör, yükleme kaydı | — | Genel sefer durumu (kendi yükü) | Aynı |
| Sevkiyat ve yük takibi | Tam | Durum güncelle | Depo adımlarını güncelle | Atanan: gör | Kendi: gör | Kendi: gör |
| Evraklar | Tam + görünürlük | Tam + görünürlük + eksik bildir | Yükle (tutanak), atanan gör | Atanan: gör, yükle, eksik bildir | Kendi: gör, yükle | Kendi: gör, yükle |
| Gümrük dosyaları | Tam | Yönet, ata | — | **Atanan: GTİP, vergi tahmini, durum** | Kendi: gör | Kendi: gör |
| Yurtiçi dağıtım | Tam | Tam | — | — | Kendi: teslimat talebi | Kendi: teslimat talebi |
| Faturalar ve ödemeler | Tam | Fatura, tahsilat doğrulama | — | — | Kendi: bakiye gör, **ödeme bildir** | Kendi: bakiye gör |
| Masraflar (gerçekleşen maliyet) | Tam | Gir, gör | — | — | — | — |
| Finansal raporlar, kârlılık | Tam | — | — | — | — | — |
| Mesajlaşma | Tam + dahili not | Tam + dahili not | Gönder + dahili not | Atanan dosyalarda gönder | Kendi dosyalarında gönder | Aynı |
| Destek kayıtları | Tam | Yönet | — | Aç | Aç | Aç |
| Operasyon raporları | Tam | Gör | — | — | — | — |
| Yönetici gösterge paneli | Tam | — | — | — | — | — |
| İşlem kayıtları (activity_logs) | Gör | — | — | — | — | — |

## Rol bazında izin kodları

**super_admin:** tüm 62 izin.

**tr_operations (24):** `suppliers.view_all` · `requests.view_all` · `requests.review` · `precheck.manage` · `quotations.prepare` · `quotations.send` · `quotations.view_costs` · `consolidations.manage` · `consolidations.prepare` · `bookings.manage` · `shipments.update_status` · `shipments.view_all` · `documents.upload_all` · `documents.view_all` · `documents.set_visibility` · `documents.flag_missing` · `customs.manage` · `deliveries.manage` · `finance.manage` · `finance.record_expense` · `messages.send` · `messages.internal` · `tickets.manage` · `reports.operational`

**cn_warehouse (13):** `requests.view_all` · `shipments.view_all` · `warehouse.receive` · `warehouse.inspect` · `warehouse.upload_media` · `warehouse.report_discrepancy` · `warehouse.mark_ready` · `warehouse.assign_location` · `consolidations.prepare` · `documents.upload_all` · `documents.view_assigned` · `messages.send` · `messages.internal`

**customs_partner (7):** `customs.view_assigned` · `customs.update_assigned` · `documents.view_assigned` · `documents.upload_own` · `documents.flag_missing` · `messages.send` · `tickets.create`

**customer_admin (16):** `company.manage_own` · `users.manage_own` · `suppliers.manage_own` · `requests.create` · `requests.view_own` · `quotations.view_own` · `quotations.respond` · `consolidations.view_own` · `shipments.view_own` · `documents.upload_own` · `documents.view_own` · `deliveries.request` · `finance.view_own_balance` · `finance.report_payment` · `messages.send` · `tickets.create`

**customer_user (12):** `suppliers.manage_own` · `requests.create` · `requests.view_own` · `quotations.view_own` · `consolidations.view_own` · `shipments.view_own` · `documents.upload_own` · `documents.view_own` · `deliveries.request` · `finance.view_own_balance` · `messages.send` · `tickets.create`

## Faz 2'de bu tablonun karşılığı

- **RLS politikaları:** "Kendi" = `company_id` kullanıcının aktif üyeliklerinden birine eşit; "Atanan" = `customs_files.partner_company_id` eşleşmesi ve o dosyanın sevkiyatı; "Tam" = operatör rolleri.
- **Hassas finans:** `quotation_item_costs`, `expenses`, `quotation_profitability_v`, `shipment_profit_v` yalnızca `super_admin` ve `tr_operations` (kâr view'ları yalnızca `super_admin`).
- **Uygulama katmanı:** `role_permissions` menü/buton görünürlüğü için okunur; asıl güvenlik RLS'tedir.
- **Kritik geçişler RPC ile:** teklif onayı/revizyon, ödeme bildirimi, milestone ekleme — hangi sütunların değişebileceğini fonksiyon denetler.
