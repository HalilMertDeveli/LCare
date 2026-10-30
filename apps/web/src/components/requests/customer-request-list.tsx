import Link from "next/link";
import { ChevronRight } from "lucide-react";

import { StatusBadge } from "@/components/status-badge";
import type { ServiceRequestSummary } from "@/lib/api/types";
import { formatDateTime, t } from "@/lib/i18n";

/** Simple, touch-friendly list of the customer's own requests. */
export function CustomerRequestList({ items }: { items: ServiceRequestSummary[] }) {
  if (items.length === 0) {
    return (
      <p className="rounded-lg border border-dashed p-6 text-center text-sm text-muted-foreground">
        {t.customer.empty}
      </p>
    );
  }
  return (
    <ul className="divide-y rounded-lg border bg-card" aria-label={t.customer.listTitle}>
      {items.map((item) => (
        <li key={item.id} data-testid="request-item" data-reference={item.referenceCode}>
          <Link
            href={`/musteri/talepler/${item.id}`}
            className="flex items-center gap-3 p-4 transition-colors hover:bg-muted/60 focus-visible:bg-muted/60"
          >
            <div className="min-w-0 flex-1 space-y-1">
              <div className="flex flex-wrap items-center gap-2">
                <span className="font-mono text-xs text-muted-foreground">
                  {item.referenceCode}
                </span>
                <StatusBadge status={item.status} />
              </div>
              <p className="truncate font-medium">{item.title}</p>
              <p className="text-xs text-muted-foreground">
                {t.requests.createdAt}: {formatDateTime(item.createdAt)} ·{" "}
                {t.requests.updatedAt}: {formatDateTime(item.updatedAt)}
              </p>
            </div>
            <ChevronRight aria-hidden className="size-4 shrink-0 text-muted-foreground" />
          </Link>
        </li>
      ))}
    </ul>
  );
}
