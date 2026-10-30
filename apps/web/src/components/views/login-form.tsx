"use client";

import { useId, useState, type FormEvent } from "react";

import { ErrorAlert } from "@/components/error-alert";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ApiError } from "@/lib/api/client";
import { api } from "@/lib/api/endpoints";
import type { MeResponse } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { resolveShell, safeNextPath } from "@/lib/session";
import { validateLogin } from "@/lib/validation";

export interface LoginFormProps {
  /** Post-login target requested via `?next=` (validated against the user's shell). */
  next?: string | null;
  /** Injectable for tests. */
  login?: typeof api.login;
  me?: () => Promise<MeResponse>;
  navigate?: (href: string) => void;
}

function loginErrorMessage(err: unknown): string {
  if (err instanceof ApiError) {
    if (err.kind === "unauthorized") return t.login.invalidCredentials;
    if (err.kind === "rateLimited") return t.login.rateLimited;
    if (err.kind === "validation") return t.login.invalidCredentials;
    return t.errors[err.kind];
  }
  return t.errors.unknown;
}

export function LoginForm({
  next,
  login = api.login,
  me = () => api.me(),
  navigate = (href) => window.location.assign(href),
}: LoginFormProps) {
  const id = useId();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fieldErrors, setFieldErrors] = useState<{ email?: string; password?: string }>({});
  const [error, setError] = useState<string>();
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(undefined);
    const errors = validateLogin(email, password);
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) return;

    setSubmitting(true);
    try {
      await login({ email: email.trim(), password });
      const profile = await me();
      const shell = resolveShell(profile);
      if (shell === "none") {
        setError(t.login.noRole);
        setSubmitting(false);
        return;
      }
      // Full navigation so the new session cookie is used by every subsequent request.
      navigate(safeNextPath(next, shell));
    } catch (err) {
      setError(loginErrorMessage(err));
      setSubmitting(false);
    }
  }

  return (
    <form onSubmit={onSubmit} noValidate className="space-y-4" aria-label={t.login.title}>
      <div className="space-y-1.5">
        <Label htmlFor={`${id}-email`}>{t.login.email}</Label>
        <Input
          id={`${id}-email`}
          type="email"
          name="email"
          autoComplete="username"
          inputMode="email"
          value={email}
          aria-invalid={fieldErrors.email ? true : undefined}
          onChange={(e) => setEmail(e.target.value)}
          className="h-10"
        />
        {fieldErrors.email ? (
          <p className="text-xs text-destructive" role="alert">
            {fieldErrors.email}
          </p>
        ) : null}
      </div>
      <div className="space-y-1.5">
        <Label htmlFor={`${id}-password`}>{t.login.password}</Label>
        <Input
          id={`${id}-password`}
          type="password"
          name="password"
          autoComplete="current-password"
          value={password}
          aria-invalid={fieldErrors.password ? true : undefined}
          onChange={(e) => setPassword(e.target.value)}
          className="h-10"
        />
        {fieldErrors.password ? (
          <p className="text-xs text-destructive" role="alert">
            {fieldErrors.password}
          </p>
        ) : null}
      </div>
      {error ? <ErrorAlert message={error} /> : null}
      <Button type="submit" size="lg" className="h-10 w-full" disabled={submitting}>
        {submitting ? t.login.submitting : t.login.submit}
      </Button>
    </form>
  );
}
