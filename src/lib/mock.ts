// Demo (mock) modu için gömülü örnek veri — Örnek İthalat A.Ş. senaryosu.
// Hiçbir sunucu/Supabase importu YOK; hem sunucu (queries.ts) hem istemci
// (notifications-bell) bileşenleri güvenle import edebilir.
// Tüm kayıtlar birbiriyle tutarlıdır: 3 talep → konsolidasyon → TKL-2026-00128
// teklifi (kalem toplamı = 3.305,20 USD) → SVK-2026-00428 sevkiyatı.

const H = 3_600_000;
const D = 24 * H;
const iso = (offsetMs: number) => new Date(Date.now() + offsetMs).toISOString();

// ---- Tedarikçiler --------------------------------------------------------
export interface MockSupplier {
  id: string; name: string; contact_name: string | null; phone: string | null; email: string | null;
  wechat: string | null; province: string | null; city: string | null; address: string | null;
  address_type: string; default_incoterm: string; products_summary: string | null; notes: string | null;
  rating: number | null;
}

export const suppliers: MockSupplier[] = [
  {
    id: "sup-1", name: "Shenzhen Bright Electronics", contact_name: "Wang Lei",
    phone: "+86 138 0000 1001", email: "sales@szbright.cn", wechat: "szbright",
    province: "Guangdong", city: "Shenzhen", address: "Bao'an District, Hangcheng Ave 88",
    address_type: "factory", default_incoterm: "FOB", products_summary: "LED aydınlatma, elektronik aksesuar",
    notes: null, rating: 4,
  },
  {
    id: "sup-2", name: "Ningbo Homeware Co.", contact_name: "Chen Mei",
    phone: "+86 138 0000 1002", email: "info@nbhomeware.cn", wechat: "nbhomeware",
    province: "Zhejiang", city: "Ningbo", address: "Yinzhou District, Export Zone Rd 12",
    address_type: "warehouse", default_incoterm: "FOB", products_summary: "Mutfak & ev ürünleri",
    notes: null, rating: 5,
  },
  {
    id: "sup-3", name: "Guangzhou Textile Ltd.", contact_name: "Liu Yang",
    phone: "+86 138 0000 1003", email: "trade@gztextile.cn", wechat: null,
    province: "Guangdong", city: "Guangzhou", address: "Baiyun District, Textile City B4",
    address_type: "office", default_incoterm: "EXW", products_summary: "Kumaş, hazır giyim",
    notes: "Numune süreci 5 gün", rating: 4,
  },
];

export const defaultDelivery = "İstoç Ticaret Merkezi 28. Ada No: 112, Bağcılar, İstanbul";

// ---- Talepler ------------------------------------------------------------
export interface MockRequest {
  id: string; request_no: string | null; requested_mode: string; declared_packages: number | null;
  declared_cbm: number | null; status: string; created_at: string; suppliers: { name: string } | null;
}

export const requests: MockRequest[] = [
  { id: "req-1", request_no: "TLP-2026-00426", requested_mode: "sea_lcl", declared_packages: 40, declared_cbm: 12.5, status: "quoted", created_at: iso(-10 * D), suppliers: { name: "Shenzhen Bright Electronics" } },
  { id: "req-2", request_no: "TLP-2026-00427", requested_mode: "sea_lcl", declared_packages: 38, declared_cbm: 10.2, status: "quoted", created_at: iso(-9 * D), suppliers: { name: "Ningbo Homeware Co." } },
  { id: "req-3", request_no: "TLP-2026-00428", requested_mode: "sea_lcl", declared_packages: 22, declared_cbm: 6.4, status: "precheck", created_at: iso(-2 * D), suppliers: { name: "Guangzhou Textile Ltd." } },
];

// ---- Depo kabulleri (özet, dashboard) -----------------------------------
export const receipts = [
  { received_packages: 40, actual_cbm: 12.5, status: "ready" },
  { received_packages: 38, actual_cbm: 10.2, status: "received" },
  { received_packages: 22, actual_cbm: 6.4, status: "inspected" },
];

// ---- Aktif sevkiyatlar ---------------------------------------------------
export const shipments = [
  { id: "shp-1", shipment_no: "SVK-2026-00428", status: "active", eta: iso(9 * D), current_milestone_code: "vessel_departed" },
];

// ---- Müşteri bakiyesi (customer_balance_v) ------------------------------
export const balance = [
  { currency: "USD", open_balance: 1652.6, due_within_7_days: 1652.6 },
];

// ---- Bildirimler ---------------------------------------------------------
export interface MockNotif { id: string; title_tr: string; body_tr: string | null; created_at: string; is_read: boolean }

