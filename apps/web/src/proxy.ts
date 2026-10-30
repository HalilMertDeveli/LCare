import { NextResponse, type NextRequest } from "next/server";

import { SESSION_COOKIE } from "@/lib/session";

/**
 * UX-only route protection: without a session cookie there is no point rendering an
 * authenticated area, so send the user to the login page. Whether the cookie is valid — and
 * what the user may see — is decided by the API on every request.
 */
export function proxy(request: NextRequest) {
  if (request.cookies.has(SESSION_COOKIE)) return NextResponse.next();
  const url = request.nextUrl.clone();
  url.pathname = "/giris";
  url.search = "";
  url.searchParams.set("next", request.nextUrl.pathname + request.nextUrl.search);
  return NextResponse.redirect(url);
}

export const config = {
  matcher: ["/musteri/:path*", "/yonetim/:path*", "/teknisyen/:path*"],
};
