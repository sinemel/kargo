"use client";
import { useEffect, useState } from "react";
import { Bell } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { formatRelative } from "@/lib/format";

interface Notif { id: string; title_tr: string; body_tr: string | null; created_at: string; is_read: boolean }

export function NotificationsBell({ initialUnread }: { initialUnread: number }) {
  const [unread, setUnread] = useState(initialUnread);
  const [items, setItems] = useState<Notif[]>([]);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    if (!open) return;
    const supabase = createClient();
    supabase
      .from("notifications")
      .select("id, title_tr, body_tr, created_at, is_read")
      .order("created_at", { ascending: false })
      .limit(10)
      .then(({ data }) => setItems((data as Notif[]) ?? []));
  }, [open]);

  async function markAll() {
    const supabase = createClient();
    await supabase.rpc("mark_notifications_read", { p_ids: null });
    setUnread(0);
    setItems((prev) => prev.map((n) => ({ ...n, is_read: true })));
  }

  return (
    <DropdownMenu open={open} onOpenChange={setOpen}>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="relative" aria-label="Bildirimler">
          <Bell className="h-5 w-5" />
          {unread > 0 && (
            <span className="absolute right-1.5 top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-bold text-danger-foreground">
              {unread > 9 ? "9+" : unread}
            </span>
          )}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-80">
        <DropdownMenuLabel className="flex items-center justify-between">
          <span>Bildirimler</span>
          {unread > 0 && <button onClick={markAll} className="text-xs font-normal text-accent hover:underline">Tümünü okundu işaretle</button>}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        {items.length === 0 ? (
          <p className="px-2 py-6 text-center text-sm text-muted-foreground">Henüz bildirim yok.</p>
        ) : (
          <ul className="max-h-80 overflow-y-auto">
            {items.map((n) => (
              <li key={n.id} className={`border-b px-3 py-2.5 last:border-0 ${n.is_read ? "opacity-60" : ""}`}>
                <p className="text-sm font-medium">{n.title_tr}</p>
                {n.body_tr && <p className="text-xs text-muted-foreground line-clamp-2">{n.body_tr}</p>}
                <p className="mt-0.5 text-[11px] text-muted-foreground">{formatRelative(n.created_at)}</p>
              </li>
            ))}
          </ul>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