export const notifications: MockNotif[] = [
  { id: "ntf-1", title_tr: "Teklif hazır", body_tr: "TKL-2026-00128 numaralı teklifiniz onayınıza sunuldu.", created_at: iso(-4 * H), is_read: false },
  { id: "ntf-2", title_tr: "Depo teslim alma", body_tr: "Ningbo Homeware sevkiyatı Shanghai deposunda teslim alındı (38 koli).", created_at: iso(-1 * D), is_read: false },
  { id: "ntf-3", title_tr: "Ön kontrol tamamlandı", body_tr: "TLP-2026-00428 talebinin ön kontrolü tamamlandı.", created_at: iso(-2 * D), is_read: false },
  { id: "ntf-4", title_tr: "Konsolidasyon oluşturuldu", body_tr: "3 talebiniz KNS-2026-00042 altında birleştirildi.", created_at: iso(-3 * D), is_read: true },
  { id: "ntf-5", title_tr: "Sevkiyat yola çıktı", body_tr: "SVK-2026-00428 Ambarlı'ya doğru yola çıktı.", created_at: iso(-5 * D), is_read: true },
  { id: "ntf-6", title_tr: "Ödeme hatırlatması", body_tr: "FTR-2026-00098 faturasının %50 bakiyesi bu hafta vadeli.", created_at: iso(-6 * D), is_read: true },
];

export const unreadCount = notifications.filter((n) => !n.is_read).length;

// ---- Teklifler (liste) ---------------------------------------------------
export interface MockQuotationRow {
  id: string; quotation_no: string | null; version: number; transport_mode: string; status: string;
  valid_until: string; total: number; currency: string; quote_date: string;
}

export const quotations: MockQuotationRow[] = [
  { id: "q-128", quotation_no: "TKL-2026-00128", version: 1, transport_mode: "sea_lcl", status: "sent", valid_until: iso(3 * D), total: 3305.2, currency: "USD", quote_date: iso(-4 * D) },
  { id: "q-119", quotation_no: "TKL-2026-00119", version: 2, transport_mode: "sea_lcl", status: "approved", valid_until: iso(-20 * D), total: 2870.0, currency: "USD", quote_date: iso(-35 * D) },
];

// ---- Teklif detayı -------------------------------------------------------
export interface MockQuotationDetail {
  id: string; quotation_no: string | null; version: number; status: string; transport_mode: string;
  incoterm: string; currency: string; quote_date: string; valid_until: string;
  transit_days_min: number | null; transit_days_max: number | null;
  planned_departure_date: string | null; estimated_arrival_date: string | null; chargeable_wm: number | null;
  included_services: string[]; excluded_services: string[];
  special_terms: string | null; payment_plan: string | null; cancellation_terms: string | null;
  delay_force_majeure_terms: string | null; subtotal: number; total: number; customer_response_note: string | null;
}

export interface MockQuotationItem {
  id: string; sort_order: number; category: string; description_tr: string; certainty: string;
  quantity: number; unit: string; unit_price: number; amount: number; currency: string; note: string | null;
}

const q128Detail: MockQuotationDetail = {
  id: "q-128", quotation_no: "TKL-2026-00128", version: 1, status: "sent", transport_mode: "sea_lcl",
  incoterm: "FOB", currency: "USD", quote_date: iso(-4 * D), valid_until: iso(3 * D),
  transit_days_min: 22, transit_days_max: 30, planned_departure_date: iso(5 * D), estimated_arrival_date: iso(30 * D),
  chargeable_wm: 29.1,
  included_services: ["main_freight", "cn_warehouse_receipt", "consolidation", "cn_export_clearance", "export_documents", "documentation_ordino", "tr_domestic_delivery", "platform_fee"],
  excluded_services: ["taxes_and_duties"],
  special_terms: "Fiyat, 29,1 W/M ücretlendirilebilir hacim üzerinden geçerlidir. Nihai hacim depo ölçümüne göre güncellenebilir.",
  payment_plan: "%50 sevkiyat öncesi, %50 varışta (teslimattan önce).",
  cancellation_terms: "Konteyner yüklemesinden sonra iptal halinde navlun bedeli iade edilmez.",
  delay_force_majeure_terms: "Liman yoğunluğu ve mücbir sebeplerden kaynaklı gecikmeler taşıyıcı sorumluluğunda değildir.",
  subtotal: 3305.2, total: 3305.2, customer_response_note: null,
};

