// Müşteri panelinin dokunduğu tablolar/view'ler/RPC'ler için elle yazılmış tip alt kümesi.
// Tam sürüm: `npm run gen:types` (supabase gen types typescript --local).
//
// Not: @supabase/supabase-js her Tables/Views girdisinde `Relationships` alanı bekler
// (GenericTable/GenericView kısıtı). Alan yoksa satırlar `never` tipine düşer;
// bu yüzden her girdide `Relationships: []` yer alır.

export type Json = string | number | boolean | null | { [k: string]: Json } | Json[];

type Timestamps = { created_at: string; updated_at: string };
type Rel = [];

export interface Database {
  public: {
    Tables: {
      users: {
        Row: { id: string; email: string; full_name: string; phone: string | null; avatar_url: string | null; locale: string } & Timestamps;
        Insert: { id: string; email: string; full_name: string; phone?: string | null };
        Update: Partial<{ full_name: string; phone: string | null; avatar_url: string | null; locale: string }>;
        Relationships: Rel;
      };
      companies: {
        Row: { id: string; type: "operator" | "customer" | "partner"; legal_name: string; trade_name: string | null; tax_number: string | null; city: string | null; district: string | null; address: string | null; phone: string | null; email: string | null; default_currency: string; status: string } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      company_users: {
        Row: { id: string; company_id: string; user_id: string; role_id: string; title: string | null; is_primary_contact: boolean; status: string } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      customers: {
        Row: { id: string; company_id: string; customer_code: string; segment: string | null; trade_center: string | null; default_delivery_address: string | null; default_delivery_city: string | null; default_delivery_district: string | null; status: string } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      suppliers: {
        Row: {
          id: string; company_id: string; name: string; contact_name: string | null; phone: string | null; email: string | null; wechat: string | null;
          country_code: string; province: string | null; city: string | null; address: string | null; address_type: string;
          default_incoterm: string; products_summary: string | null; rating: number | null; notes: string | null; is_active: boolean; status: string;
          created_by: string | null; deleted_at: string | null;
        } & Timestamps;
        Insert: {
          company_id: string; name: string; contact_name?: string | null; phone?: string | null; email?: string | null; wechat?: string | null;
          province?: string | null; city?: string | null; address?: string | null; address_type?: string; default_incoterm?: string;
          products_summary?: string | null; notes?: string | null; created_by?: string | null;
        };
        Update: Partial<Database["public"]["Tables"]["suppliers"]["Insert"] & { is_active: boolean; status: string; deleted_at: string | null }>;
        Relationships: Rel;
      };
      shipment_requests: {
        Row: {
          id: string; request_no: string | null; company_id: string; customer_id: string; supplier_id: string | null;
          origin_country_code: string; origin_city: string | null; pickup_address: string | null; incoterm: string;
          delivery_address: string | null; delivery_city: string | null; delivery_district: string | null;
          requested_mode: string; suggested_mode: string | null; cargo_ready_date: string | null;
          goods_value: number | null; currency: string; declared_packages: number | null; declared_gross_kg: number | null;
          declared_cbm: number | null; is_dangerous: boolean; is_stackable: boolean; is_fragile: boolean;
          status: string; customer_note: string | null; submitted_at: string | null; shipment_id: string | null; created_by: string | null;
        } & Timestamps;
        Insert: {
          company_id: string; customer_id: string; supplier_id?: string | null;
          origin_country_code?: string; origin_city?: string | null; pickup_address?: string | null; incoterm?: string;
          delivery_address?: string | null; delivery_city?: string | null; delivery_district?: string | null;
          requested_mode?: string; cargo_ready_date?: string | null;
          goods_value?: number | null; currency?: string;
          declared_packages?: number | null; declared_gross_kg?: number | null; declared_cbm?: number | null;
          is_dangerous?: boolean; is_stackable?: boolean; is_fragile?: boolean;
          status?: string; customer_note?: string | null; submitted_at?: string | null; created_by?: string | null;
        };
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      shipment_items: {
        Row: {
          id: string; request_id: string; company_id: string; line_no: number; description: string; hs_code_estimated: string | null;
          package_type: string; package_count: number; length_cm: number; width_cm: number; height_cm: number;
          gross_kg_per_package: number; net_kg_per_package: number | null; unit_cbm: number; total_cbm: number; total_gross_kg: number;
          goods_value: number | null; currency: string; is_dangerous: boolean; is_stackable: boolean; is_fragile: boolean;
        } & Timestamps;
        Insert: {
          request_id: string; company_id: string; line_no: number; description: string; hs_code_estimated?: string | null;
          package_type: "carton" | "pallet" | "crate" | "bag" | "drum" | "roll" | "other"; package_count: number;
          length_cm: number; width_cm: number; height_cm: number;
          gross_kg_per_package: number; net_kg_per_package?: number | null;
          goods_value?: number | null; currency?: string;
          is_dangerous?: boolean; is_stackable?: boolean; is_fragile?: boolean;
        };
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      quotations: {
        Row: {
          id: string; quotation_no: string | null; version: number; company_id: string; customer_id: string; consolidation_id: string | null;
          status: string; transport_mode: string; incoterm: string; currency: string; exchange_rates: Json;
          quote_date: string; valid_until: string; transit_days_min: number | null; transit_days_max: number | null;
          planned_departure_date: string | null; estimated_arrival_date: string | null; chargeable_wm: number | null;
          included_services: string[]; excluded_services: string[]; special_terms: string | null; payment_plan: string | null;
          cancellation_terms: string | null; delay_force_majeure_terms: string | null; subtotal: number; total: number;
          customer_response_note: string | null; approved_at: string | null; sent_at: string | null;
        } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      quotation_items: {
        Row: {
          id: string; quotation_id: string; company_id: string; sort_order: number; category: string; description_tr: string;
          certainty: string; quantity: number; unit: string; unit_price: number; amount: number; currency: string; note: string | null;
        } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      precheck_flags: {
        Row: { id: string; request_id: string; company_id: string; flag_type: string; severity: string; message_tr: string; source: string; resolved_at: string | null } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      warehouse_receipts: {
        Row: {
          id: string; receipt_no: string | null; delivery_code: string | null; company_id: string; customer_id: string; request_id: string | null;
          supplier_id: string | null; warehouse_id: string; consolidation_id: string | null; status: string;
          expected_packages: number | null; received_packages: number; actual_gross_kg: number | null; actual_cbm: number | null;
          damage_status: string; received_at: string | null; ready_at: string | null;
        } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      shipments: {
        Row: {
          id: string; shipment_no: string | null; company_id: string; customer_id: string; quotation_id: string | null;
          consolidation_id: string | null; schedule_id: string | null; container_id: string | null; hbl_no: string | null;
          transport_mode: string; incoterm: string; status: string; current_milestone_code: string | null; current_milestone_at: string | null;
          origin_port: string | null; destination_port: string | null; etd: string | null; eta: string | null;
          total_packages: number | null; total_gross_kg: number | null; total_cbm: number | null; is_delayed: boolean; delivered_at: string | null;
        } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      notifications: {
        Row: { id: string; company_id: string | null; user_id: string; event_key: string; title_tr: string; body_tr: string | null; entity_type: string | null; entity_id: string | null; channel: string; is_read: boolean; read_at: string | null; created_at: string };
        Insert: Record<string, unknown>;
        Update: { is_read?: boolean; read_at?: string | null };
        Relationships: Rel;
      };
      warehouses: {
        Row: { id: string; code: string; name: string; country_code: string; city: string; address: string | null; is_public: boolean; is_active: boolean } & Timestamps;
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
      system_settings: {
        Row: { key: string; value: Json; description: string | null; is_public: boolean; updated_at: string };
        Insert: Record<string, unknown>;
        Update: Record<string, unknown>;
        Relationships: Rel;
      };
    };
    Views: {
      customer_balance_v: {
        Row: { customer_id: string; company_id: string; currency: string | null; invoiced_total: number; paid_total: number; open_balance: number; overdue_balance: number; due_within_7_days: number };
        Relationships: Rel;
      };
      consolidation_summary_v: {
        Row: { consolidation_id: string; company_id: string; consolidation_no: string | null; status: string; receipt_count: number; supplier_count: number; total_packages: number; total_gross_kg: number; total_cbm: number; ready_receipts: number; missing_packages: number };
        Relationships: Rel;
      };
    };
    Functions: {
      approve_quotation: { Args: { p_quotation_id: string; p_note?: string | null }; Returns: Json };
      request_quotation_revision: { Args: { p_quotation_id: string; p_note: string }; Returns: Json };
      report_payment: { Args: { p_invoice_id: string; p_amount: number; p_method?: string; p_reference_no?: string | null; p_receipt_document_id?: string | null; p_note?: string | null }; Returns: Json };
      mark_notifications_read: { Args: { p_ids?: string[] | null }; Returns: number };
      calc_cbm: { Args: { p_length_cm: number; p_width_cm: number; p_height_cm: number; p_count?: number }; Returns: number };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
}
