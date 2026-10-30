"use client";

import { useState } from "react";
import { RefreshCw } from "lucide-react";

import { ErrorAlert } from "@/components/error-alert";
import { AdminRequestTable } from "@/components/requests/admin-request-table";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api/endpoints";
import { SERVICE_REQUEST_STATUSES, type ServiceRequestStatus } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { useRealtimeRefresh } from "@/lib/realtime/realtime-provider";
import { statusLabel } from "@/lib/status";
import { useResource } from "@/lib/use-resource";

const PAGE_SIZE = 25;

export function AdminRequestsPage() {
  const [status, setStatus] = useState<ServiceRequestStatus | "">("");
  const [page, setPage] = useState(1);
  const list = useResource(
    (signal) =>
      api.listServiceRequests({ status: status || undefined, page, pageSize: PAGE_SIZE }, signal),
    [status, page],
  );
  useRealtimeRefresh(() => void list.reload());

  const totalPages = list.data ? Math.max(1, Math.ceil(list.data.totalCount / PAGE_SIZE)) : 1;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">{t.admin.title}</h1>
          <p className="text-sm text-muted-foreground">{t.admin.lead}</p>
        </div>
        <div className="flex flex-wrap items-end gap-2">
          <label className="flex flex-col gap-1 text-xs font-medium text-muted-foreground">
            {t.admin.filterLabel}
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as ServiceRequestStatus | "");
                setPage(1);
              }}
              className="h-8 rounded-md border border-input bg-card px-2 text-sm text-foreground outline-none focus-visible:ring-3 focus-visible:ring-ring/50"
            >
              <option value="">{t.admin.filterAll}</option>
              {SERVICE_REQUEST_STATUSES.map((s) => (
                <option key={s} value={s}>
                  {statusLabel(s)}
                </option>
              ))}
            </select>
          </label>
          <Button size="sm" variant="outline" onClick={() => void list.reload()}>
            <RefreshCw aria-hidden />
            {t.requests.refresh}
          </Button>
        </div>
      </div>

      {list.error ? <ErrorAlert error={list.error} onRetry={() => void list.reload()} /> : null}
      {list.loading ? (
        <p className="text-sm text-muted-foreground">{t.requests.loading}</p>
      ) : list.data ? (
        <>
          <AdminRequestTable items={list.data.items} />
          <div className="flex flex-wrap items-center justify-between gap-2 text-xs text-muted-foreground">
            <span>{t.requests.totalCount(list.data.totalCount)}</span>
            {totalPages > 1 ? (
              <div className="flex items-center gap-2">
                <Button
                  size="xs"
                  variant="outline"
                  disabled={page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  {t.requests.previousPage}
                </Button>
                <span>{t.requests.pageInfo(page, totalPages)}</span>
                <Button
                  size="xs"
                  variant="outline"
                  disabled={page >= totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  {t.requests.nextPage}
                </Button>
              </div>
            ) : null}
          </div>
        </>
      ) : null}
    </div>
  );
}
