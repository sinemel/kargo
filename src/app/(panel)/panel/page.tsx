import Link from "next/link";
import {
  Warehouse, Boxes, FileText, Ship, CalendarClock, Wallet, PackageCheck, Bell,
} from "lucide-react";
import { requireSession } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatCbm, formatCurrency, formatRelative, formatDate } from "@/lib/format";

export const metadata = { title: "Genel bakış" };

export default async function DashboardPage() {
  const session = await requireSession();
  const supabase = createClient();

  const [receipts, quotes, shipments, balance, notifs] = await Promise.all([
    supabase.from("warehouse_receipts").select("received_packages, actual_cbm, status")
      .in("status", ["received", "inspected", "discrepancy", "ready"]),
    supabase.from("quotations").select("id").eq("status", "sent"),
    supabase.from("shipments").select("id, shipment_no, status, eta, current_milestone_code").eq("status", "active"),
    supabase.from("customer_balance_v").select("currency, open_balance, due_within_7_days").not("currency", "is", null),
    supabase.from("notifications").select("id, title_tr, body_tr, created_at").order("created_at", { ascending: false }).limit(6),
  ]);

  const totalPackages = (receipts.data ?? []).reduce((s, r) => s + (r.received_packages ?? 0), 0);
  const totalCbm = (receipts.data ?? []).reduce((s, r) => s + (r.actual_cbm ?? 0), 0);
  const pendingQuotes = quotes.data?.length ?? 0;
  const activeShipments = shipments.data?.length ?? 0;
  const arriving = (shipments.data ?? []).filter((s) => s.eta && new Date(s.eta).getTime() - Date.now() < 14 * 86_400_000).length;
  const openBalance = (balance.data ?? []).reduce((s, b) => s + Number(b.open_balance ?? 0), 0);
  const balanceCurrency = balance.data?.[0]?.currency ?? "USD";
  const dueSoon = (balance.data ?? []).reduce((s, b) => s + Number(b.due_within_7_days ?? 0), 0);

  return (
    <>
      <PageHeader title={`Merhaba, ${session.fullName.split(" ")[0]}`} description={`${session.companyName} · genel operasyon durumu`} />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Çin deposundaki toplam yük" value={`${totalPackages} koli`} hint="Teslim alınan / hazır" icon={Warehouse} tone="primary" />
        <StatCard label="Toplam CBM" value={formatCbm(totalCbm)} hint="Depodaki hacim" icon={Boxes} tone="accent" />
        <StatCard label="Teklif bekleyen talepler" value={String(pendingQuotes)} hint="Onayınızı bekliyor" icon={FileText} tone="warning" />
        <StatCard label="Aktif sevkiyatlar" value={String(activeShipments)} hint={`${arriving} tanesi 14 gün içinde varacak`} icon={Ship} tone="primary" />
      </div>

      <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Yaklaşan hareketler" value={`${arriving} sevkiyat`} hint="Türkiye'ye ulaşmak üzere" icon={CalendarClock} tone="accent" />
        <StatCard label="Ödenecek bakiye" value={formatCurrency(openBalance, balanceCurrency)} hint={dueSoon > 0 ? `${formatCurrency(dueSoon, balanceCurrency)} bu hafta vadeli` : "Vadesi yaklaşan yok"} icon={Wallet} tone={dueSoon > 0 ? "danger" : "success"} />
        <StatCard label="Teslim alınan yük" value={`${totalPackages} koli`} hint="Kontrol tamamlandı" icon={PackageCheck} tone="success" />
        <StatCard label="Son bildirimler" value={String(notifs.data?.length ?? 0)} hint="Son 6 kayıt" icon={Bell} tone="accent" />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader className="flex-row items-center justify-between space-y-0">
            <CardTitle>Aktif sevkiyatlar</CardTitle>
            <Link href="/panel/sevkiyatlarim" className="text-sm text-accent hover:underline">Tümü</Link>
          </CardHeader>
          <CardContent className="space-y-3">
            {(shipments.data ?? []).length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">Aktif sevkiyatınız bulunmuyor.</p>
            ) : (
              (shipments.data ?? []).map((s) => (
                <div key={s.id} className="flex items-center justify-between rounded-md border p-3">
                  <div>
                    <p className="font-medium">{s.shipment_no}</p>
                    <p className="text-xs text-muted-foreground">Tahmini varış: {formatDate(s.eta)}</p>
                  </div>
                  <Badge tone="info">Yolda</Badge>
                </div>
              ))
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Son bildirimler</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            {(notifs.data ?? []).length === 0 ? (
              <p className="py-6 text-center text-sm text-muted-foreground">Henüz bildirim yok.</p>
            ) : (
              (notifs.data ?? []).map((n) => (
                <div key={n.id} className="border-b pb-2.5 last:border-0 last:pb-0">
                  <p className="text-sm font-medium">{n.title_tr}</p>
                  {n.body_tr && <p className="text-xs text-muted-foreground line-clamp-2">{n.body_tr}</p>}
                  <p className="mt-0.5 text-[11px] text-muted-foreground">{formatRelative(n.created_at)}</p>
                </div>
              ))
            )}
          </CardContent>
        </Card>
      </div>
    </>
  );
}