const q128Items: MockQuotationItem[] = [
  { id: "qi-1", sort_order: 1, category: "main_freight", description_tr: "Denizyolu navlun (LCL)", certainty: "fixed", quantity: 29.1, unit: "W/M", unit_price: 62, amount: 1804.2, currency: "USD", note: null },
  { id: "qi-2", sort_order: 2, category: "fuel_and_surcharges", description_tr: "Yakıt & ek ücretler", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 210, amount: 210, currency: "USD", note: null },
  { id: "qi-3", sort_order: 3, category: "cn_warehouse_receipt", description_tr: "Çin deposu teslim alma & elleçleme", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 120, amount: 120, currency: "USD", note: null },
  { id: "qi-4", sort_order: 4, category: "consolidation", description_tr: "Konsolidasyon (3 tedarikçi)", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 95, amount: 95, currency: "USD", note: null },
  { id: "qi-5", sort_order: 5, category: "cn_export_clearance", description_tr: "Çin ihracat gümrüklemesi", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 130, amount: 130, currency: "USD", note: null },
  { id: "qi-6", sort_order: 6, category: "export_documents", description_tr: "İhracat belgeleri", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 45, amount: 45, currency: "USD", note: null },
  { id: "qi-7", sort_order: 7, category: "tr_port_cfs", description_tr: "Türkiye liman / CFS masrafları", certainty: "estimated", quantity: 1, unit: "kalem", unit_price: 175, amount: 175, currency: "USD", note: "Liman tarifesine göre değişebilir" },
  { id: "qi-8", sort_order: 8, category: "documentation_ordino", description_tr: "Ordino & belge", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 60, amount: 60, currency: "USD", note: null },
  { id: "qi-9", sort_order: 9, category: "customs_brokerage", description_tr: "Gümrük müşavirliği", certainty: "estimated", quantity: 1, unit: "kalem", unit_price: 220, amount: 220, currency: "USD", note: null },
  { id: "qi-10", sort_order: 10, category: "insurance", description_tr: "Yük sigortası (%0,3)", certainty: "estimated", quantity: 1, unit: "kalem", unit_price: 96, amount: 96, currency: "USD", note: "Mal bedeli beyanına göre" },
  { id: "qi-11", sort_order: 11, category: "tr_domestic_delivery", description_tr: "İstanbul içi teslimat", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 260, amount: 260, currency: "USD", note: null },
  { id: "qi-12", sort_order: 12, category: "platform_fee", description_tr: "Platform & operasyon ücreti", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 90, amount: 90, currency: "USD", note: null },
];

const q119Detail: MockQuotationDetail = {
  id: "q-119", quotation_no: "TKL-2026-00119", version: 2, status: "approved", transport_mode: "sea_lcl",
  incoterm: "FOB", currency: "USD", quote_date: iso(-35 * D), valid_until: iso(-20 * D),
  transit_days_min: 24, transit_days_max: 32, planned_departure_date: iso(-30 * D), estimated_arrival_date: iso(-4 * D),
  chargeable_wm: 21.4,
  included_services: ["main_freight", "cn_warehouse_receipt", "consolidation", "tr_domestic_delivery", "platform_fee"],
  excluded_services: ["taxes_and_duties", "insurance"],
  special_terms: null,
  payment_plan: "%50 sevkiyat öncesi, %50 varışta.",
  cancellation_terms: "Yükleme sonrası iptalde navlun iade edilmez.",
  delay_force_majeure_terms: null,
  subtotal: 2870.0, total: 2870.0, customer_response_note: "Demiryolu yerine denizyolu tercih edildi.",
};

const q119Items: MockQuotationItem[] = [
  { id: "qj-1", sort_order: 1, category: "main_freight", description_tr: "Denizyolu navlun (LCL)", certainty: "fixed", quantity: 21.4, unit: "W/M", unit_price: 64, amount: 1369.6, currency: "USD", note: null },
  { id: "qj-2", sort_order: 2, category: "cn_warehouse_receipt", description_tr: "Çin deposu teslim alma", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 110, amount: 110, currency: "USD", note: null },
  { id: "qj-3", sort_order: 3, category: "consolidation", description_tr: "Konsolidasyon", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 90, amount: 90, currency: "USD", note: null },
  { id: "qj-4", sort_order: 4, category: "customs_brokerage", description_tr: "Gümrük müşavirliği", certainty: "estimated", quantity: 1, unit: "kalem", unit_price: 210, amount: 210, currency: "USD", note: null },
  { id: "qj-5", sort_order: 5, category: "tr_domestic_delivery", description_tr: "İstanbul içi teslimat", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 240, amount: 240, currency: "USD", note: null },
  { id: "qj-6", sort_order: 6, category: "platform_fee", description_tr: "Platform & operasyon ücreti", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 90, amount: 90, currency: "USD", note: null },
  { id: "qj-7", sort_order: 7, category: "tr_port_cfs", description_tr: "Liman / CFS masrafları", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 160, amount: 160, currency: "USD", note: null },
  { id: "qj-8", sort_order: 8, category: "fuel_and_surcharges", description_tr: "Yakıt & ek ücretler", certainty: "fixed", quantity: 1, unit: "kalem", unit_price: 600.4, amount: 600.4, currency: "USD", note: null },
];

const details: Record<string, { detail: MockQuotationDetail; items: MockQuotationItem[] }> = {
  "q-128": { detail: q128Detail, items: q128Items },
  "q-119": { detail: q119Detail, items: q119Items },
};

export function quotationDetail(id: string): MockQuotationDetail | null {
  return details[id]?.detail ?? null;
}
export function quotationItems(id: string): MockQuotationItem[] {
  return details[id]?.items ?? [];
}
