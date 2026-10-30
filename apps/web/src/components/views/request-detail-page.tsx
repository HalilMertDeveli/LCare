"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";

import { ErrorAlert } from "@/components/error-alert";
import { RequestDetailView } from "@/components/requests/request-detail-view";
import { AdminStatusActions, CustomerCancelAction } from "@/components/requests/status-actions";
import { api } from "@/lib/api/endpoints";
import type { ServiceRequestDetail } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { useRealtimeRefresh } from "@/lib/realtime/realtime-provider";
import { useResource } from "@/lib/use-resource";

/** Detail page for both areas; `mode` decides back link and which actions are offered. */
export function RequestDetailPage({ mode }: { mode: "customer" | "admin" }) {
  const params = useParams<{ id: string }>();
  const id = params.id;
  const resource = useResource((signal) => api.getServiceRequest(id, signal), [id]);
  // A successful mutation returns the fresh detail; prefer it until the next fetch lands.
  const [override, setOverride] = useState<ServiceRequestDetail>();
  const request =
    override && resource.data && override.version > resource.data.version ? override : resource.data;

  useRealtimeRefresh(
    () => void resource.reload(),
    (event) => event.serviceRequestId === id,
  );

  const backHref = mode === "admin" ? "/yonetim" : "/musteri";

  if (resource.loading) return <p className="text-sm text-muted-foreground">{t.requests.loading}</p>;
  if (!request) {
    return (
      <div className="space-y-4">
        <ErrorAlert
          error={resource.error}
          onRetry={
            resource.error && (resource.error as { kind?: string }).kind !== "notFound"
              ? () => void resource.reload()
              : undefined
          }
        />
        <Link href={backHref} className="text-sm text-primary hover:underline">
          {t.requests.back}
        </Link>
      </div>
    );
  }

  const actionProps = {
    request,
    onChanged: (updated: ServiceRequestDetail) => {
      setOverride(updated);
      void resource.reload();
    },
    onStale: () => resource.reload(),
  };

  return (
    <div className="space-y-4">
      {resource.error ? (
        <ErrorAlert error={resource.error} onRetry={() => void resource.reload()} />
      ) : null}
      <RequestDetailView
        request={request}
        backHref={backHref}
        showCustomer={mode === "admin"}
        actions={
          mode === "admin" ? (
            <AdminStatusActions {...actionProps} />
          ) : (
            <CustomerCancelAction {...actionProps} />
          )
        }
      />
    </div>
  );
}
