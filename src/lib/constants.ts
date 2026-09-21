// Enum → Türkçe etiket ve durum → renk eşlemeleri.
// Arayüz dili Türkçe; en/zh sonraki fazda aynı yapıyla eklenir.

export type BadgeTone = "default" | "success" | "warning" | "danger" | "info" | "muted";

export const TRANSPORT_MODE: Record<string, string> = {
  sea_lcl: "Denizyolu LCL",
  rail_lcl: "Demiryolu parsiyel",
  air_cargo: "Havayolu kargo",
  express: "Ekspres kargo",
  system_suggestion: "Sistem önerisi",
};

export const INCOTERM: Record<string, string> = {
  EXW: "EXW", FCA: "FCA", FOB: "FOB", CFR: "CFR", CIF: "CIF", DAP: "DAP", DDP: "DDP", OTHER: "Diğer",
};

export const REQUEST_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  draft: { label: "Taslak", tone: "muted" },
  submitted: { label: "Gönderildi", tone: "info" },
  precheck: { label: "Ön kontrol", tone: "info" },
  quoted: { label: "Teklif verildi", tone: "warning" },
  approved: { label: "Onaylandı", tone: "success" },
  revision_requested: { label: "Revizyon istendi", tone: "warning" },
  rejected: { label: "Reddedildi", tone: "danger" },
  converted: { label: "Sevkiyata dönüştü", tone: "success" },
  cancelled: { label: "İptal", tone: "muted" },
};

export const QUOTATION_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  draft: { label: "Taslak", tone: "muted" },
  sent: { label: "Onayınızı bekliyor", tone: "warning" },
  approved: { label: "Onaylandı", tone: "success" },
  revision_requested: { label: "Revizyon istendi", tone: "info" },
  rejected: { label: "Reddedildi", tone: "danger" },
  expired: { label: "Süresi doldu", tone: "muted" },
  superseded: { label: "Güncellendi", tone: "muted" },
};

export const RECEIPT_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  expected: { label: "Bekleniyor", tone: "muted" },
  partially_received: { label: "Kısmi teslim", tone: "warning" },
  received: { label: "Teslim alındı", tone: "info" },
  inspected: { label: "Kontrol edildi", tone: "info" },
  discrepancy: { label: "Eksik/hasar", tone: "danger" },
  ready: { label: "Hazır", tone: "success" },
  consolidated: { label: "Konsolide edildi", tone: "success" },
  cancelled: { label: "İptal", tone: "muted" },
};

export const SHIPMENT_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  active: { label: "Aktif", tone: "info" },
  on_hold: { label: "Beklemede", tone: "warning" },
  delivered: { label: "Teslim edildi", tone: "success" },
  cancelled: { label: "İptal", tone: "muted" },
};

export const PAYMENT_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  pending: { label: "Ödeme bekleniyor", tone: "warning" },
  reported: { label: "Ödeme bildirildi", tone: "info" },
  verified: { label: "Kontrol edildi", tone: "info" },
  paid: { label: "Ödendi", tone: "success" },
  rejected: { label: "Reddedildi", tone: "danger" },
};

export const INVOICE_STATUS: Record<string, { label: string; tone: BadgeTone }> = {
  draft: { label: "Taslak", tone: "muted" },
  issued: { label: "Düzenlendi", tone: "info" },
  partially_paid: { label: "Kısmi ödendi", tone: "warning" },
  paid: { label: "Ödendi", tone: "success" },
  overdue: { label: "Gecikmiş", tone: "danger" },
  cancelled: { label: "İptal", tone: "muted" },
};

export const COST_CERTAINTY: Record<string, { label: string; tone: BadgeTone }> = {
  fixed: { label: "Kesin", tone: "success" },
  estimated: { label: "Tahmini", tone: "info" },
  included: { label: "Dahil", tone: "muted" },
  excluded: { label: "Hariç", tone: "warning" },
  to_be_calculated: { label: "Sonra hesaplanacak", tone: "warning" },
};

export const COST_CATEGORY: Record<string, string> = {
  cn_pickup: "Çin içi toplama",
  cn_warehouse_receipt: "Çin depo kabulü",
  measurement_weighing: "Ölçüm ve tartım",
  photo_video_check: "Fotoğraf/video kontrolü",
  consolidation: "Konsolidasyon",
  repacking: "Yeniden paketleme",
  palletizing: "Paletleme",
  cn_export_clearance: "Çin çıkış işlemleri",
  export_documents: "İhracat evrakları",
  main_freight: "Ana taşıma navlunu",
  fuel_and_surcharges: "Yakıt ve hat ek ücretleri",
  insurance: "Sigorta",
  tr_port_cfs: "Türkiye liman/CFS masrafları",
  documentation_ordino: "Belge ve ordino masrafları",
  customs_brokerage: "Gümrük müşavirliği",
  taxes_and_duties: "Vergi ve mali yükler",
  tr_domestic_delivery: "Türkiye içi dağıtım",
  platform_fee: "Platform hizmet bedeli",
  other: "Diğer",
};

export const SEVERITY: Record<string, { label: string; tone: BadgeTone }> = {
  info: { label: "Bilgi", tone: "info" },
  warning: { label: "Uyarı", tone: "warning" },
  critical: { label: "Kritik", tone: "danger" },
};

export const RISK_FLAG: Record<string, string> = {
  hs_code_verification: "GTİP doğrulaması",
  tareks_check: "TAREKS kontrolü",
  surveillance_measure: "Gözetim uygulaması",
  antidamping: "Antidamping riski",
  import_license: "İthalat izni",
  ce_conformity: "CE / uygunluk belgesi",
  dangerous_goods: "Tehlikeli madde",
  ipr_brand: "Marka / fikrî mülkiyet",
  regulated_product: "Özel ürün kontrolü",
};

export function label(map: Record<string, string>, key: string | null | undefined): string {
  if (!key) return "—";
  return map[key] ?? key;
}
