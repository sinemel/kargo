import { cn } from "@/lib/utils";

export function Progress({ value, tone = "accent", className }: { value: number; tone?: "accent" | "warning" | "danger" | "success"; className?: string }) {
  const pct = Math.min(Math.max(value, 0), 100);
  const bar = { accent: "bg-accent", warning: "bg-warning", danger: "bg-danger", success: "bg-success" }[tone];
  return (
    <div className={cn("h-2.5 w-full overflow-hidden rounded-full bg-secondary", className)}>
      <div className={cn("h-full rounded-full transition-all", bar)} style={{ width: `${pct}%` }} />
    </div>
  );
}
