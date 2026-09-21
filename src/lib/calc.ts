// Hesaplama motoru — veritabanındaki calc_* fonksiyonlarının istemci ikizi.
// Ölçüler cm, ağırlık kg, hacim m³ (CBM). Canlı önizleme ve maliyet aracı için.
// Nihai/faturaya esas değerler her zaman sunucuda (SQL) hesaplanır.

export type TransportMode = "sea_lcl" | "rail_lcl" | "air_cargo" | "express" | "system_suggestion";

export interface PackageDims {
  lengthCm: number;
  widthCm: number;
  heightCm: number;
  count: number;
  grossKgPerPackage: number;
}

/** CBM = En × Boy × Yükseklik / 1.000.000 × adet */
export function calcCbm(lengthCm: number, widthCm: number, heightCm: number, count = 1): number {
  const v = (lengthCm * widthCm * heightCm) / 1_000_000 * count;
  return round(v, 4);
}

/** Hacimsel ağırlık = En × Boy × Yükseklik / bölen × adet (hava varsayılan 6000) */
export function calcVolumetricKg(
  lengthCm: number, widthCm: number, heightCm: number, count = 1, divisor = 6000,
): number {
  const v = (lengthCm * widthCm * heightCm) / divisor * count;
  return round(v, 3);
}

/** Deniz/demiryolu W/M = max(CBM, kg / kgPerCbm, minimum) */
export function calcChargeableWm(cbm: number, grossKg: number, kgPerCbm = 1000, min = 1): number {
  const byWeight = kgPerCbm > 0 ? grossKg / kgPerCbm : 0;
  return round(Math.max(cbm, byWeight, min), 4);
}

export interface PricingRule {
  transportMode: TransportMode;
  wmKgPerCbm: number | null;      // deniz/demiryolu
  volumetricDivisor: number | null; // hava/ekspres
  minChargeable: number;
  minChargeableUnit: "wm" | "kg";
}

export const DEFAULT_RULES: Record<Exclude<TransportMode, "system_suggestion">, PricingRule> = {
  sea_lcl:   { transportMode: "sea_lcl",  wmKgPerCbm: 1000, volumetricDivisor: null, minChargeable: 1,   minChargeableUnit: "wm" },
  rail_lcl:  { transportMode: "rail_lcl", wmKgPerCbm: 1000, volumetricDivisor: null, minChargeable: 1,   minChargeableUnit: "wm" },
  air_cargo: { transportMode: "air_cargo", wmKgPerCbm: null, volumetricDivisor: 6000, minChargeable: 45, minChargeableUnit: "kg" },
  express:   { transportMode: "express",  wmKgPerCbm: null, volumetricDivisor: 5000, minChargeable: 0.5, minChargeableUnit: "kg" },
};

export interface ChargeableResult {
  quantity: number;
  unit: "wm" | "kg";
}

/** Ücretlendirilebilir miktar: deniz/demiryolu → W/M, hava/ekspres → kg */
export function calcChargeable(
  mode: Exclude<TransportMode, "system_suggestion">, cbm: number, grossKg: number, rule?: PricingRule,
): ChargeableResult {
  const r = rule ?? DEFAULT_RULES[mode];
  if (mode === "air_cargo" || mode === "express") {
    const divisor = r.volumetricDivisor ?? 6000;
    const volKg = (cbm * 1_000_000) / divisor;
    return { quantity: round(Math.max(grossKg, volKg, r.minChargeable), 3), unit: "kg" };
  }
  const kgPerCbm = r.wmKgPerCbm ?? 1000;
  return { quantity: calcChargeableWm(cbm, grossKg, kgPerCbm, r.minChargeable), unit: "wm" };
}

/** Kalem listesinden toplam koli, brüt kg ve CBM */
export function sumItems(items: PackageDims[]) {
  return items.reduce(
    (acc, it) => {
      const cbm = calcCbm(it.lengthCm, it.widthCm, it.heightCm, it.count);
      const gross = round(it.grossKgPerPackage * it.count, 3);
      acc.packages += it.count;
      acc.cbm = round(acc.cbm + cbm, 4);
      acc.grossKg = round(acc.grossKg + gross, 3);
      return acc;
    },
    { packages: 0, cbm: 0, grossKg: 0 },
  );
}

/** Konsolidasyon tasarrufu tahmini: ayrı ayrı minimumlar vs birleşik W/M */
export function estimateConsolidationSavings(
  perItemMinWm: number, itemCount: number, combinedWm: number, ratePerWm: number,
): number {
  const separate = perItemMinWm * itemCount * ratePerWm;
  const combined = combinedWm * ratePerWm;
  return round(Math.max(separate - combined, 0), 2);
}

function round(v: number, digits: number): number {
  const f = 10 ** digits;
  return Math.round((v + Number.EPSILON) * f) / f;
}
