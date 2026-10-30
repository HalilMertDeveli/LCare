import Link from "next/link";
import type { ReactNode } from "react";
import { ArrowLeft } from "lucide-react";

import { StatusBadge } from "@/components/status-badge";
import type { ServiceRequestDetail } from "@/lib/api/types";
import { formatDateTime, t } from "@/lib/i18n";
import { statusLabel } from "@/lib/status";

/** Read-only request detail shared by the customer and admin areas. */
export function RequestDetailView({
  request,
  backHref,
  showCustomer,
  actions,
}: {
  request: ServiceRequestDetail;
  backHref: string;
  showCustomer?: boolean;
  actions?: ReactNode;
}) {
  const history = [...request.history].sort(
    (a, b) => new Date(b.changedAt).getTime() - new Date(a.changedAt).getTime(),
  );
  return (
    <div className="space-y-6">
      <Link
        href={backHref}
        className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft aria-hidden className="size-4" />
        {t.requests.back}
      </Link>

      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        <article className="space-y-4 rounded-lg border bg-card p-4 sm:p-6">
          <header className="space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-mono text-sm text-muted-foreground">{request.referenceCode}</span>
              <StatusBadge status={request.status} />
            </div>
            <h1 className="text-xl font-semibold tracking-tight break-words">{request.title}</h1>
          </header>
          <dl className="grid grid-cols-1 gap-x-6 gap-y-2 text-sm sm:grid-cols-2">
            {showCustomer ? (
              <div>
                <dt className="text-muted-foreground">{t.requests.customer}</dt>
                <dd className="font-medium">{request.customerName}</dd>
              </div>
            ) : null}
            <div>
              <dt className="text-muted-foreground">{t.requests.createdAt}</dt>
              <dd>{formatDateTime(request.createdAt)}</dd>
            </div>
            <div>
              <dt className="text-muted-foreground">{t.requests.updatedAt}</dt>
              <dd>{formatDateTime(request.updatedAt)}</dd>
            </div>
          </dl>
          <section className="space-y-1">
            <h2 className="text-sm font-medium text-muted-foreground">{t.requests.description}</h2>
            <p className="text-sm leading-relaxed whitespace-pre-wrap break-words">
              {request.description}
            </p>
          </section>
        </article>

        <aside className="space-y-6">
          {actions}
          <section className="rounded-lg border bg-card p-4" aria-labelledby="history-heading">
            <h2 id="history-heading" className="mb-3 text-sm font-semibold">
              {t.requests.history}
            </h2>
            {history.length === 0 ? (
              <p className="text-sm text-muted-foreground">{t.requests.historyEmpty}</p>
            ) : (
              <ol className="space-y-3" data-testid="status-history">
                {history.map((h, i) => (
                  <li key={`${h.changedAt}-${i}`} className="border-l-2 pl-3 text-sm">
                    <div className="flex flex-wrap items-center gap-1.5">
                      {h.fromStatus ? (
                        <>
                          <span className="text-muted-foreground">{statusLabel(h.fromStatus)}</span>
                          <span aria-hidden className="text-muted-foreground">→</span>
                        </>
                      ) : null}
                      <StatusBadge status={h.toStatus} />
                    </div>
                    <div className="mt-1 text-xs text-muted-foreground">
                      {formatDateTime(h.changedAt)} · {t.requests.changedBy}: {h.changedBy}
                    </div>
                    {h.note ? (
                      <p className="mt-1 text-sm break-words">
                        <span className="text-muted-foreground">{t.requests.note}: </span>
                        {h.note}
                      </p>
                    ) : null}
                  </li>
                ))}
              </ol>
            )}
          </section>
        </aside>
      </div>
    </div>
  );
}
