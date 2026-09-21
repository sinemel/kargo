"use client";
import { useState, useTransition } from "react";
import { Trash2, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { deleteSupplier } from "@/app/actions/suppliers";
import { Button } from "@/components/ui/button";
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger,
} from "@/components/ui/dialog";

export function SupplierDelete({ id, name }: { id: string; name: string }) {
  const [open, setOpen] = useState(false);
  const [pending, startTransition] = useTransition();
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="icon" aria-label="Sil"><Trash2 className="h-4 w-4 text-danger" /></Button>
      </DialogTrigger>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Tedarikçiyi sil</DialogTitle>
          <DialogDescription><span className="font-medium text-foreground">{name}</span> pasife alınacak. Mevcut talep ve sevkiyatları etkilenmez.</DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>Vazgeç</Button>
          <Button variant="destructive" disabled={pending} onClick={() => startTransition(async () => {
            const res = await deleteSupplier(id);
            if (res.ok) { toast.success("Tedarikçi silindi"); setOpen(false); }
            else toast.error("Silinemedi", { description: res.error });
          })}>
            {pending && <Loader2 className="h-4 w-4 animate-spin" />}Sil
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
