"use client";
import { LogOut, User as UserIcon } from "lucide-react";
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
  DropdownMenuSeparator, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { initials } from "@/lib/format";
import { signOut } from "@/app/actions/auth";
import { DEMO_MODE } from "@/lib/demo";

export function UserMenu({ fullName, email, companyName, roleName }: { fullName: string; email: string; companyName: string; roleName: string }) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" className="gap-2 pl-2 pr-3">
          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-accent text-sm font-semibold text-accent-foreground">
            {initials(fullName)}
          </span>
          <span className="hidden text-left sm:block">
            <span className="block text-sm font-medium leading-tight">{fullName}</span>
            <span className="block text-xs text-muted-foreground leading-tight">{companyName}</span>
          </span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel>
          <div className="font-medium">{fullName}</div>
          <div className="text-xs font-normal text-muted-foreground">{email}</div>
          <div className="mt-1 text-xs font-normal text-muted-foreground">{roleName}</div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem asChild>
          <a href="/panel/ayarlar" className="cursor-pointer"><UserIcon className="mr-2 h-4 w-4" />Hesabım</a>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        {DEMO_MODE ? (
          <DropdownMenuItem disabled className="text-xs text-muted-foreground">
            Demo modu · giriş devre dışı
          </DropdownMenuItem>
        ) : (
          <form action={signOut}>
            <button type="submit" className="w-full">
              <DropdownMenuItem className="cursor-pointer text-danger focus:text-danger">
                <LogOut className="mr-2 h-4 w-4" />Çıkış yap
              </DropdownMenuItem>
            </button>
          </form>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
