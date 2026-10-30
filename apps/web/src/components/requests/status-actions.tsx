"use client";

import { useId, useState } from "react";

import { ErrorAlert, SuccessAlert } from "@/components/error-alert";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { ApiError, redirectToLogin } from "@/lib/api/client";
import { api } from "@/lib/api/endpoints";
import type { ServiceRequestDetail, ServiceRequestStatus } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { statusLabel } from "@/lib/status";
import { LIMITS } from "@/lib/validation";

type ChangeFn = typeof api.changeStatus;

interface CommonProps {
  request: ServiceRequestDetail;
  /** Called with the server's response after a successful change. */
  onChanged: (updated: ServiceRequestDetail) => void;
  /** Re-fetches the request (used after a 409 so the user sees the current state). */
  onStale: () => Promise<void> | void;
  changeStatus?: ChangeFn;
}

function useStatusChange({ request, onChanged, onStale, changeStatus = api.changeStatus }: CommonProps) {
  const [pending, setPending] = useState<ServiceRequestStatus | null>(null);
  const [error, setError] = useState<unknown>();
  const [success, setSuccess] = useState<string>();

  async function run(status: ServiceRequestStatus, note: string | null): Promise<boolean> {
    setPending(status);
    setError(undefined);
    setSuccess(undefined);
    try {
      // `version` is the one we last read: the API answers 409 if someone changed it since.
      const updated = await changeStatus(request.id, { status, version: request.version, note });
      setSuccess(t.admin.changed(statusLabel(updated.status)));
      onChanged(updated);
      return true;
    } catch (err) {
      if (err instanceof ApiError && err.kind === "unauthorized") {
        redirectToLogin();
        return false;
      }
      setError(err);
      if (err instanceof ApiError && (err.kind === "conflict" || err.kind === "forbidden")) {
        await onStale();
      }
      return false;
    } finally {
      setPending(null);
    }
  }

  return { pending, error, success, run };
}

/** Staff: one button per transition the API allows for this caller, plus an optional note. */
export function AdminStatusActions(props: CommonProps) {
  const id = useId();
  const [note, setNote] = useState("");
  const { pending, error, success, run } = useStatusChange(props);
  const transitions = props.request.allowedTransitions;
  const noteTooLong = note.trim().length > LIMITS.noteMax;

  return (
    <section className="space-y-3 rounded-lg border bg-card p-4" aria-labelledby={`${id}-h`}>
      <div>
        <h2 id={`${id}-h`} className="text-sm font-semibold">
          {t.admin.actionsTitle}
        </h2>
        <p className="text-xs text-muted-foreground">{t.admin.actionsLead}</p>
      </div>
      {transitions.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t.admin.noActions}</p>
      ) : (
        <>
          <div className="space-y-1.5">
            <Label htmlFor={`${id}-note`}>{t.admin.noteLabel}</Label>
            <Textarea
              id={`${id}-note`}
              rows={2}
              value={note}
              placeholder={t.admin.notePlaceholder}
              aria-invalid={noteTooLong || undefined}
              onChange={(e) => setNote(e.target.value)}
            />
            {noteTooLong ? (
              <p className="text-xs text-destructive" role="alert">
                {t.admin.noteTooLong}
              </p>
            ) : null}
          </div>
          <div className="flex flex-wrap gap-2" data-testid="status-actions">
            {transitions.map((status) => (
              <Button
                key={status}
                size="sm"
                variant={status === "Cancelled" ? "destructive" : "outline"}
                disabled={pending !== null || noteTooLong}
                data-transition={status}
                onClick={async () => {
                  const ok = await run(status, note.trim() || null);
                  if (ok) setNote("");
                }}
              >
                {pending === status ? t.admin.saving : statusLabel(status)}
              </Button>
            ))}
          </div>
        </>
      )}
      {error ? <ErrorAlert error={error} /> : null}
      {success ? <SuccessAlert message={success} /> : null}
    </section>
  );
}

/** Customer: only "cancel", and only when the API lists `Cancelled` as allowed. */
export function CustomerCancelAction(props: CommonProps) {
  const [confirming, setConfirming] = useState(false);
  const { pending, error, success, run } = useStatusChange(props);
  const canCancel = props.request.allowedTransitions.includes("Cancelled");

  if (!canCancel && !error && !success) return null;

  return (
    <section className="space-y-3 rounded-lg border bg-card p-4">
      {canCancel && !confirming ? (
        <Button variant="destructive" onClick={() => setConfirming(true)}>
          {t.customer.cancel}
        </Button>
      ) : null}
      {canCancel && confirming ? (
        <div className="space-y-3">
          <p className="text-sm">{t.customer.cancelConfirm}</p>
          <div className="flex flex-wrap gap-2">
            <Button
              variant="destructive"
              disabled={pending !== null}
              onClick={async () => {
                await run("Cancelled", null);
                setConfirming(false);
              }}
            >
              {pending ? t.customer.cancelling : t.customer.cancel}
            </Button>
            <Button variant="outline" onClick={() => setConfirming(false)} disabled={pending !== null}>
              {t.customer.keep}
            </Button>
          </div>
        </div>
      ) : null}
      {error ? <ErrorAlert error={error} /> : null}
      {success ? <SuccessAlert message={t.customer.cancelled} /> : null}
    </section>
  );
}
