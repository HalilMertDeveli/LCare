"use client";

import { RefreshCw } from "lucide-react";

import { ErrorAlert } from "@/components/error-alert";
import { CustomerRequestList } from "@/components/requests/customer-request-list";
import { ServiceRequestForm } from "@/components/requests/service-request-form";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api/endpoints";
import { t } from "@/lib/i18n";
import { useRealtimeRefresh } from "@/lib/realtime/realtime-provider";
import { useResource } from "@/lib/use-resource";

export function CustomerDashboard() {
  const list = useResource((signal) => api.listServiceRequests({ pageSize: 50 }, signal), []);
  useRealtimeRefresh(() => void list.reload());

  return (
    <div className="space-y-6">
      <div className="space-y-1">
        <h1 className="text-2xl font-semibold tracking-tight">{t.customer.title}</h1>
        <p className="text-sm text-muted-foreground">{t.customer.lead}</p>
      </div>
      <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_400px]">
        <section aria-labelledby="my-requests" className="order-2 space-y-3 lg:order-1">
          <div className="flex items-center justify-between gap-2">
            <h2 id="my-requests" className="text-lg font-semibold">
              {t.customer.listTitle}
              {list.data ? (
                <span className="ml-2 text-sm font-normal text-muted-foreground">
                  {t.requests.totalCount(list.data.totalCount)}
                </span>
              ) : null}
            </h2>
            <Button size="sm" variant="ghost" onClick={() => void list.reload()}>
              <RefreshCw aria-hidden />
              {t.requests.refresh}
            </Button>
          </div>
          {list.error ? <ErrorAlert error={list.error} onRetry={() => void list.reload()} /> : null}
          {list.loading ? (
            <p className="text-sm text-muted-foreground">{t.requests.loading}</p>
          ) : list.data ? (
            <CustomerRequestList items={list.data.items} />
          ) : null}
        </section>
        <section
          aria-labelledby="new-request"
          className="order-1 h-fit space-y-3 rounded-lg border bg-card p-4 sm:p-6 lg:order-2"
        >
          <h2 id="new-request" className="text-lg font-semibold">
            {t.customer.formTitle}
          </h2>
          <ServiceRequestForm onCreated={() => void list.reload()} />
        </section>
      </div>
    </div>
  );
}
