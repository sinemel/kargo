import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

const TR = "tr-TR";

export function formatCurrency(amount: number | null | undefined, currency = "USD"): string {
  if (amount == null) return "—";
  return new Intl.NumberFormat(TR, { style: "currency", currency, maximumFractionDigits: 2 }).format(amount);
}

export function formatNumber(value: number | null | undefined, digits = 2): string {
  if (value == null) return "—";
  return new Intl.NumberFormat(TR, { minimumFractionDigits: 0, maximumFractionDigits: digits }).format(value);
}

export function formatCbm(value: number | null | undefined): string {
  if (value == null) return "—";
  return `${formatNumber(value, 4)} m³`;
}

export function formatKg(value: number | null | undefined): string {
  if (value == null) return "—";
  return `${formatNumber(value, 2)} kg`;
}

export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = typeof value === "string" ? new Date(value) : value;
  return new Intl.DateTimeFormat(TR, { day: "2-digit", month: "long", year: "numeric" }).format(d);
}

export function formatDateTime(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = typeof value === "string" ? new Date(value) : value;
  return new Intl.DateTimeFormat(TR, {
    day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit",
  }).format(d);
}

export function formatRelative(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = typeof value === "string" ? new Date(value) : value;
  const diff = d.getTime() - Date.now();
  const abs = Math.abs(diff);
  const rtf = new Intl.RelativeTimeFormat(TR, { numeric: "auto" });
  const min = 60_000, hour = 3_600_000, day = 86_400_000;
  if (abs < hour) return rtf.format(Math.round(diff / min), "minute");
  if (abs < day) return rtf.format(Math.round(diff / hour), "hour");
  return rtf.format(Math.round(diff / day), "day");
}

export function daysUntil(value: string | Date | null | undefined): number | null {
  if (!value) return null;
  const d = typeof value === "string" ? new Date(value) : value;
  return Math.ceil((d.getTime() - Date.now()) / 86_400_000);
}

/** Baş harfleri (avatar için) */
export function initials(name: string | null | undefined): string {
  if (!name) return "?";
  return name.trim().split(/\s+/).slice(0, 2).map((p) => p[0]?.toLocaleUpperCase(TR) ?? "").join("");
}
