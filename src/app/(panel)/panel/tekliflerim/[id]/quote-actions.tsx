"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { CheckCircle2, MessageSquareWarning, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { quoteRevisionSchema, type QuoteRevisionInput } from "@/lib/validators";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";

export function QuoteActions({ quotationId, quotationNo }: { quotationId: string; quotationNo: string }) {
  const router = useRouter();
  const [approveOpen, setApproveOpen] = useState(false);
  const [reviseOpen, setReviseOpen] = useState(false);
  const [pending, startTransition] = useTransition();

  const { register, handleSubmit, reset, formState: { errors } } = useForm<QuoteRevisionInput>({
    resolver: zodResolver(quoteRevisionSchema), defaultValues: { note: "" },
  });

  function approve() {
    startTransition(async () => {
      const supabase = createClient();
      const { error } = await supabase.rpc("approve_quotation", { p_quotation_id: quotationId, p_note: null });
      if (error) { toast.error("Onaylanamadı", { description: error.message }); return; }
      toast.success("Teklif onaylandı", { description: `${quotationNo} onaylandı, sevkiyat süreci başlatılacak.` });
      setApproveOpen(false);
      router.refresh();
    });
  }

  function revise(values: QuoteRevisionInput) {
    startTransition(async () => {
      const supabase = createClient();
      const { error } = await supabase.rpc("request_quotation_revision", { p_quotation_id: quotationId, p_note: values.note });
      if (error) { toast.error("Gönderilemedi", { description: error.message }); return; }
      toast.success("Revizyon talebiniz iletildi");
      setReviseOpen(false);
      reset();
      router.refresh();
    });
  }

  return (
    <div className="flex flex-col gap-3 sm:flex-row">
      {/* Onayla */}
      <Dialog open={approveOpen} onOpenChange={setApproveOpen}>
        <DialogTrigger asChild>
          <Button className="flex-1 gap-2"><CheckCircle2 className="h-4 w-4" />Teklifi onayla</Button>
        </DialogTrigger>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Teklifi onayla</DialogTitle>
            <DialogDescription>
              <span className="font-medium text-foreground">{quotationNo}</span> numaralı teklifi onaylıyorsunuz.
              Onayınızın ardından sevkiyat süreci başlatılır ve fatura düzenlenir.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setApproveOpen(false)}>Vazgeç</Button>
            <Button onClick={approve} disabled={pending}>{pending && <Loader2 className="h-4 w-4 animate-spin" />}Onaylıyorum</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Revizyon iste */}
      <Dialog open={reviseOpen} onOpenChange={setReviseOpen}>
        <DialogTrigger asChild>
          <Button variant="outline" className="flex-1 gap-2"><MessageSquareWarning className="h-4 w-4" />Revizyon iste</Button>
        </DialogTrigger>
        <DialogContent className="max-w-md">
          <form onSubmit={handleSubmit(revise)} noValidate>
            <DialogHeader>
              <DialogTitle>Revizyon iste</DialogTitle>
              <DialogDescription>Hangi noktada değişiklik istediğinizi belirtin. Operasyon ekibi teklifi güncelleyip yeniden gönderecek.</DialogDescription>
            </DialogHeader>
            <div className="my-4 space-y-2">
              <Label htmlFor="note">Revizyon gerekçesi *</Label>
              <Textarea id="note" rows={4} placeholder="Örn. Denizyolu yerine demiryolu seçeneği ve sigorta dahil fiyat istiyorum." {...register("note")} />
              {errors.note && <p className="text-xs text-danger">{errors.note.message}</p>}
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setReviseOpen(false)}>Vazgeç</Button>
              <Button type="submit" disabled={pending}>{pending && <Loader2 className="h-4 w-4 animate-spin" />}Gönder</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
