import { Suspense } from "react";
import { Ship } from "lucide-react";
import { Skeleton } from "@/components/ui/skeleton";
import { LoginForm } from "./login-form";

export const metadata = { title: "Giriş yap" };

export default function LoginPage() {
  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      {/* Marka paneli */}
      <div className="relative hidden flex-col justify-between bg-primary p-12 text-primary-foreground lg:flex">
        <div className="flex items-center gap-2 text-lg font-semibold">
          <Ship className="h-6 w-6" /> ChinaCargo Hub
        </div>
        <div className="space-y-4">
          <h1 className="text-3xl font-bold leading-tight">Çin&apos;den gelen tüm yükleriniz tek platformda.</h1>
          <p className="text-primary-foreground/80">
            Tedarikçi konsolidasyonundan gümrüklemeye, parsiyel denizyolu taşımadan Türkiye içi teslimata kadar
            tüm ithalat sürecinizi tek panelden yönetin.
          </p>
        </div>
        <p className="text-sm text-primary-foreground/60">© {new Date().getFullYear()} ChinaCargo Hub Lojistik A.Ş.</p>
      </div>

      {/* Form */}
      <div className="flex items-center justify-center p-6">
        <div className="w-full max-w-sm space-y-6">
          <div className="space-y-2 text-center lg:text-left">
            <div className="flex items-center justify-center gap-2 text-lg font-semibold lg:hidden">
              <Ship className="h-6 w-6 text-primary" /> ChinaCargo Hub
            </div>
            <h2 className="text-2xl font-bold">Giriş yap</h2>
            <p className="text-sm text-muted-foreground">Hesabınıza erişmek için bilgilerinizi girin.</p>
          </div>

          <Suspense fallback={<div className="space-y-4"><Skeleton className="h-16" /><Skeleton className="h-16" /><Skeleton className="h-10" /></div>}>
            <LoginForm />
          </Suspense>

          <p className="text-center text-xs text-muted-foreground">
            Demo: <span className="font-medium">ayse@ornekithalat.com</span> · şifre <span className="font-medium">Demo1234!</span>
          </p>
        </div>
      </div>
    </div>
  );
}
