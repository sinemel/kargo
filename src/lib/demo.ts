// Demo modu: login olmadan panele doğrudan girmek için.
// NEXT_PUBLIC_DEMO_MODE=true iken auth kapısı devre dışı kalır, sabit bir demo
// kullanıcı (Ayşe Yılmaz / Örnek İthalat) oturumu kullanılır ve veri okuma
// sunucu tarafında bu kullanıcı adına üretilen kısa ömürlü bir JWT ile yapılır;
// böylece RLS aynen çalışır (kiracı izolasyonu korunur) ve `auth.users` tablosunun
// dolu olması gerekmez. Üretime çıkarken NEXT_PUBLIC_DEMO_MODE=false yapın.
//
// Bu dosya istemci tarafında da import edilebilir; node/crypto burada KULLANILMAZ.

export const DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === "true";

// Seed'deki sabit UUID'ler (Örnek İthalat müşteri yöneticisi Ayşe)
export const DEMO_USER_ID = "20000000-0000-4000-8000-000000000005";
export const DEMO_COMPANY_ID = "10000000-0000-4000-8000-000000000002";
export const DEMO_COMPANY_NAME = "Örnek İthalat";
export const DEMO_EMAIL = "ayse@ornekithalat.com";
export const DEMO_FULL_NAME = "Ayşe Yılmaz";
export const DEMO_ROLE_CODE = "customer_admin";
export const DEMO_ROLE_NAME = "Kurumsal Müşteri Yöneticisi";

// customer_admin izin kümesi (migration 2 ile birebir)
export const DEMO_PERMISSIONS: string[] = [
  "company.manage_own", "users.manage_own", "suppliers.manage_own",
  "requests.create", "requests.view_own", "quotations.view_own", "quotations.respond",
  "consolidations.view_own", "shipments.view_own", "documents.upload_own", "documents.view_own",
  "deliveries.request", "finance.view_own_balance", "finance.report_payment",
  "messages.send", "tickets.create",
];
