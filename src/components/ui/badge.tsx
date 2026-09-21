import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";
import type { BadgeTone } from "@/lib/constants";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium transition-colors",
  {
    variants: {
      tone: {
        default: "border-transparent bg-primary/10 text-primary",
        success: "border-transparent bg-success/12 text-success",
        warning: "border-transparent bg-warning/15 text-warning",
        danger: "border-transparent bg-danger/12 text-danger",
        info: "border-transparent bg-info/12 text-info",
        muted: "border-transparent bg-muted text-muted-foreground",
      },
    },
    defaultVariants: { tone: "default" },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  tone?: BadgeTone;
}

function Badge({ className, tone, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ tone }), className)} {...props} />;
}
export { Badge, badgeVariants };
