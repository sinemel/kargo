import { createServerClient } from "@supabase/ssr";
import { createClient as createSupabaseClient, type SupabaseClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import crypto from "crypto";
import type { Database } from "@/types/database";
import { DEMO_MODE, DEMO_USER_ID } from "@/lib/demo";

function b64url(input: string): string {
  return Buffer.from(input).toString("base64url");
}

// Demo kullanıcı adına kısa ömürlü bir Supabase JWT üretir (HS256).
// PostgREST bu token'ın `role` claim'ini Postgres rolüne, `sub`'u auth.uid()'e
// eşler; böylece RLS gerçek bir giriş yapılmış gibi çalışır. SUPABASE_JWT_SECRET
// projenin JWT Secret'ı ile aynı olmalıdır (Supabase → Project Settings → API).
function mintDemoToken(): string | null {
  const secret = process.env.SUPABASE_JWT_SECRET;
  if (!secret) return null;
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const payload = b64url(
    JSON.stringify({
      sub: DEMO_USER_ID,
      role: "authenticated",
      aud: "authenticated",
      iss: "chinacargo-demo",
      iat: now,
      exp: now + 60 * 60, // 1 saat
    }),
  );
  const data = `${header}.${payload}`;
  const sig = crypto.createHmac("sha256", secret).update(data).digest("base64url");
  return `${data}.${sig}`;
}

function createDemoClient(): SupabaseClient<Database> {
  const token = mintDemoToken();
  return createSupabaseClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      auth: { persistSession: false, autoRefreshToken: false },
      global: token ? { headers: { Authorization: `Bearer ${token}` } } : {},
    },
  );
}

// Sunucu bileşenleri ve server action'lar için Supabase istemcisi.
// Gerçek modda: kullanıcının çerez oturumu (anon anahtar + RLS).
// Demo modda: demo kullanıcı adına imzalı JWT (yine RLS; service_role KULLANILMAZ).
export function createClient(): SupabaseClient<Database> {
  if (DEMO_MODE) return createDemoClient();

  const cookieStore = cookies();
  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options),
            );
          } catch {
            // Server Component'ten çağrıldıysa yoksay; oturum middleware'de yenilenir.
          }
        },
      },
    },
  );
}
