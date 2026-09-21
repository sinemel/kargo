"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { getSession } from "@/lib/auth";
import { supplierSchema, type SupplierInput } from "@/lib/validators";

export type ActionResult = { ok: true } | { ok: false; error: string };

function clean(v: string | undefined): string | null {
  const t = (v ?? "").trim();
  return t.length ? t : null;
}

export async function saveSupplier(input: SupplierInput, id?: string): Promise<ActionResult> {
  const parsed = supplierSchema.safeParse(input);
  if (!parsed.success) return { ok: false, error: parsed.error.issues[0]?.message ?? "Geçersiz veri" };

  const session = await getSession();
  if (!session?.companyId) return { ok: false, error: "Oturum bulunamadı" };

  const supabase = createClient();
  const d = parsed.data;
  const row = {
    name: d.name.trim(),
    contact_name: clean(d.contactName),
    phone: clean(d.phone),
    email: clean(d.email),
    wechat: clean(d.wechat),
    province: clean(d.province),
    city: clean(d.city),
    address: clean(d.address),
    address_type: d.addressType,
    default_incoterm: d.defaultIncoterm,
    products_summary: clean(d.productsSummary),
    notes: clean(d.notes),
  };

  if (id) {
    const { error } = await supabase.from("suppliers").update(row).eq("id", id);
    if (error) return { ok: false, error: error.message };
  } else {
    const { error } = await supabase.from("suppliers").insert({
      ...row, company_id: session.companyId, created_by: session.userId,
    });
    if (error) return { ok: false, error: error.message };
  }
  revalidatePath("/panel/tedarikcilerim");
  return { ok: true };
}

export async function deleteSupplier(id: string): Promise<ActionResult> {
  const supabase = createClient();
  // Yumuşak silme: is_active=false + deleted_at
  const { error } = await supabase
    .from("suppliers")
    .update({ is_active: false, status: "inactive", deleted_at: new Date().toISOString() })
    .eq("id", id);
  if (error) return { ok: false, error: error.message };
  revalidatePath("/panel/tedarikcilerim");
  return { ok: true };
}
