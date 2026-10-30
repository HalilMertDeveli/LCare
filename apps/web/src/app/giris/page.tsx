import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";

import { BrandMark } from "@/components/brand";
import { LoginFormWithParams } from "@/components/views/login-form-with-params";
import { t } from "@/lib/i18n";

export const metadata: Metadata = {
  title: { absolute: t.login.metaTitle },
  robots: { index: false, follow: true },
};

export default function LoginPage() {
  return (
    <main id="main" className="flex flex-1 items-center justify-center bg-navy px-4 py-12">
      <div className="w-full max-w-sm space-y-6">
        <Link href="/" className="flex items-center justify-center gap-2 text-lg font-semibold text-white">
          <BrandMark />
          {t.brand.name}
        </Link>
        <div className="space-y-5 rounded-xl bg-card p-6 shadow-xl">
          <div className="space-y-1">
            <h1 className="text-xl font-semibold tracking-tight">{t.login.title}</h1>
            <p className="text-sm text-muted-foreground">{t.login.lead}</p>
          </div>
          <Suspense>
            <LoginFormWithParams />
          </Suspense>
        </div>
      </div>
    </main>
  );
}
