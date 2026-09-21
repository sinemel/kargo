import { Building2, Star } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { EmptyState } from "@/components/empty-state";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { label, INCOTERM } from "@/lib/constants";
import { SupplierForm, type SupplierRow } from "./supplier-form";
import { SupplierDelete } from "./supplier-delete";

export const metadata = { title: "Tedarikçilerim" };

const ADDRESS_TYPE: Record<string, string> = { factory: "Fabrika", warehouse: "Depo", office: "Ofis" };

export default async function SuppliersPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from("suppliers")
    .select("id, name, contact_name, phone, email, wechat, province, city, address, address_type, default_incoterm, products_summary, notes, rating")
    .eq("is_active", true)
    .is("deleted_at", null)
    .order("name");

  const suppliers = (data ?? []) as (SupplierRow & { rating: number | null })[];

  return (
    <>
      <PageHeader
        title="Tedarikçilerim"
        description="Çin'deki tedarikçilerinizi yönetin. Taşıma talebi oluştururken bu listeden seçim yaparsınız."
        action={<SupplierForm />}
      />

      {suppliers.length === 0 ? (
        <EmptyState
          icon={Building2}
          title="Henüz tedarikçi eklenmemiş"
          description="İlk Çinli tedarikçinizi ekleyerek başlayın. Ürün, iletişim ve teslim şekli bilgileri taşıma taleplerinde otomatik kullanılır."
          action={<SupplierForm />}
        />
      ) : (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Tedarikçi</TableHead>
                <TableHead>İletişim</TableHead>
                <TableHead>Konum</TableHead>
                <TableHead>Teslim</TableHead>
                <TableHead>Ürünler</TableHead>
                <TableHead className="text-right">İşlem</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {suppliers.map((s) => (
                <TableRow key={s.id}>
                  <TableCell>
                    <div className="font-medium">{s.name}</div>
                    <div className="text-xs text-muted-foreground">{label(ADDRESS_TYPE, s.address_type)}</div>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">{s.contact_name ?? "—"}</div>
                    <div className="text-xs text-muted-foreground">{s.phone ?? s.email ?? "—"}</div>
                  </TableCell>
                  <TableCell className="text-sm">{[s.city, s.province].filter(Boolean).join(", ") || "—"}</TableCell>
                  <TableCell><Badge tone="muted">{label(INCOTERM, s.default_incoterm)}</Badge></TableCell>
                  <TableCell className="max-w-48 truncate text-sm text-muted-foreground">{s.products_summary ?? "—"}</TableCell>
                  <TableCell>
                    <div className="flex items-center justify-end gap-1">
                      <SupplierForm supplier={s} trigger={<Button variant="ghost" size="icon" aria-label="Düzenle"><Star className="hidden" /><span className="sr-only">Düzenle</span><EditIcon /></Button>} />
                      <SupplierDelete id={s.id} name={s.name} />
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      )}
    </>
  );
}

function EditIcon() {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 20h9" /><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z" />
    </svg>
  );
}
