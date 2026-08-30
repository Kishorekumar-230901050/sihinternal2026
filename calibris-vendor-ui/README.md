# Calibris — User / Vendor App

React Native (Expo, TypeScript) implementation of the user-side flow:

```
Login → Register Instrument → Apply for Verification → Select Nearby GATC →
Pay Fee → Track Application → Verification → Certificate → Re-verification & Alerts
```

This covers the **core demo path** end to end against realistic mock data. It's
built so every screen already talks to a single typed data layer
(`src/context/AppContext.tsx`) — swapping the mock functions in that one file
for real API calls is the only change needed to point this at a live backend.

## Setup

This project was hand-written in an environment without npm registry access,
so dependencies were never installed or version-resolved here. On a machine
with normal internet access:

```bash
cd calibris-user-app
npx expo install   # resolves every dependency to versions compatible with the pinned Expo SDK
npx expo start      # opens Expo Dev Tools — scan the QR with Expo Go, or press i / a / w
```

`npx expo install` (not plain `npm install`) is recommended the first time —
it cross-checks each package in `package.json` against the Expo SDK version
and adjusts anything mismatched.

### Demo credentials

- **Login**: any mobile/email + any password logs into the seeded demo account.
- **OTP** (during Create Account): the code is always `1234`.

## Project structure

```
src/
  theme/        colors, typography, spacing — the whole design system in 3 files
  types/        domain types (Instrument, VerificationApplication, Gatc, Certificate, ...)
  data/         seed/mock data — swap for real API responses later
  utils/        geo.ts (haversine distance), ids.ts (ID generators)
  context/      AppContext.tsx — single in-memory store + all "backend" actions
  components/   shared UI: Button, TextField, Card, StatusBadge, Timeline, Screen, ...
  navigation/   RootNavigator (auth vs. app switch), MainTabNavigator, param types
  screens/
    auth/           Splash, Login, Register, OtpVerification
    dashboard/       Dashboard (home tab)
    instruments/     MyInstruments, RegisterInstrument, InstrumentDetails
    verification/    ApplyVerification, LocationPermission, FindGatc, GatcDetails, ApplicationSummary
    payment/         Payment, ApplicationSubmitted (payment success + submission confirmation combined)
    tracking/        MyApplications (tab), ApplicationTracking, VerificationAppointment
    certificates/    CertificateWallet (tab), CertificateDetails
    notifications/   NotificationCentre
    profile/         Profile (tab)
```

## Design decisions worth knowing about

**Nearest-GATC without a full Maps SDK.** `src/utils/geo.ts` ranks GATCs by
haversine distance from the device's lat/long against a small GATC table
(`src/data/mockData.ts`) — exactly the "GPS + GATC database, no Maps SDK
required for ranking" approach. `FindGatcScreen` renders a lightweight
relative-position sketch instead of a tile map (no Google Maps API key is
wired up yet); swap that one component for a real `MapView` once a key
exists — the ranking logic underneath doesn't change. `VerificationAppointmentScreen`
does use a real "Get Directions" deep link into Google/Apple Maps via `Linking`,
since that needs no SDK or key.

**Payment never self-certifies.** `PaymentScreen` simulates a gateway
round-trip, but the comment there marks exactly where a real build inserts
backend-side transaction verification before moving the application to
`PAYMENT_CONFIRMED` — the frontend "success" screen is deliberately never the
source of truth (see the improvement notes in the project doc).

**The REJECTED/DISCREPANCY branch is real, not decorative.** `AppContext`
implements `submitVerificationResult(applicationId, 'PASSED' | 'REJECTED', ...)`
with two distinct outcomes: PASSED issues a certificate and updates the
instrument; REJECTED records a discrepancy and leaves the instrument
re-appliable. `ApplicationTrackingScreen` has "demo controls" (an outlined
button block, clearly labeled) that stand in for the LMO field app so a
reviewer can click through both branches without a second app existing yet.
Delete that block once the real LMO app / backend is wired in.

**Application state machine.** `VerificationApplication.status` follows
`APPLICATION_SUBMITTED → PAYMENT_CONFIRMED → GATC_SELECTED → SCHEDULED →
INSPECTION_IN_PROGRESS → PASSED/REJECTED → CERTIFICATE_ISSUED`, matching the
project's architecture doc. In this prototype the first four transitions
happen together the moment payment succeeds (since GATC + slot are already
chosen by then); a real backend would likely persist and surface each step
as its own event.

**QR verification.** The certificate QR encodes a verification URL
(`https://verify.calibris.gov.in/c/{certificateId}?t={token}`), not the
certificate data itself — a scanner always re-queries the backend for
current status, matching the "QR code alone is not a security mechanism"
principle in the architecture doc.

## What's intentionally out of scope for this pass

Per the agreed "core demo path" scope, these pages from the full 28-screen
flow aren't built yet: legacy certificate onboarding, instrument relocation,
multi-branch business grouping, in-app Help/Support, and full Settings
sub-pages (language, notification preferences) beyond their placeholder rows
in Profile. See `user-app-flow-review.md` in the project for the full list
and priority order if you want to extend this next.

## Wiring a real backend later

Everything a screen needs comes from `useApp()` (`src/context/AppContext.tsx`).
To connect a real API: keep the same function signatures on `AppContextValue`,
but replace each function body with an API call (and likely move from
`useState` to a data-fetching library like React Query). No screen file needs
to change.
