"use client";

import { useState, useTransition } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Plus, Pencil, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { supplierSchema, type SupplierInput } from "@/lib/validators";
import { saveSupplier } from "@/app/actions/suppliers";
import { INCOTERM } from "@/lib/constants";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

export interface SupplierRow {
  id: string; name: string; contact_name: string | null; phone: string | null; email: string | null;
  wechat: string | null; province: string | null; city: string | null; address: string | null;
  address_type: string; default_incoterm: string; products_summary: string | null; notes: string | null;
}

export function SupplierForm({ supplier, trigger }: { supplier?: SupplierRow; trigger?: React.ReactNode }) {
  const [open, setOpen] = useState(false);
  const [pending, startTransition] = useTransition();
  const editing = Boolean(supplier);

  const { register, handleSubmit, setValue, watch, reset, formState: { errors } } = useForm<SupplierInput>({
    resolver: zodResolver(supplierSchema),
    defaultValues: {
      name: supplier?.name ?? "", contactName: supplier?.contact_name ?? "", phone: supplier?.phone ?? "",
      email: supplier?.email ?? "", wechat: supplier?.wechat ?? "", province: supplier?.province ?? "",
      city: supplier?.city ?? "", address: supplier?.address ?? "",
      addressType: (supplier?.address_type as SupplierInput["addressType"]) ?? "factory",
      defaultIncoterm: (supplier?.default_incoterm as SupplierInput["defaultIncoterm"]) ?? "EXW",
      productsSummary: supplier?.products_summary ?? "", notes: supplier?.notes ?? "",
    },
  });

  function onSubmit(values: SupplierInput) {
    startTransition(async () => {
      const res = await saveSupplier(values, supplier?.id);
      if (res.ok) {
        toast.success(editing ? "Tedarikçi güncellendi" : "Tedarikçi eklendi");
        setOpen(false);
        if (!editing) reset();
      } else {
        toast.error("İşlem başarısız", { description: res.error });
      }
    });
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger ?? (
          <Button className="gap-2">{editing ? <Pencil className="h-4 w-4" /> : <Plus className="h-4 w-4" />}{editing ? "Düzenle" : "Tedarikçi ekle"}</Button>
        )}
      </DialogTrigger>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>{editing ? "Tedarikçiyi düzenle" : "Yeni tedarikçi"}</DialogTitle>
          <DialogDescription>Çin&apos;deki tedarikçi bilgilerini girin. Bu bilgiler taşıma taleplerinde kullanılır.</DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="name">Tedarikçi adı *</Label>
              <Input id="name" placeholder="Guangzhou Lighting Co." {...register("name")} />
              {errors.name && <p className="text-xs text-danger">{errors.name.message}</p>}
            </div>
            <div className="space-y-2">
              <Label htmlFor="contactName">İletişim kişisi</Label>
              <Input id="contactName" placeholder="Mr. Chen" {...register("contactName")} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="phone">Telefon</Label>
              <Input id="phone" placeholder="+86 ..." {...register("phone")} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="email">E-posta</Label>
              <Input id="email" type="email" placeholder="sales@..." {...register("email")} />
              {errors.email && <p className="text-xs text-danger">{errors.email.message}</p>}
            </div>
            <div className="space-y-2">
              <Label htmlFor="wechat">WeChat</Label>
              <Input id="wechat" {...register("wechat")} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="province">Eyalet</Label>
              <Input id="province" placeholder="Guangdong" {...register("province")} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="city">Şehir</Label>
              <Input id="city" placeholder="Guangzhou" {...register("city")} />
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="address">Adres</Label>
              <Input id="address" {...register("address")} />
            </div>
            <div className="space-y-2">
              <Label>Adres türü</Label>
              <Select value={watch("addressType")} onValueChange={(v) => setValue("addressType", v as SupplierInput["addressType"])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="factory">Fabrika</SelectItem>
                  <SelectItem value="warehouse">Depo</SelectItem>
                  <SelectItem value="office">Ofis</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Varsayılan teslim şekli</Label>
              <Select value={watch("defaultIncoterm")} onValueChange={(v) => setValue("defaultIncoterm", v as SupplierInput["defaultIncoterm"])}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {Object.entries(INCOTERM).map(([k, v]) => <SelectItem key={k} value={k}>{v}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="productsSummary">Ürün özeti</Label>
              <Input id="productsSummary" placeholder="LED panel, downlight, armatür" {...register("productsSummary")} />
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="notes">Notlar</Label>
              <Textarea id="notes" rows={2} {...register("notes")} />
            </div>
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => setOpen(false)}>İptal</Button>
            <Button type="submit" disabled={pending}>
              {pending && <Loader2 className="h-4 w-4 animate-spin" />}{editing ? "Kaydet" : "Ekle"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
