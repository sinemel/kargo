import { cache } from "react";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export interface SessionContext {
  userId: string;
  email: string;
  fullName: string;
  companyId: string;
  companyName: string;
  companyType: "operator" | "customer" | "partner";
  roleCode: string;
  roleName: string;
  permissions: Set<string>;
}

// İstek başına bir kez çözülür (React cache). Kullanıcının aktif üyeliğini,
// rolünü ve izinlerini toplar. Çok şirketli üyelikte ilk aktif üyelik alınır
// (Faz 4'te şirket değiştirici eklenecek).
export const getSession = cache(async (): Promise<SessionContext | null> => {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return null;

  const { data: membership } = await supabase
    .from("company_users")
    .select(
      `company_id, status,
       companies:company_id ( legal_name, trade_name, type ),
       roles:role_id ( code, name_tr,
         role_permissions ( permissions ( code ) ) ),
       users:user_id ( full_name, email )`,
    )
    .eq("user_id", user.id)
    .eq("status", "active")
    .limit(1)
    .maybeSingle();

  if (!membership) {
    return {
      userId: user.id,
      email: user.email ?? "",
      fullName: (user.user_metadata?.full_name as string) ?? user.email ?? "",
      companyId: "",
      companyName: "",
      companyType: "customer",
      roleCode: "",
      roleName: "",
      permissions: new Set<string>(),
    };
  }

  const company = membership.companies as unknown as { legal_name: string; trade_name: string | null; type: SessionContext["companyType"] };
  const role = membership.roles as unknown as {
    code: string; name_tr: string;
    role_permissions: { permissions: { code: string } | null }[];
  };
  const usr = membership.users as unknown as { full_name: string; email: string };

  const permissions = new Set<string>(
    (role?.role_permissions ?? [])
      .map((rp) => rp.permissions?.code)
      .filter((c): c is string => Boolean(c)),
  );

  return {
    userId: user.id,
    email: usr?.email ?? user.email ?? "",
    fullName: usr?.full_name ?? user.email ?? "",
    companyId: membership.company_id,
    companyName: company?.trade_name ?? company?.legal_name ?? "",
    companyType: company?.type ?? "customer",
    roleCode: role?.code ?? "",
    roleName: role?.name_tr ?? "",
    permissions,
  };
});

/** Korumalı sayfalarda çağrılır; oturum yoksa /giris'e yönlendirir. */
export async function requireSession(): Promise<SessionContext> {
  const session = await getSession();
  if (!session) redirect("/giris");
  return session;
}

export function can(session: SessionContext | null, permission: string): boolean {
  return session?.permissions.has(permission) ?? false;
}
