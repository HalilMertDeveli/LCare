import type { ServiceRequestStatus } from "@/lib/api/types";
import { cn } from "@/lib/utils";
import { STATUS_STYLES, statusLabel } from "@/lib/status";

export function StatusBadge({
  status,
  className,
}: {
  status: ServiceRequestStatus;
  className?: string;
}) {
  const style = STATUS_STYLES[status];
  return (
    <span
      data-status={status}
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium whitespace-nowrap ring-1 ring-inset",
        style.badge,
        className,
      )}
    >
      <span aria-hidden className={cn("size-1.5 rounded-full", style.dot)} />
      {statusLabel(status)}
    </span>
  );
}
