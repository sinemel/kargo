import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { RequestForm } from "./request-form";

export const metadata = { title: "Yeni taşıma talebi" };

export default async function NewRequestPage() {
  const supabase = createClient();
  const [{ data: suppliers }, { data: customer }] = await Promise.all([
    supabase.from("suppliers").select("id, name, default_incoterm, city, address").eq("is_active", true).is("deleted_at", null).order("name"),
    supabase.from("customers").select("default_delivery_address, default_delivery_city, default_delivery_district").maybeSingle(),
  ]);

  const defaultDelivery = [customer?.default_delivery_address, customer?.default_delivery_district, customer?.default_delivery_city]
    .filter(Boolean).join(", ");

  return (
    <div className="mx-auto max-w-5xl">
      <PageHeader
        title="Yeni taşıma talebi"
        description="Çin'den taşınacak yükünüzün bilgilerini girin. Ölçüleri girdikçe hacim ve ücretlendirilebilir ağırlık anlık hesaplanır."
      />
      <RequestForm suppliers={suppliers ?? []} defaultDelivery={defaultDelivery} />
    </div>
  );
}
