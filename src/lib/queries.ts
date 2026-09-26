import { createClient } from "@/lib/supabase/server";
import { DEMO_MODE } from "@/lib/demo";
import * as mock from "@/lib/mock";
import type { MockSupplier, MockRequest, MockQuotationRow, MockQuotationDetail, MockQuotationItem, MockNotif } from "@/lib/mock";

// Bu katman panelin tüm veri okumalarını tek yerde toplar. Demo (mock) modda
// gömülü örnek veriyi döndürür; aksi halde Supabase'i (RLS ile) sorgular.

export async function getUnreadCount(): Promise<number> {
  if (DEMO_MODE) return mock.unreadCount;
  const supabase = createClient();
  const { count } = await supabase.from("notifications").select("id", { count: "exact", head: true }).eq("is_read", false);
  return count ?? 0;
}

export interface DashboardData {
  receipts: { received_packages: number | null; actual_cbm: number | null; status: string }[];
  pendingQuotes: number;
  shipments: { id: string; shipment_no: string | null; status: string; eta: string | null; current_milestone_code: string | null }[];
  balance: { currency: string | null; open_balance: number; due_within_7_days: number }[];
  notifs: { id: string; title_tr: string; body_tr: string | null; created_at: string }[];
}

export async function getDashboardData(): Promise<DashboardData> {
  if (DEMO_MODE) {
    return {
      receipts: mock.receipts,
      pendingQuotes: mock.quotations.filter((q) => q.status === "sent").length,
      shipments: mock.shipments,
      balance: mock.balance,
      notifs: mock.notifications.map(({ id, title_tr, body_tr, created_at }) => ({ id, title_tr, body_tr, created_at })),
    };
  }
  const supabase = createClient();
  const [receipts, quotes, shipments, balance, notifs] = await Promise.all([
    supabase.from("warehouse_receipts").select("received_packages, actual_cbm, status").in("status", ["received", "inspected", "discrepancy", "ready"]),
    supabase.from("quotations").select("id").eq("status", "sent"),
    supabase.from("shipments").select("id, shipment_no, status, eta, current_milestone_code").eq("status", "active"),
    supabase.from("customer_balance_v").select("currency, open_balance, due_within_7_days").not("currency", "is", null),
    supabase.from("notifications").select("id, title_tr, body_tr, created_at").order("created_at", { ascending: false }).limit(6),
  ]);
  return {
    receipts: receipts.data ?? [],
    pendingQuotes: quotes.data?.length ?? 0,
    shipments: shipments.data ?? [],
    balance: (balance.data ?? []) as DashboardData["balance"],
    notifs: notifs.data ?? [],
  };
}

export async function listSuppliers(): Promise<MockSupplier[]> {
  if (DEMO_MODE) return mock.suppliers;
  const supabase = createClient();
  const { data } = await supabase
    .from("suppliers")
    .select("id, name, contact_name, phone, email, wechat, province, city, address, address_type, default_incoterm, products_summary, notes, rating")
    .eq("is_active", true).is("deleted_at", null).order("name");
  return (data ?? []) as MockSupplier[];
}

export interface SupplierOption { id: string; name: string; default_incoterm: string; city: string | null; address: string | null }

export async function listSupplierOptions(): Promise<SupplierOption[]> {
  if (DEMO_MODE) return mock.suppliers.map(({ id, name, default_incoterm, city, address }) => ({ id, name, default_incoterm, city, address }));
  const supabase = createClient();
  const { data } = await supabase.from("suppliers").select("id, name, default_incoterm, city, address").eq("is_active", true).is("deleted_at", null).order("name");
  return (data ?? []) as SupplierOption[];
}

export async function getDefaultDelivery(): Promise<string> {
  if (DEMO_MODE) return mock.defaultDelivery;
  const supabase = createClient();
  const { data: customer } = await supabase.from("customers").select("default_delivery_address, default_delivery_city, default_delivery_district").maybeSingle();
  return [customer?.default_delivery_address, customer?.default_delivery_district, customer?.default_delivery_city].filter(Boolean).join(", ");
}

export async function listRequests(): Promise<MockRequest[]> {
  if (DEMO_MODE) return mock.requests;
  const supabase = createClient();
  const { data } = await supabase
    .from("shipment_requests")
    .select("id, request_no, requested_mode, declared_packages, declared_cbm, status, created_at, suppliers:supplier_id ( name )")
    .order("created_at", { ascending: false });
  return (data ?? []) as unknown as MockRequest[];
}

export async function listQuotations(): Promise<MockQuotationRow[]> {
  if (DEMO_MODE) return mock.quotations;
  const supabase = createClient();
  const { data } = await supabase
    .from("quotations")
    .select("id, quotation_no, version, transport_mode, status, valid_until, total, currency, quote_date")
    .order("quote_date", { ascending: false });
  return (data ?? []) as MockQuotationRow[];
}

export async function getQuotationDetail(id: string): Promise<MockQuotationDetail | null> {
  if (DEMO_MODE) return mock.quotationDetail(id);
  const supabase = createClient();
  const { data } = await supabase
    .from("quotations")
    .select(`id, quotation_no, version, status, transport_mode, incoterm, currency, quote_date, valid_until,
      transit_days_min, transit_days_max, planned_departure_date, estimated_arrival_date, chargeable_wm,
      included_services, excluded_services, special_terms, payment_plan, cancellation_terms, delay_force_majeure_terms,
      subtotal, total, customer_response_note`)
    .eq("id", id).maybeSingle();
  return (data as unknown as MockQuotationDetail) ?? null;
}

export async function getQuotationItems(id: string): Promise<MockQuotationItem[]> {
  if (DEMO_MODE) return mock.quotationItems(id);
  const supabase = createClient();
  const { data } = await supabase
    .from("quotation_items")
    .select("id, sort_order, category, description_tr, certainty, quantity, unit, unit_price, amount, currency, note")
    .eq("quotation_id", id).order("sort_order");
  return (data ?? []) as MockQuotationItem[];
}
