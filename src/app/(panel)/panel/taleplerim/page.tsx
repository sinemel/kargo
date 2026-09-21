import Link from "next/link";
import { ClipboardList, PackagePlus } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { EmptyState } from "@/components/empty-state";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { StatusBadge } from "@/components/status-badge";
import { REQUEST_STATUS, TRANSPORT_MODE, label } from "@/lib/constants";
import { formatCbm, formatDate } from "@/lib/format";

export const metadata = { title: "Taleplerim" };

export default async function RequestsPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from("shipment_requests")
    .select("id, request_no, requested_mode, declared_packages, declared_cbm, status, created_at, suppliers:supplier_id ( name )")
    .order("created_at", { ascending: false });

  const rows = (data ?? []) as unknown as {
    id: string; request_no: string | null; requested_mode: string; declared_packages: number | null;
    declared_cbm: number | null; status: string; created_at: string; suppliers: { name: string } | null;
  }[];

  return (
    <>
      <PageHeader
        title="Taleplerim"
        description="Oluşturduğunuz taşıma talepleri ve durumları."
        action={<Button asChild className="gap-2"><Link href="/panel/taleplerim/yeni"><PackagePlus className="h-4 w-4" />Yeni talep</Link></Button>}
      />

      {rows.length === 0 ? (
        <EmptyState
          icon={ClipboardList}
          title="Henüz talep oluşturmadınız"
          description="İlk taşıma talebinizi oluşturun; operasyon ekibi ön kontrol yapıp size teklif hazırlasın."
          action={<Button asChild><Link href="/panel/taleplerim/yeni">Yeni talep oluştur</Link></Button>}
        />
      ) : (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Talep no</TableHead>
                <TableHead>Tedarikçi</TableHead>
                <TableHead>Taşıma</TableHead>
                <TableHead>Koli</TableHead>
                <TableHead>CBM</TableHead>
                <TableHead>Tarih</TableHead>
                <TableHead>Durum</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((r) => (
                <TableRow key={r.id}>
                  <TableCell className="font-medium">{r.request_no ?? "Taslak"}</TableCell>
                  <TableCell>{r.suppliers?.name ?? "—"}</TableCell>
                  <TableCell className="text-sm">{label(TRANSPORT_MODE, r.requested_mode)}</TableCell>
                  <TableCell>{r.declared_packages ?? "—"}</TableCell>
                  <TableCell className="text-sm">{formatCbm(r.declared_cbm)}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">{formatDate(r.created_at)}</TableCell>
                  <TableCell><StatusBadge map={REQUEST_STATUS} value={r.status} /></TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      )}
    </>
  );
}
