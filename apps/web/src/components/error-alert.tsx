"use client";

import { AlertCircle } from "lucide-react";

import { Alert, AlertDescription } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { errorMessage } from "@/lib/api/client";
import { t } from "@/lib/i18n";

export function ErrorAlert({
  error,
  message,
  onRetry,
}: {
  error?: unknown;
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <Alert variant="destructive" className="border-red-200 bg-red-50">
      <AlertCircle />
      <AlertDescription className="flex flex-wrap items-center justify-between gap-2">
        <span>{message ?? errorMessage(error)}</span>
        {onRetry ? (
          <Button size="sm" variant="outline" onClick={onRetry}>
            {t.errors.retry}
          </Button>
        ) : null}
      </AlertDescription>
    </Alert>
  );
}

export function SuccessAlert({ message }: { message: string }) {
  return (
    <Alert className="border-green-200 bg-green-50 text-green-900">
      <AlertDescription className="text-green-900">{message}</AlertDescription>
    </Alert>
  );
}
