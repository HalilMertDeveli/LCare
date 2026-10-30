"use client";

import { useId, useState, type FormEvent } from "react";

import { ErrorAlert, SuccessAlert } from "@/components/error-alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { ApiError, redirectToLogin } from "@/lib/api/client";
import { api } from "@/lib/api/endpoints";
import type { ServiceRequestDetail } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import {
  LIMITS,
  validateServiceRequest,
  type ServiceRequestErrors,
  type ServiceRequestInput,
} from "@/lib/validation";

/** Maps API validation errors (English, PascalCase keys) to our Turkish field messages. */
function serverFieldErrors(error: ApiError, input: ServiceRequestInput): ServiceRequestErrors {
  const fields = error.fieldErrors;
  const local = validateServiceRequest(input);
  const out: ServiceRequestErrors = {};
  if (fields.title) out.title = local.title ?? fields.title.join(" ");
  if (fields.description) out.description = local.description ?? fields.description.join(" ");
  return out;
}

export function ServiceRequestForm({
  onCreated,
  submit = api.createServiceRequest,
}: {
  onCreated?: (created: ServiceRequestDetail) => void;
  /** Injectable for tests. */
  submit?: (body: ServiceRequestInput) => Promise<ServiceRequestDetail>;
}) {
  const id = useId();
  const [values, setValues] = useState<ServiceRequestInput>({ title: "", description: "" });
  const [errors, setErrors] = useState<ServiceRequestErrors>({});
  const [formError, setFormError] = useState<unknown>();
  const [success, setSuccess] = useState<string>();
  const [submitting, setSubmitting] = useState(false);

  function update(field: keyof ServiceRequestInput, value: string) {
    setValues((v) => ({ ...v, [field]: value }));
    if (errors[field]) setErrors((e) => ({ ...e, [field]: undefined }));
    setSuccess(undefined);
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setFormError(undefined);
    setSuccess(undefined);
    const clientErrors = validateServiceRequest(values);
    setErrors(clientErrors);
    if (Object.keys(clientErrors).length > 0) return;

    setSubmitting(true);
    try {
      const created = await submit({
        title: values.title.trim(),
        description: values.description.trim(),
      });
      setValues({ title: "", description: "" });
      setSuccess(t.customer.created(created.referenceCode));
      onCreated?.(created);
    } catch (err) {
      if (err instanceof ApiError && err.kind === "unauthorized") return redirectToLogin();
      if (err instanceof ApiError && err.kind === "validation") {
        setErrors(serverFieldErrors(err, values));
        setFormError(err);
      } else if (err instanceof ApiError && err.kind === "forbidden") {
        setFormError(new ApiError("forbidden", 403));
      } else {
        setFormError(err);
      }
    } finally {
      setSubmitting(false);
    }
  }

  const titleLen = values.title.trim().length;
  const descLen = values.description.trim().length;

  return (
    <form onSubmit={onSubmit} noValidate className="space-y-4" aria-describedby={`${id}-lead`}>
      <p id={`${id}-lead`} className="text-sm text-muted-foreground">
        {t.customer.formLead}
      </p>
      <div className="space-y-1.5">
        <Label htmlFor={`${id}-title`}>{t.requests.title}</Label>
        <Input
          id={`${id}-title`}
          name="title"
          value={values.title}
          maxLength={LIMITS.titleMax + 50}
          placeholder={t.customer.titlePlaceholder}
          aria-invalid={errors.title ? true : undefined}
          aria-describedby={`${id}-title-hint`}
          onChange={(e) => update("title", e.target.value)}
        />
        <FieldHint
          id={`${id}-title-hint`}
          error={errors.title}
          count={t.customer.charCount(titleLen, LIMITS.titleMax)}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor={`${id}-description`}>{t.requests.description}</Label>
        <Textarea
          id={`${id}-description`}
          name="description"
          rows={5}
          value={values.description}
          placeholder={t.customer.descriptionPlaceholder}
          aria-invalid={errors.description ? true : undefined}
          aria-describedby={`${id}-description-hint`}
          onChange={(e) => update("description", e.target.value)}
        />
        <FieldHint
          id={`${id}-description-hint`}
          error={errors.description}
          count={t.customer.charCount(descLen, LIMITS.descriptionMax)}
        />
      </div>
      {formError ? <ErrorAlert error={formError} /> : null}
      {success ? <SuccessAlert message={success} /> : null}
      <Button type="submit" size="lg" disabled={submitting} className="w-full sm:w-auto">
        {submitting ? t.customer.submitting : t.customer.submit}
      </Button>
    </form>
  );
}

function FieldHint({ id, error, count }: { id: string; error?: string; count: string }) {
  return (
    <div id={id} className="flex justify-between gap-2 text-xs">
      <span className="text-destructive" role={error ? "alert" : undefined}>
        {error ?? ""}
      </span>
      <span className="text-muted-foreground tabular-nums">{count}</span>
    </div>
  );
}
