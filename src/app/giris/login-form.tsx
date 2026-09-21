"use client";

import { useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { toast } from "sonner";
import { createClient } from "@/lib/supabase/client";
import { loginSchema, type LoginInput } from "@/lib/validators";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function LoginForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [loading, setLoading] = useState(false);
  const { register, handleSubmit, formState: { errors } } = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  });

  async function onSubmit(values: LoginInput) {
    setLoading(true);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword(values);
    if (error) {
      toast.error("Giriş başarısız", { description: "E-posta veya şifre hatalı." });
      setLoading(false);
      return;
    }
    toast.success("Hoş geldiniz");
    router.replace(params.get("next") || "/panel");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
      <div className="space-y-2">
        <Label htmlFor="email">E-posta</Label>
        <Input id="email" type="email" autoComplete="email" placeholder="ornek@firma.com" {...register("email")} />
        {errors.email && <p className="text-xs text-danger">{errors.email.message}</p>}
      </div>
      <div className="space-y-2">
        <Label htmlFor="password">Şifre</Label>
        <Input id="password" type="password" autoComplete="current-password" placeholder="••••••••" {...register("password")} />
        {errors.password && <p className="text-xs text-danger">{errors.password.message}</p>}
      </div>
      <Button type="submit" className="w-full" disabled={loading}>
        {loading && <Loader2 className="h-4 w-4 animate-spin" />} Giriş yap
      </Button>
    </form>
  );
}
