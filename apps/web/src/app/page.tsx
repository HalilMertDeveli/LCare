import type { Metadata } from "next";
import Link from "next/link";
import { ArrowRight, Headset, MapPin, ShieldCheck, Wrench, CalendarCheck } from "lucide-react";

import { BrandMark } from "@/components/brand";
import { t } from "@/lib/i18n";

export const metadata: Metadata = {
  title: { absolute: t.home.metaTitle },
  description: t.home.metaDescription,
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    locale: "tr_TR",
    siteName: t.brand.name,
    title: t.home.metaTitle,
    description: t.home.metaDescription,
  },
};

const SERVICE_ICONS = [Headset, MapPin, Wrench, CalendarCheck];

const jsonLd = {
  "@context": "https://schema.org",
  "@type": "Service",
  serviceType: t.home.heroEyebrow,
  name: t.brand.name,
  description: t.home.metaDescription,
  areaServed: { "@type": "Country", name: "Türkiye" },
  hasOfferCatalog: {
    "@type": "OfferCatalog",
    name: t.home.servicesTitle,
    itemListElement: t.home.services.map((s) => ({
      "@type": "Offer",
      itemOffered: { "@type": "Service", name: s.title, description: s.body },
    })),
  },
};

export default function HomePage() {
  return (
    <>
      <header className="bg-navy text-navy-foreground">
        <nav
          aria-label={t.shell.mainNav}
          className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-4 py-4 sm:px-6"
        >
          <Link href="/" className="flex items-center gap-2 text-lg font-semibold">
            <BrandMark />
            {t.brand.name}
          </Link>
          <Link
            href="/giris"
            className="rounded-md border border-white/20 px-3 py-1.5 text-sm font-medium hover:bg-white/10"
          >
            {t.nav.login}
          </Link>
        </nav>
      </header>

      <main id="main" className="flex-1">
        <section className="bg-navy pb-20 text-navy-foreground">
          <div className="mx-auto max-w-6xl px-4 pt-12 sm:px-6 sm:pt-20">
            <p className="text-sm font-medium tracking-wide text-blue-300 uppercase">
              {t.home.heroEyebrow}
            </p>
            <h1 className="mt-3 max-w-3xl text-3xl font-semibold tracking-tight text-balance sm:text-5xl">
              {t.home.heroTitle}
            </h1>
            <p className="mt-5 max-w-2xl text-base text-white/75 sm:text-lg">{t.home.heroLead}</p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/giris?next=%2Fmusteri"
                className="inline-flex h-11 items-center gap-2 rounded-md bg-primary px-5 text-sm font-semibold text-primary-foreground hover:bg-primary/90"
              >
                {t.home.heroPrimaryCta}
                <ArrowRight aria-hidden className="size-4" />
              </Link>
              <Link
                href="/giris"
                className="inline-flex h-11 items-center rounded-md border border-white/25 px-5 text-sm font-semibold hover:bg-white/10"
              >
                {t.home.heroSecondaryCta}
              </Link>
            </div>
          </div>
        </section>

        <section aria-labelledby="services" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
          <h2 id="services" className="text-2xl font-semibold tracking-tight">
            {t.home.servicesTitle}
          </h2>
          <p className="mt-2 max-w-2xl text-muted-foreground">{t.home.servicesLead}</p>
          <ul className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {t.home.services.map((service, i) => {
              const Icon = SERVICE_ICONS[i] ?? Wrench;
              return (
                <li key={service.title} className="rounded-lg border bg-card p-5">
                  <Icon aria-hidden className="size-6 text-primary" />
                  <h3 className="mt-3 font-semibold">{service.title}</h3>
                  <p className="mt-1.5 text-sm text-muted-foreground">{service.body}</p>
                </li>
              );
            })}
          </ul>
        </section>

        <section aria-labelledby="brand-independent" className="border-y bg-card">
          <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-14 sm:flex-row sm:items-start sm:gap-8 sm:px-6">
            <ShieldCheck aria-hidden className="size-10 shrink-0 text-primary" />
            <div>
              <h2 id="brand-independent" className="text-2xl font-semibold tracking-tight">
                {t.home.brandIndependentTitle}
              </h2>
              <p className="mt-2 max-w-3xl text-muted-foreground">{t.home.brandIndependentBody}</p>
            </div>
          </div>
        </section>

        <section aria-labelledby="how" className="mx-auto max-w-6xl px-4 py-16 sm:px-6">
          <h2 id="how" className="text-2xl font-semibold tracking-tight">
            {t.home.howTitle}
          </h2>
          <ol className="mt-8 grid gap-6 sm:grid-cols-3">
            {t.home.howSteps.map((step, i) => (
              <li key={step.title} className="flex gap-4">
                <span
                  aria-hidden
                  className="flex size-8 shrink-0 items-center justify-center rounded-full bg-navy text-sm font-semibold text-white"
                >
                  {i + 1}
                </span>
                <div>
                  <h3 className="font-semibold">{step.title}</h3>
                  <p className="mt-1 text-sm text-muted-foreground">{step.body}</p>
                </div>
              </li>
            ))}
          </ol>
        </section>

        <section aria-labelledby="cta" className="mx-auto max-w-6xl px-4 pb-16 sm:px-6">
          <div className="flex flex-col items-start gap-4 rounded-xl bg-navy p-8 text-navy-foreground sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 id="cta" className="text-xl font-semibold">
                {t.home.ctaTitle}
              </h2>
              <p className="mt-1 text-white/75">{t.home.ctaBody}</p>
            </div>
            <Link
              href="/giris?next=%2Fmusteri"
              className="inline-flex h-11 shrink-0 items-center gap-2 rounded-md bg-primary px-5 text-sm font-semibold text-primary-foreground hover:bg-primary/90"
            >
              {t.nav.requestService}
              <ArrowRight aria-hidden className="size-4" />
            </Link>
          </div>
        </section>
      </main>

      <footer className="border-t bg-card">
        <div className="mx-auto max-w-6xl px-4 py-6 text-sm text-muted-foreground sm:px-6">
          {t.home.footer}
        </div>
      </footer>

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }}
      />
    </>
  );
}
