# Proje Varsayımları — ChinaCargo Hub (Faz 1)

Spec'te belirsiz kalan ya da birden fazla şekilde yorumlanabilecek iş kurallarında alınan kararlar. Her madde ilgili tablo/alanla eşleştirildi. İtiraz edilen madde bir sonraki fazda değiştirilebilir; veri modeli buna göre esnek tutuldu.

## A. Kiracı ve kullanıcı modeli

1. **Tek operatör şirketi.** `companies.type = 'operator'` ChinaCargo Hub'ın kendisidir. Süper yönetici, Türkiye operasyon ve Çin depo personeli bu şirkete bağlıdır.
2. **Gümrük müşavirleri ayrı şirkettir** (`companies.type = 'partner'`). Kullanıcıları yalnızca `customs_files.partner_company_id` kendi şirketi olan dosyalara ve o dosyanın sevkiyat/evraklarına erişir.
3. **Bir kullanıcı birden fazla şirkete üye olabilir** (`company_users`). Yetki şirket bazında rolle belirlenir. Rolün kapsamı (`roles.scope`) şirket türüyle eşleşmek zorundadır; tetikleyici uyumsuz atamayı reddeder.
4. **Müşteri şirketinin ticari profili** (`customers`: müşteri numarası, hesap yöneticisi, vade, kredi limiti) operatör tarafından yönetilir. Müşteri kaydı oluştuğunda `customers` satırı da açılır — Faz 2'de kayıt akışına bağlanacak.
5. **`customer_user` rolü teklif onaylayamaz ve ödeme bildiremez**; bu iki işlem `customer_admin`'e aittir. Spec "firma onaylar" diyor, kullanıcı düzeyinde ayrım bizim kararımız.
6. **KVKK onayı hem şirket hem kullanıcı düzeyinde** tutulur: `companies.kvkk_consent_*` (kurumsal) ve `consent_records` (kullanıcı, metin sürümü, IP). Metinler `legal_texts` tablosunda sürümlüdür; şu an taslak.

## B. Talep, teklif ve sevkiyat ilişkisi

