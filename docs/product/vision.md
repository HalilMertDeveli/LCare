# Product vision

LEDCare OS lets **anyone who owns an LED display** request professional technical support, regardless of
where the display was bought. Customers open requests from the web or the mobile app; a centrally managed
LED service operation diagnoses and resolves them — remotely (via AnyDesk), on site, or with a combination
(a remote specialist guiding a field technician). Every activity is recorded in one system.

Principles:

- **Humans repair, software coordinates.** Technicians diagnose and fix LED problems. The platform manages
  requests, people, communication, quotations, payments and records — it does not configure hardware.
- **One source of truth.** Web and mobile are two clients of the same ASP.NET Core API and PostgreSQL database.
- **Trust by design.** Customers only ever see their own records; technicians only what they are assigned;
  every important administrative action is audited.

Explicitly out of scope: Colorlight/NovaStar SDKs, hardware monitoring, automatic configuration, firmware
flashing, AI-made repair decisions, custom remote-desktop software, IoT infrastructure. AnyDesk stays an
external tool; LEDCare OS only stores authorized AnyDesk IDs, customer approvals and session logs (never passwords).
