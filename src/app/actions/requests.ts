"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getSession } from "@/lib/auth";
import { shipmentRequestSchema, type ShipmentRequestInput } from "@/lib/validators";
import { sumItems } from "@/lib/calc";

export type CreateResult = { ok: true; requestNo: string | null; id: string } | { ok: false; error: string };

function clean(v: string | undefined): string | null {
  const t = (v ?? "").trim();
  return t.length ? t : null;
}

export async function createShipmentRequest(input: ShipmentRequestInput, submit: boolean): Promise<CreateResult> {
  const parsed = shipmentRequestSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "Geçersiz veri" };

  const session = await getSession();
  if (!session?.companyId) return { ok: false, error: "Oturum bulunamadı" };

  const supabase = createClient();

  // Müşteri kaydını bul (RLS ile yalnızca kendi şirketi görünür)
  const { data: customer } = await supabase
    .from("customers").select("id").eq("company_id", session.companyId).maybeSingle();
  if (!customer) return { ok: false, error: "Firmanıza ait müşteri kaydı bulunamadı. Lütfen operasyon ekibiyle iletişime geçin." };

  const d = parsed.data;
  const totals = sumItems(d.items.map((it) => ({
    lengthCm: it.lengthCm, widthCm: it.widthCm, heightCm: it.heightCm, count: it.packageCount, grossKgPerPackage: it.grossKgPerPackage,
  })));

  const { data: reqRow, error: reqErr } = await supabase
    .from("shipment_requests")
    .insert({
      company_id: session.companyId,
      customer_id: customer.id,
      supplier_id: clean(d.supplierId),
      origin_city: clean(d.originCity),
      pickup_address: clean(d.pickupAddress),
      incoterm: d.incoterm,
      delivery_address: d.deliveryAddress.trim(),
      delivery_city: clean(d.deliveryCity),
      delivery_district: clean(d.deliveryDistrict),
      requested_mode: d.requestedMode,
      cargo_ready_date: clean(d.cargoReadyDate),
      currency: d.currency,
      goods_value: d.goodsValue ?? null,
      declared_packages: totals.packages,
      declared_gross_kg: totals.grossKg,
      declared_cbm: totals.cbm,
      is_dangerous: d.isDangerous,
      is_stackable: d.isStackable,
      is_fragile: d.isFragile,
      customer_note: clean(d.customerNote),
      status: submit ? "submitted" : "draft",
      submitted_at: submit ? new Date().toISOString() : null,
      created_by: session.userId,
    })
    .select("id, request_no")
    .single();

  if (reqErr || !reqRow) return { ok: false, error: reqErr?.message ?? "Talep oluşturulamadı" };

  const items = d.items.map((it, i) => ({
    request_id: reqRow.id,
    company_id: session.companyId,
    line_no: i + 1,
    description: it.description.trim(),
    hs_code_estimated: clean(it.hsCodeEstimated),
    package_type: it.packageType,
    package_count: it.packageCount,
    length_cm: it.lengthCm,
    width_cm: it.widthCm,
    height_cm: it.heightCm,
    gross_kg_per_package: it.grossKgPerPackage,
    net_kg_per_package: it.netKgPerPackage ?? null,
    goods_value: it.goodsValue ?? null,
    currency: d.currency,
    is_dangerous: it.isDangerous,
    is_stackable: it.isStackable,
    is_fragile: it.isFragile,
  }));

  const { error: itemErr } = await supabase.from("shipment_items").insert(items);
  if (itemErr) return { ok: false, error: itemErr.message };

  revalidatePath("/panel/taleplerim");
  return { ok: true, requestNo: reqRow.request_no, id: reqRow.id };
}