7. **Bir taşıma talebi = bir tedarikçi / bir yükleme noktası.** Birden fazla tedarikçi için birden fazla talep açılır (spec'teki talep formunda tek tedarikçi alanı var).
8. **Bir teklif birden fazla talebi kapsayabilir** (`quotation_requests`). Demo teklifi üç talebi tek konsolide teklifte toplar. Talep başına ön teklif de aynı yapıyla mümkündür.
9. **Teklif revizyonu yeni sürüm satırıdır** (`quotations.version`, `previous_version_id`); eski sürüm `superseded` olur. Onaylanmış teklif değiştirilmez.
10. **Sevkiyat (`shipments`) teklif onayından sonra oluşur**; talepler `converted` durumuna geçip `shipment_id` alır. Konsolide sevkiyatta bir sevkiyat = bir HBL.
11. **21 adımlık takip `milestone_types` tablosundadır** (tr/en/zh etiketli, sıralı). "Eksiklik/hasar tespit edildi" `is_exception = true`: zaman çizelgesinde görünür ve bildirim üretir ama ilerlemeyi geriye almaz. Geçmişe dönük düşük sıralı adım girilebilir; güncel durum yalnızca ileri gider.
12. **Kısmi eksik yük** (demo'daki 2 koli): ana yük gider, eksik koliler sonraki sefere yeni bir depo kabulü (`S04` gibi) olarak bağlanır; müşteri onayı mesaj kaydıyla belgelenir.

## C. Numaralandırma ve kodlar

13. **Belge numaraları `ÖNEK-YIL-SIRA`** biçimindedir ve yıl bazında sıfırlanır (`sequence_counters`): TLP talep · TKL teklif · DPK depo kabul · KNS konsolidasyon · SEF sefer · SVK sevkiyat · GMR gümrük dosyası · TSL teslimat · FTR fatura · ODM ödeme · MSR masraf · DST destek. Numara elle verilmişse tetikleyici dokunmaz.
14. **Depo teslim kodu `CC-IST-YYYY-MMMMM-Snn`**: CC platform ön eki, IST varış merkezi (ikisi de `system_settings`), MMMMM 5 haneli müşteri numarası, Snn müşterinin o yılki kabul sırası. Her koli QR kodu `<teslim kodu>-Pnnn`.
15. **Konteyner numarası ISO 6346** biçiminde doğrulanır (4 harf + 7 rakam).

## D. Ölçü ve hesaplama

16. **Birimler:** ölçü cm, ağırlık kg, hacim m³ (CBM, 4 ondalık). CBM = En × Boy × Yükseklik / 1.000.000 × adet; `shipment_items` ve `packages` tablolarında generated column olarak hesaplanır, elle girilemez.
17. **W/M (deniz, demiryolu):** `max(CBM, kg ÷ kg_per_cbm, minimum)`; varsayılan 1 CBM = 1.000 kg, minimum 1 W/M. **Hava/ekspres:** `max(brüt kg, CBM × 1.000.000 ÷ bölen, minimum)`; bölen hava 6.000, ekspres 5.000; minimum hava 45 kg. Tüm değerler `pricing_rules` tablosunda mod + taşıyıcı bazında değiştirilebilir; taşıyıcıya özel kural genel kuralı ezer (`get_pricing_rule`, `calc_chargeable`).
18. **Teklif toplamı** yalnızca "Kesin" ve "Tahmini" kalemleri toplar (tetikleyici). "Dahil", "Hariç" ve "Daha sonra hesaplanacak" kalemler listede 0 tutarla görünür. Vergiler ilk teklifte "Daha sonra hesaplanacak"tır.
19. **Konsolidasyon, sefer ve konteyner toplamları denormalize edilmez**; `consolidation_summary_v`, `container_utilization_v`, `schedule_capacity_v` view'larından okunur. Doluluk oranı CBM bazlıdır; kg bazlı oran da verilir.
20. **Beyan ile ölçüm ayrıdır:** müşterinin girdiği değerler `declared_*`, deponun ölçtüğü `actual_*`. Teklif beyan üzerinden, gerçekleşen navlun ölçüm üzerinden hesaplanır (fark eşiği teklif özel şartlarında).

## E. Finans

21. **Teklif para birimi varsayılan USD.** TRY karşılığı için kur bilgisi teklifte JSON olarak (`quotations.exchange_rates`) saklanır; `exchange_rates` tablosu kur farkı raporu için tarihli kur tutar. Kur girişi ilk sürümde manuel (TCMB entegrasyonu sonraki faz).
22. **Alış maliyeti ve kâr müşterinin okuduğu tablolardan ayrıdır:** `quotation_item_costs` (tahmini) ve `expenses` (gerçekleşen). Faz 2 RLS'te bu tablolara ve `quotation_profitability_v` / `shipment_profit_v` view'larına yalnızca operatör rolleri erişir. Sütun bazlı gizleme yerine tablo ayrımı tercih edildi; PostgREST ile daha güvenli.
23. **Ödeme altyapısı yok.** `payments.status` akışı: `pending → reported → verified → paid` (spec'teki dört durum) + `rejected`. Dekont `documents` tablosuna yüklenir (`receipt_document_id`).
24. **Sonradan oluşan masraflar** `expenses.is_rebillable = true` ile işaretlenip `invoice_type = 'additional'` faturaya dönüşür; müşteri `expenses` tablosunu değil faturayı görür. Beklenmeyen masraf `is_unexpected` ile ayrıca raporlanır.
25. **Tedarikçi/taşıyıcı borçları** ayrı tablo yerine `expenses.payable_status` + `payable_due_date` ile izlenir. Sefer geneli masraflar (konteyner navlunu gibi) `company_id = operatör` ve `schedule_id/container_id` ile kaydedilir; dosya bazına dağıtım raporlama katmanında yapılır.
26. **Fatura bakiyesi** generated column (`invoices.balance = total − paid_amount`); `paid_amount` ödeme doğrulandığında uygulama katmanı günceller (Faz 7).

## F. Belge ve medya

27. **Resmî evrak ile depo fotoğraf/videosu ayrı tablolardır:** `documents` (sürümlü, onay durumlu, görünürlük bayraklı) ve `media_assets`.
28. **Storage yolu** `<company_id>/<entity_type>/<entity_id>/<dosya>` kuralına uyar; Faz 2 storage politikaları ilk klasörü şirket kimliği olarak okur. Kovalar: `documents` ve `media` (ikisi de özel).
29. **Belge eksikliği uyarısı** `document_requirements` ile modellenir; müşteri panelindeki "Eksik evraklar" kartı bu tablodan beslenir.

## G. Güvenlik

30. **RLS Faz 1'de tüm tablolarda açık, politika yok.** İstemci anahtarıyla hiçbir tablo okunamaz; yalnızca service role çalışır. Politikalar Faz 2'de eklenir — yanlışlıkla açık veri riski sıfır.
31. **`activity_logs`** kritik tablolarda insert/update/delete için otomatik doludur; update'te yalnızca değişen alanlar saklanır, `status` değişince `status_change` olarak işaretlenir. Giriş kayıtları Faz 2'de auth hook ile eklenir.
32. **`app` şeması** tetikleyici ve yardımcı fonksiyonlar içindir; PostgREST ile dışa açılmaz. Hesaplama fonksiyonları (`calc_*`) `public`'tedir ve istemciden çağrılabilir (maliyet hesaplama aracı için).

## H. Demo senaryosu

33. **Tek Çin toplama deposu (Shanghai)** varsayıldı; Guangzhou/Foshan/Shenzhen yükleri Çin içi nakliyeyle bu depoya gelir. Gerçek ağda Guangdong yükleri için Shenzhen deposu + Yantian/Shekou çıkışı daha ekonomiktir; spec'teki Shanghai/Ambarlı rotası korundu.
34. **Kurlar, fiyatlar, GTİP kodları ve TAREKS/antidamping uyarıları temsilidir.** Ön uygunluk uyarıları hukuki karar değildir; disclaimer metni `system_settings.precheck_disclaimer_tr`.
35. **Demo `auth.users` satırları yalnızca lokal Supabase içindir** (`supabase db reset`). Barındırılan projede kullanıcılar Dashboard/CLI ile aynı e-postalarla açılır; seed `on conflict` ile tekrar çalıştırılabilir.
36. **İkinci müşteri (Marmara Tekstil)** yalnızca aynı konteynerde iki müşterinin yükünü göstermek ve Faz 2'de "müşteri diğer müşteriyi göremez" testini yapmak için eklendi.

## I. Sonraki fazlarda netleşecekler

37. **Ön uygunluk kural motoru** (GTİP fasıl → uyarı eşlemesi) uygulama katmanında yazılacak; Faz 1'de yalnızca sonuç tablosu (`precheck_flags`) var.
38. **Arayüz dili Türkçe.** `milestone_types` gibi etiketli tablolar `name_en`/`name_zh` ile hazır; enum etiketleri uygulama katmanında sözlükten çevrilir. UI i18n altyapısı Faz 3'te.
39. **Zaman dilimi:** tüm zaman damgaları `timestamptz` (UTC). Depo ekranları `warehouses.timezone` (Asia/Shanghai), Türkiye ekranları Europe/Istanbul ile gösterir.
40. **Bildirim kanalları:** `notifications.channel` ve `webhook_endpoints` hazır; e-posta gönderimi ve WhatsApp webhook teslimi Faz 8'de. Şu an yalnızca uygulama içi kayıt üretilir.
