import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, CheckCircle2, Ship, CalendarClock } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/status-badge";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { QUOTATION_STATUS, TRANSPORT_MODE, INCOTERM, COST_CATEGORY, COST_CERTAINTY, label } from "@/lib/constants";
import { formatCurrency, formatDate, formatNumber, daysUntil } from "@/lib/format";
import { QuoteActions } from "./quote-actions";

export default async function QuoteDetailPage({ params }: { params: { id: string } }) {
  const supabase = createClient();

  const { data: q } = await supabase
    .from("quotations")
    .select(`id, quotation_no, version, status, transport_mode, incoterm, currency, quote_date, valid_until,
      transit_days_min, transit_days_max, planned_departure_date, estimated_arrival_date, chargeable_wm,
      included_services, excluded_services, special_terms, payment_plan, cancellation_terms, delay_force_majeure_terms,
      subtotal, total, customer_response_note`)
    .eq("id", params.id)
    .maybeSingle();

  if (!q) notFound();

  const { data: items } = await supabase
    .from("quotation_items")
    .select("id, sort_order, category, description_tr, certainty, quantity, unit, unit_price, amount, currency, note")
    .eq("quotation_id", params.id)
    .order("sort_order");

  const days = daysUntil(q.valid_until);
  const canAct = q.status === "sent";

  return (
    <div className="mx-auto max-w-4xl">
      <Link href="/panel/tekliflerim" className="mb-4 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Tekliflere dön
      </Link>

      <PageHeader
        title={`${q.quotation_no}${q.version > 1 ? ` · v${q.version}` : ""}`}
        description={`${label(TRANSPORT_MODE, q.transport_mode)} · ${label(INCOTERM, q.incoterm)}`}
        action={<StatusBadge map={QUOTATION_STATUS} value={q.status} />}
      />

      {canAct && days !== null && days <= 3 && (
        <div className="mb-4 rounded-md border border-warning/50 bg-warning/10 px-4 py-3 text-sm text-warning">
          Bu teklifin geçerliliği {days <= 0 ? "bugün doluyor" : `${days} gün içinde doluyor`}. Onayınızı geciktirmemenizi öneririz.
        </div>
      )}

      {/* Özet */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card><CardContent className="flex items-center gap-3 p-4">
          <Ship className="h-5 w-5 text-accent" />
          <div><p className="text-xs text-muted-foreground">Transit süre</p>
          <p className="font-semibold">{q.transit_days_min && q.transit_days_max ? `${q.transit_days_min}–${q.transit_days_max} gün` : "—"}</p></div>
        </CardContent></Card>
        <Card><CardContent className="flex items-center gap-3 p-4">
          <CalendarClock className="h-5 w-5 text-accent" />
          <div><p className="text-xs text-muted-foreground">Tahmini kalkış / varış</p>
          <p className="text-sm font-semibold">{formatDate(q.planned_departure_date)} → {formatDate(q.estimated_arrival_date)}</p></div>
        </CardContent></Card>
        <Card><CardContent className="flex items-center gap-3 p-4">
          <CheckCircle2 className="h-5 w-5 text-accent" />
          <div><p className="text-xs text-muted-foreground">Ücretlendirilebilir</p>
          <p className="font-semibold">{q.chargeable_wm ? `${formatNumber(q.chargeable_wm, 3)} W/M` : "—"}</p></div>
        </CardContent></Card>
      </div>

      {/* Kalemler */}
      <Card className="mt-4">
        <CardHeader><CardTitle>Fiyat dökümü</CardTitle></CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Hizmet</TableHead>
                <TableHead>Durum</TableHead>
                <TableHead className="text-right">Miktar</TableHead>
                <TableHead className="text-right">Birim</TableHead>
                <TableHead className="text-right">Tutar</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {(items ?? []).map((it) => (
                <TableRow key={it.id}>
                  <TableCell>
                    <div className="font-medium">{it.description_tr}</div>
                    <div className="text-xs text-muted-foreground">{label(COST_CATEGORY, it.category)}{it.note ? ` · ${it.note}` : ""}</div>
                  </TableCell>
                  <TableCell><StatusBadge map={COST_CERTAINTY} value={it.certainty} /></TableCell>
                  <TableCell className="text-right text-sm">{formatNumber(it.quantity, 2)} {it.unit}</TableCell>
                  <TableCell className="text-right text-sm">{formatCurrency(it.unit_price, it.currency)}</TableCell>
                  <TableCell className="text-right font-medium">{formatCurrency(it.amount, it.currency)}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="flex flex-col items-end gap-1 border-t p-4">
            <div className="flex w-64 justify-between text-sm"><span className="text-muted-foreground">Ara toplam</span><span>{formatCurrency(q.subtotal, q.currency)}</span></div>
            <div className="flex w-64 justify-between text-lg font-bold"><span>Genel toplam</span><span>{formatCurrency(q.total, q.currency)}</span></div>
            <p className="mt-1 text-xs text-muted-foreground">Tahmini kalemler nihai maliyete göre güncellenebilir; kesin kalemler sabittir.</p>
          </div>
        </CardContent>
      </Card>

      {/* Hizmet kapsamı */}
      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <Card>
          <CardHeader><CardTitle className="text-base">Dahil hizmetler</CardTitle></CardHeader>
          <CardContent className="flex flex-wrap gap-2">
            {(q.included_services ?? []).length ? (q.included_services ?? []).map((s: string) => <Badge key={s} tone="success">{label(COST_CATEGORY, s)}</Badge>) : <span className="text-sm text-muted-foreground">—</span>}
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle className="text-base">Hariç hizmetler</CardTitle></CardHeader>
          <CardContent className="flex flex-wrap gap-2">
            {(q.excluded_services ?? []).length ? (q.excluded_services ?? []).map((s: string) => <Badge key={s} tone="warning">{label(COST_CATEGORY, s)}</Badge>) : <span className="text-sm text-muted-foreground">—</span>}
          </CardContent>
        </Card>
      </div>

      {/* Şartlar */}
      {(q.payment_plan || q.special_terms || q.cancellation_terms || q.delay_force_majeure_terms) && (
        <Card className="mt-4">
          <CardHeader><CardTitle className="text-base">Teklif şartları</CardTitle></CardHeader>
          <CardContent className="space-y-3 text-sm">
            {q.payment_plan && <Term title="Ödeme planı" body={q.payment_plan} />}
            {q.special_terms && <Term title="Özel şartlar" body={q.special_terms} />}
            {q.cancellation_terms && <Term title="İptal koşulları" body={q.cancellation_terms} />}
            {q.delay_force_majeure_terms && <Term title="Gecikme / mücbir sebep" body={q.delay_force_majeure_terms} />}
          </CardContent>
        </Card>
      )}

      {q.customer_response_note && (
        <div className="mt-4 rounded-md border bg-secondary/50 p-4 text-sm">
          <p className="font-medium">Önceki yanıtınız</p>
          <p className="text-muted-foreground">{q.customer_response_note}</p>
        </div>
      )}

      {/* Aksiyonlar */}
      {canAct ? (
        <div className="mt-6">
          <QuoteActions quotationId={q.id} quotationNo={q.quotation_no ?? ""} />
        </div>
      ) : (
        <div className="mt-6 rounded-md border bg-secondary/40 p-4 text-center text-sm text-muted-foreground">
          Bu teklif için işlem yapılamaz (durum: {label(Object.fromEntries(Object.entries(QUOTATION_STATUS).map(([k, v]) => [k, v.label])), q.status)}).
        </div>
      )}
    </div>
  );
}

function Term({ title, body }: { title: string; body: string }) {
  return (
    <div>
      <p className="font-medium">{title}</p>
      <p className="whitespace-pre-line text-muted-foreground">{body}</p>
    </div>
  );
}
