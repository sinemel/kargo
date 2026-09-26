import Link from "next/link";
import { Ship } from "lucide-react";
import { requireSession } from "@/lib/auth";
import { AppSidebar } from "@/components/app-sidebar";
import { UserMenu } from "@/components/user-menu";
import { ThemeToggle } from "@/components/theme-toggle";
import { NotificationsBell } from "@/components/notifications-bell";
import { MobileSidebar } from "@/components/mobile-sidebar";
import { createClient } from "@/lib/supabase/server";

// Panel kullanıcıya özel ve canlı veri gösterir; her istekte sunucuda üretilir
// (özellikle demo modda build-zamanı önizlemeyi engellemek için gerekli).
export const dynamic = "force-dynamic";

export default async function PanelLayout({ children }: { children: React.ReactNode }) {
  const session = await requireSession();
  const permissions = Array.from(session.permissions);

  const supabase = createClient();
  const { count: unread } = await supabase
    .from("notifications")
    .select("id", { count: "exact", head: true })
    .eq("is_read", false);

  return (
    <div className="min-h-screen bg-background">
      {/* Üst bar */}
      <header className="sticky top-0 z-40 flex h-16 items-center gap-4 border-b bg-card/95 px-4 backdrop-blur supports-[backdrop-filter]:bg-card/80">
        <MobileSidebar permissions={permissions} />
        <Link href="/panel" className="flex items-center gap-2 font-semibold">
          <span className="flex h-8 w-8 items-center justify-center rounded-md bg-primary text-primary-foreground">
            <Ship className="h-5 w-5" />
          </span>
          <span className="hidden sm:inline">ChinaCargo Hub</span>
        </Link>
        <div className="ml-auto flex items-center gap-1">
          <NotificationsBell initialUnread={unread ?? 0} />
          <ThemeToggle />
          <UserMenu fullName={session.fullName} email={session.email} companyName={session.companyName} roleName={session.roleName} />
        </div>
      </header>

      <div className="mx-auto flex max-w-[1600px]">
        {/* Masaüstü kenar çubuğu */}
        <aside className="sticky top-16 hidden h-[calc(100vh-4rem)] w-72 shrink-0 overflow-y-auto border-r bg-card lg:block">
          <AppSidebar permissions={permissions} />
        </aside>
        <main className="min-w-0 flex-1 p-4 sm:p-6 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
