import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";

import { t } from "@/lib/i18n";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin", "latin-ext"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin", "latin-ext"],
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000"),
  title: { default: t.home.metaTitle, template: `%s — ${t.brand.name}` },
  description: t.home.metaDescription,
  applicationName: t.brand.name,
};

export const viewport: Viewport = {
  themeColor: "#0d1b33",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="tr" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:rounded focus:bg-card focus:px-3 focus:py-2 focus:shadow"
        >
          {t.nav.skipToContent}
        </a>
        {children}
      </body>
    </html>
  );
}
