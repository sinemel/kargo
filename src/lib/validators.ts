import { z } from "zod";

const trText = (min: number, max: number, msg: string) =>
  z.string().trim().min(min, msg).max(max, "Çok uzun");

// --- Tedarikçi ---
export const supplierSchema = z.object({
  name: trText(2, 200, "Tedarikçi adı zorunlu"),
  contactName: z.string().trim().max(120).optional().or(z.literal("")),
  phone: z.string().trim().max(40).optional().or(z.literal("")),
  email: z.string().trim().email("Geçersiz e-posta").max(160).optional().or(z.literal("")),
  wechat: z.string().trim().max(80).optional().or(z.literal("")),
  province: z.string().trim().max(120).optional().or(z.literal("")),
  city: z.string().trim().max(120).optional().or(z.literal("")),
  address: z.string().trim().max(400).optional().or(z.literal("")),
  addressType: z.enum(["factory", "warehouse", "office"]).default("factory"),
  defaultIncoterm: z.enum(["EXW", "FCA", "FOB", "CFR", "CIF", "DAP", "DDP", "OTHER"]).default("EXW"),
  productsSummary: z.string().trim().max(400).optional().or(z.literal("")),
  notes: z.string().trim().max(1000).optional().or(z.literal("")),
});
export type SupplierInput = z.infer<typeof supplierSchema>;

// --- Talep kalemi ---
export const requestItemSchema = z.object({
  description: trText(2, 400, "Ürün açıklaması zorunlu"),
  hsCodeEstimated: z.string().trim().max(20).optional().or(z.literal("")),
  packageType: z.enum(["carton", "pallet", "crate", "bag", "drum", "roll", "other"]).default("carton"),
  packageCount: z.coerce.number().int("Tam sayı olmalı").positive("Adet 0'dan büyük olmalı"),
  lengthCm: z.coerce.number().positive("En 0'dan büyük olmalı"),
  widthCm: z.coerce.number().positive("Boy 0'dan büyük olmalı"),
  heightCm: z.coerce.number().positive("Yükseklik 0'dan büyük olmalı"),
  grossKgPerPackage: z.coerce.number().nonnegative("Ağırlık negatif olamaz"),
  netKgPerPackage: z.coerce.number().nonnegative().optional(),
  goodsValue: z.coerce.number().nonnegative().optional(),
  isFragile: z.boolean().default(false),
  isStackable: z.boolean().default(true),
  isDangerous: z.boolean().default(false),
});
export type RequestItemInput = z.infer<typeof requestItemSchema>;

// --- Taşıma talebi ---
export const shipmentRequestSchema = z.object({
  supplierId: z.string().uuid("Tedarikçi seçin").optional().or(z.literal("")),
  originCity: z.string().trim().max(120).optional().or(z.literal("")),
  pickupAddress: z.string().trim().max(400).optional().or(z.literal("")),
  incoterm: z.enum(["EXW", "FCA", "FOB", "CFR", "CIF", "DAP", "DDP", "OTHER"]).default("EXW"),
  deliveryAddress: trText(5, 400, "Teslimat adresi zorunlu"),
  deliveryCity: z.string().trim().max(120).optional().or(z.literal("")),
  deliveryDistrict: z.string().trim().max(120).optional().or(z.literal("")),
  requestedMode: z.enum(["sea_lcl", "rail_lcl", "air_cargo", "express", "system_suggestion"]).default("system_suggestion"),
  cargoReadyDate: z.string().optional().or(z.literal("")),
  currency: z.enum(["USD", "EUR", "TRY", "CNY"]).default("USD"),
  goodsValue: z.coerce.number().nonnegative().optional(),
  isDangerous: z.boolean().default(false),
  isStackable: z.boolean().default(true),
  isFragile: z.boolean().default(false),
  customerNote: z.string().trim().max(1000).optional().or(z.literal("")),
  items: z.array(requestItemSchema).min(1, "En az bir ürün kalemi ekleyin"),
});
export type ShipmentRequestInput = z.infer<typeof shipmentRequestSchema>;

// --- Teklif yanıtı ---
export const quoteRevisionSchema = z.object({
  note: trText(3, 1000, "Revizyon gerekçesi zorunlu"),
});
export type QuoteRevisionInput = z.infer<typeof quoteRevisionSchema>;

// --- Giriş ---
export const loginSchema = z.object({
  email: z.string().trim().email("Geçerli bir e-posta girin"),
  password: z.string().min(6, "Şifre en az 6 karakter"),
});
export type LoginInput = z.infer<typeof loginSchema>;
