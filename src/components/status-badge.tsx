import { Badge } from "@/components/ui/badge";
import type { BadgeTone } from "@/lib/constants";

export function StatusBadge({ map, value }: { map: Record<string, { label: string; tone: BadgeTone }>; value: string | null | undefined }) {
  if (!value) return <Badge tone="muted">—</Badge>;
  const s = map[value];
  return <Badge tone={s?.tone ?? "default"}>{s?.label ?? value}</Badge>;
}
