"use client";

import { useMemo, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { useForm, useFieldArray, useWatch } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Plus, Trash2, Loader2, Package, Calculator } from "lucide-react";
import { toast } from "sonner";
import { shipmentRequestSchema, type ShipmentRequestInput } from "@/lib/validators";
import { createShipmentRequest } from "@/app/actions/requests";
import { calcCbm, calcChargeable, sumItems, type TransportMode } from "@/lib/calc";
import { TRANSPORT_MODE, INCOTERM } from "@/lib/constants";
import { formatCbm, formatKg, formatNumber } from "@/lib/format";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";

interface SupplierOption { id: string; name: string; default_incoterm: string; city: string | null; address: string | null }

const emptyItem = {
  description: "", hsCodeEstimated: "", packageType: "carton" as const, packageCount: 1,
  lengthCm: 0, widthCm: 0, heightCm: 0, grossKgPerPackage: 0, isFragile: false, isStackable: true, isDangerous: false,
};

export function RequestForm({ suppliers, defaultDelivery }: { suppliers: SupplierOption[]; defaultDelivery: string }) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [mode, setMode] = useState<"submit" | "draft">("submit");

  const form = useForm<ShipmentRequestInput>({
    resolver: zodResolver(shipmentRequestSchema),
    defaultValues: {
      supplierId: "", incoterm: "EXW", deliveryAddress: defaultDelivery, requestedMode: "system_suggestion",
      currency: "USD", isDangerous: false, isStackable: true, isFragile: false, items: [{ ...emptyItem }],
    },
  });
  const { register, control, handleSubmit, setValue, watch, formState: { errors } } = form;
  const { fields, append, remove } = useFieldArray({ control, name: "items" });

  const items = useWatch({ control, name: "items" });
  const requestedMode = watch("requestedMode");

  // Canlı toplamlar
  const totals = useMemo(() => {
    const list = (items ?? []).map((it) => ({
      lengthCm: Number(it.lengthCm) || 0, widthCm: Number(it.widthCm) || 0, heightCm: Number(it.heightCm) || 0,
      count: Number(it.packageCount) || 0, grossKgPerPackage: Number(it.grossKgPerPackage) || 0,
    }));
    const t = sumItems(list);
    const effMode: Exclude<TransportMode, "system_suggestion"> =
      requestedMode === "system_suggestion" ? "sea_lcl" : (requestedMode as Exclude<TransportMode, "system_suggestion">);
    const chargeable = calcChargeable(effMode, t.cbm, t.grossKg);
    return { ...t, chargeable, effMode };
  }, [items, requestedMode]);

  function onSubmit(values: ShipmentRequestInput) {
    startTransition(async () => {
      const res = await createShipmentRequest(values, mode === "submit");
      if (res.ok) {
        toast.success(mode === "submit" ? "Talep gönderildi" : "Taslak kaydedildi", {
          description: res.requestNo ? `Talep numarası: ${res.requestNo}` : undefined,
        });
        router.push("/panel/taleplerim");
        router.refresh();
      } else {
        toast.error("Talep oluşturulamadı", { description: res.error });
      }
    });
  }

  function onSupplierChange(id: string) {
    setValue("supplierId", id);
    const s = suppliers.find((x) => x.id === id);
    if (s) {
      setValue("incoterm", s.default_incoterm as ShipmentRequestInput["incoterm"]);
      if (s.city) setValue("originCity", s.city);
      if (s.address) setValue("pickupAddress", s.address);
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-6" noValidate>
      {/* Yükleme & teslimat */}
      <Card>
        <CardHeader><CardTitle>Yükleme ve teslimat</CardTitle></CardHeader>
        <CardContent className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <Label>Tedarikçi</Label>
            <Select value={watch("supplierId") || ""} onValueChange={onSupplierChange}>
              <SelectTrigger><SelectValue placeholder="Tedarikçi seçin" /></SelectTrigger>
              <SelectContent>
                {suppliers.length === 0 ? (
                  <div className="px-3 py-2 text-sm text-muted-foreground">Önce tedarikçi ekleyin</div>
                ) : suppliers.map((s) => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>Teslim şekli</Label>
            <Select value={watch("incoterm")} onValueChange={(v) => setValue("incoterm", v as ShipmentRequestInput["incoterm"])}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>{Object.entries(INCOTERM).map(([k, v]) => <SelectItem key={k} value={k}>{v}</SelectItem>)}</SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="originCity">Yükleme şehri</Label>
            <Input id="originCity" placeholder="Guangzhou" {...register("originCity")} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="pickupAddress">Fabrika / depo adresi</Label>
            <Input id="pickupAddress" {...register("pickupAddress")} />
          </div>
          <div className="space-y-2 sm:col-span-2">
            <Label htmlFor="deliveryAddress">Türkiye teslimat adresi *</Label>
            <Input id="deliveryAddress" {...register("deliveryAddress")} />
            {errors.deliveryAddress && <p className="text-xs text-danger">{errors.deliveryAddress.message}</p>}
          </div>
        </CardContent>
      </Card>

      {/* Ürün kalemleri */}
      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0">
          <CardTitle>Ürün kalemleri</CardTitle>
          <Button type="button" variant="outline" size="sm" className="gap-2" onClick={() => append({ ...emptyItem })}>
            <Plus className="h-4 w-4" /> Kalem ekle
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {errors.items?.message && <p className="text-xs text-danger">{errors.items.message}</p>}
          {fields.map((field, i) => {
            const it = items?.[i];
            const cbm = it ? calcCbm(Number(it.lengthCm) || 0, Number(it.widthCm) || 0, Number(it.heightCm) || 0, Number(it.packageCount) || 0) : 0;
            const gross = it ? (Number(it.grossKgPerPackage) || 0) * (Number(it.packageCount) || 0) : 0;
            return (
              <div key={field.id} className="rounded-lg border p-4">
                <div className="mb-3 flex items-center justify-between">
                  <span className="flex items-center gap-2 text-sm font-medium"><Package className="h-4 w-4 text-accent" /> Kalem {i + 1}</span>
                  {fields.length > 1 && (
                    <Button type="button" variant="ghost" size="icon" onClick={() => remove(i)} aria-label="Kalemi sil">
                      <Trash2 className="h-4 w-4 text-danger" />
                    </Button>
                  )}
                </div>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                  <div className="space-y-1.5 sm:col-span-2 lg:col-span-4">
                    <Label>Ürün açıklaması *</Label>
                    <Input placeholder="LED panel armatür 60×60 cm 40W" {...register(`items.${i}.description`)} />
                    {errors.items?.[i]?.description && <p className="text-xs text-danger">{errors.items[i]?.description?.message}</p>}
                  </div>
                  <div className="space-y-1.5">
                    <Label>Tahmini GTİP</Label>
                    <Input placeholder="9405.11" {...register(`items.${i}.hsCodeEstimated`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>Koli/palet adedi *</Label>
                    <Input type="number" min={1} step={1} {...register(`items.${i}.packageCount`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>Koli başı brüt (kg) *</Label>
                    <Input type="number" min={0} step="0.01" {...register(`items.${i}.grossKgPerPackage`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>Ürün değeri</Label>
                    <Input type="number" min={0} step="0.01" {...register(`items.${i}.goodsValue`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>En (cm) *</Label>
                    <Input type="number" min={0} step="0.1" {...register(`items.${i}.lengthCm`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>Boy (cm) *</Label>
                    <Input type="number" min={0} step="0.1" {...register(`items.${i}.widthCm`)} />
                  </div>
                  <div className="space-y-1.5">
                    <Label>Yükseklik (cm) *</Label>
                    <Input type="number" min={0} step="0.1" {...register(`items.${i}.heightCm`)} />
                  </div>
                  <div className="flex items-end gap-4 pb-1 text-sm">
                    <div><span className="text-muted-foreground">CBM: </span><span className="font-medium">{formatNumber(cbm, 4)}</span></div>
                    <div><span className="text-muted-foreground">Brüt: </span><span className="font-medium">{formatNumber(gross, 1)} kg</span></div>
                  </div>
                </div>
                <div className="mt-3 flex flex-wrap gap-4 text-sm">
                  <label className="flex items-center gap-2"><input type="checkbox" className="h-4 w-4 rounded border-input" {...register(`items.${i}.isFragile`)} /> Kırılabilir</label>
                  <label className="flex items-center gap-2"><input type="checkbox" className="h-4 w-4 rounded border-input" {...register(`items.${i}.isStackable`)} defaultChecked /> İstiflenebilir</label>
                  <label className="flex items-center gap-2"><input type="checkbox" className="h-4 w-4 rounded border-input" {...register(`items.${i}.isDangerous`)} /> Tehlikeli madde</label>
                </div>
              </div>
            );
          })}
        </CardContent>
      </Card>

      {/* Taşıma tercihi + canlı hesap */}
      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader><CardTitle>Taşıma tercihi</CardTitle></CardHeader>
          <CardContent className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label>İstenen taşıma şekli</Label>
              <Select value={watch("requestedMode")} onValueChange={(v) => setValue("requestedMode", v as ShipmentRequestInput["requestedMode"])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>{Object.entries(TRANSPORT_MODE).map(([k, v]) => <SelectItem key={k} value={k}>{v}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="cargoReadyDate">Hazır olma tarihi</Label>
              <Input id="cargoReadyDate" type="date" {...register("cargoReadyDate")} />
            </div>
            <div className="space-y-2">
              <Label>Para birimi</Label>
              <Select value={watch("currency")} onValueChange={(v) => setValue("currency", v as ShipmentRequestInput["currency"])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>{["USD", "EUR", "TRY", "CNY"].map((c) => <SelectItem key={c} value={c}>{c}</SelectItem>)}</SelectContent>
              </Select>
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="customerNote">Not (opsiyonel)</Label>
              <Textarea id="customerNote" rows={2} placeholder="Depoya iletilmesini istediğiniz özel talimatlar" {...register("customerNote")} />
            </div>
          </CardContent>
        </Card>

        <Card className="border-accent/40 bg-accent/5">
          <CardHeader className="flex-row items-center gap-2 space-y-0">
            <Calculator className="h-5 w-5 text-accent" /><CardTitle>Canlı hesap</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <Row label="Toplam koli/palet" value={`${totals.packages}`} />
            <Row label="Toplam brüt ağırlık" value={formatKg(totals.grossKg)} />
            <Row label="Toplam hacim" value={formatCbm(totals.cbm)} />
            <div className="border-t pt-3">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Ücretlendirilebilir</span>
                <span className="text-lg font-bold text-accent">
                  {formatNumber(totals.chargeable.quantity, totals.chargeable.unit === "wm" ? 3 : 1)}{" "}
                  {totals.chargeable.unit === "wm" ? "W/M" : "kg"}
                </span>
              </div>
              <p className="mt-1 text-xs text-muted-foreground">
                {totals.effMode === "sea_lcl" || totals.effMode === "rail_lcl"
                  ? "W/M = max(CBM, kg÷1000). Nihai değer depo ölçümüyle kesinleşir."
                  : "Hacimsel ağırlık = En×Boy×Yükseklik÷bölen. Nihai değer depo ölçümüyle kesinleşir."}
              </p>
              {requestedMode === "system_suggestion" && (
                <Badge tone="info" className="mt-2">Denizyolu LCL üzerinden tahmini</Badge>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <Button type="submit" variant="outline" disabled={pending} onClick={() => setMode("draft")}>
          {pending && mode === "draft" && <Loader2 className="h-4 w-4 animate-spin" />} Taslak kaydet
        </Button>
        <Button type="submit" disabled={pending} onClick={() => setMode("submit")}>
          {pending && mode === "submit" && <Loader2 className="h-4 w-4 animate-spin" />} Talebi gönder
        </Button>
      </div>
    </form>
  );
}

function Row({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium">{value}</span>
    </div>
  );
}
