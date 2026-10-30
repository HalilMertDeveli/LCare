import { CustomerDashboard } from "@/components/views/customer-dashboard";

// Authenticated, client-rendered area: content depends on the session (resolved in the
// browser via /api/me), so it is not part of a static shell. Opt out of instant-nav validation.
export const instant = false;

export default function CustomerHomePage() {
  return <CustomerDashboard />;
}
