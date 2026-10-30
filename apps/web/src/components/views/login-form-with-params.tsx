"use client";

import { useSearchParams } from "next/navigation";

import { LoginForm } from "./login-form";

export function LoginFormWithParams() {
  const params = useSearchParams();
  return <LoginForm next={params.get("next")} />;
}
