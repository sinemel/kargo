"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard, PackagePlus, ClipboardList, FileText, Building2, Warehouse,
  Boxes, Ship, FileStack, Wallet, Truck, LifeBuoy, Settings,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface NavItem {
  href: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  perm?: string; // gerekli izin (yoksa herkese görünür)
}

const NAV: { section: string; items: NavItem[] }[] = [
  {
    section: "Operasyon",
    items: [
      { href: "/panel", label: "Genel bakış", icon: LayoutDashboard },
      { href: "/panel/taleplerim/yeni", label: "Yeni taşıma talebi", icon: PackagePlus, perm: "requests.create" },
      { href: "/panel/taleplerim", label: "Taleplerim", icon: ClipboardList, perm: "requests.view_own" },
      { href: "/panel/tekliflerim", label: "Tekliflerim", icon: FileText, perm: "quotations.view_own" },
    ],
  },
  {
    section: "Yük",
    items: [
      { href: "/panel/tedarikcilerim", label: "Tedarikçilerim", icon: Building2, perm: "suppliers.manage_own" },
      { href: "/panel/depodaki-yuklerim", label: "Çin deposundaki yüklerim", icon: Warehouse, perm: "shipments.view_own" },
      { href: "/panel/konsolidasyonlarim", label: "Konsolidasyonlarım", icon: Boxes, perm: "consolidations.view_own" },
      { href: "/panel/sevkiyatlarim", label: "Aktif sevkiyatlar", icon: Ship, perm: "shipments.view_own" },
    ],
  },
  {
    section: "Belge & Finans",
    items: [
      { href: "/panel/evraklar", label: "Evraklar", icon: FileStack, perm: "documents.view_own" },
      { href: "/panel/odemeler", label: "Ödemeler", icon: Wallet, perm: "finance.view_own_balance" },
      { href: "/panel/teslimatlar", label: "Teslimat talepleri", icon: Truck, perm: "deliveries.request" },
    ],
  },
  {
    section: "Diğer",
    items: [
      { href: "/panel/destek", label: "Destek merkezi", icon: LifeBuoy, perm: "tickets.create" },
      { href: "/panel/ayarlar", label: "Firma ve kullanıcı ayarları", icon: Settings, perm: "company.manage_own" },
    ],
  },
];

export function AppSidebar({ permissions }: { permissions: string[] }) {
  const pathname = usePathname();
  const perms = new Set(permissions);

  return (
    <nav className="flex flex-col gap-6 p-4">
      {NAV.map((group) => {
        const items = group.items.filter((it) => !it.perm || perms.has(it.perm));
        if (items.length === 0) return null;
        return (
          <div key={group.section}>
            <p className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">{group.section}</p>
            <ul className="space-y-1">
              {items.map((it) => {
                const active = pathname === it.href || (it.href !== "/panel" && pathname.startsWith(it.href));
                const Icon = it.icon;
                return (
                  <li key={it.href}>
                    <Link
                      href={it.href}
                      className={cn(
                        "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                        active ? "bg-primary text-primary-foreground" : "text-foreground/80 hover:bg-secondary hover:text-foreground",
                      )}
                    >
                      <Icon className="h-4 w-4 shrink-0" />
                      <span className="truncate">{it.label}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        );
      })}
    </nav>
  );
}
