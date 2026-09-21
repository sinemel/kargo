import { Card, CardContent } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function StatCard({ label, value, hint, icon: Icon, tone = "primary" }: {
  label: string; value: string; hint?: string;
  icon: React.ComponentType<{ className?: string }>;
  tone?: "primary" | "accent" | "warning" | "danger" | "success";
}) {
  const toneCls = {
    primary: "bg-primary/10 text-primary",
    accent: "bg-accent/10 text-accent",
    warning: "bg-warning/12 text-warning",
    danger: "bg-danger/12 text-danger",
    success: "bg-success/12 text-success",
  }[tone];
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-5">
        <span className={cn("flex h-11 w-11 shrink-0 items-center justify-center rounded-lg", toneCls)}>
          <Icon className="h-5 w-5" />
        </span>
        <div className="min-w-0">
          <p className="truncate text-sm text-muted-foreground">{label}</p>
          <p className="text-xl font-bold">{value}</p>
          {hint && <p className="truncate text-xs text-muted-foreground">{hint}</p>}
        </div>
      </CardContent>
    </Card>
  );
}
