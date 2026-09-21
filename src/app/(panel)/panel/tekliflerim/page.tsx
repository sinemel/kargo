import Link from "next/link";
import { FileText, ArrowRight } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { EmptyState } from "@/components/empty-state";
import { Card, CardContent } from "@/components/ui/card";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { QUOTATION_STATUS, TRANSPORT_MODE, label } from "@/lib/constants";
import { formatCurrency, formatDate, daysUntil } from "@/lib/format";

export const metadata = { title: "Tekliflerim" };

export default async function QuotationsPage() {
  const supabase = createClient();
  const { data } = await supabase
    .from("quotations")
    .select("id, quotation_no, version, transport_mode, status, valid_until, total, currency, quote_date")
    .order("quote_date", { ascending: false });

  const rows = (data ?? []) as {
    id: string; quotation_no: string | null; version: number; transport_mode: string; status: string;
    valid_until: string; total: number; currency: string; quote_date: string;
  }[];

  return (
    <>
      <PageHeader title="Tekliflerim" description="Size sunulan fiyat teklifleri. Onaylayabilir veya revizyon isteyebilirsiniz." />

      {rows.length === 0 ? (
        <EmptyState icon={FileText} title="Henüz teklifiniz yok" description="Taşıma talebiniz ön kontrolden geçtikten sonra teklifleriniz burada listelenir." />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {rows.map((q) => {
            const days = daysUntil(q.valid_until);
            const expiringSoon = q.status === "sent" && days !== null && days <= 3;
            return (
              <Card key={q.id} className={expiringSoon ? "border-warning/50" : undefined}>
                <CardContent className="space-y-3 p-5">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-semibold">{q.quotation_no}{q.version > 1 && <span className="ml-1 text-xs text-muted-foreground">v{q.version}</span>}</p>
                      <p className="text-xs text-muted-foreground">{label(TRANSPORT_MODE, q.transport_mode)}</p>
                    </div>
                    <StatusBadge map={QUOTATION_STATUS} value={q.status} />
                  </div>
                  <div className="flex items-end justify-between">
                    <div>
                      <p className="text-xs text-muted-foreground">Toplam</p>
                      <p className="text-2xl font-bold">{formatCurrency(q.total, q.currency)}</p>
                    </div>
                    <div className="text-right text-xs text-muted-foreground">
                      <p>Geçerlilik</p>
                      <p className={expiringSoon ? "font-medium text-warning" : ""}>{formatDate(q.valid_until)}</p>
                    </div>
                  </div>
                  <Button asChild variant="outline" className="w-full gap-2">
                    <Link href={`/panel/tekliflerim/${q.id}`}>Detayı gör <ArrowRight className="h-4 w-4" /></Link>
                  </Button>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </>
  );
}
