import type { NextConfig } from "next";

/**
 * The browser only ever talks to the Next.js origin. `/api/*` and `/hubs/*` are rewritten
 * to the ASP.NET Core API so the HttpOnly `ledcare_session` cookie stays first-party.
 */
const apiUrl = (process.env.LEDCARE_API_URL ?? "http://localhost:5080").replace(/\/$/, "");

const nextConfig: NextConfig = {
  cacheComponents: true,
  partialPrefetching: true,
  poweredByHeader: false,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
  async rewrites() {
    return [
      { source: "/api/:path*", destination: `${apiUrl}/api/:path*` },
      { source: "/hubs/:path*", destination: `${apiUrl}/hubs/:path*` },
    ];
  },
};

export default nextConfig;
