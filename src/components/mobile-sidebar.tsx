"use client";
import { useState } from "react";
import { Menu } from "lucide-react";
import { Dialog, DialogContent, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { AppSidebar } from "@/components/app-sidebar";

export function MobileSidebar({ permissions }: { permissions: string[] }) {
  const [open, setOpen] = useState(false);
  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="ghost" size="icon" className="lg:hidden" aria-label="Menü">
          <Menu className="h-5 w-5" />
        </Button>
      </DialogTrigger>
      <DialogContent className="left-0 top-0 h-full max-w-72 translate-x-0 translate-y-0 rounded-none rounded-r-lg p-0">
        <DialogTitle className="sr-only">Menü</DialogTitle>
        <div onClick={() => setOpen(false)}>
          <AppSidebar permissions={permissions} />
        </div>
      </DialogContent>
    </Dialog>
  );
}
