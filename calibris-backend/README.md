# CALIBRIS Backend

Express + TypeScript + Prisma 7 API powering all three CALIBRIS clients
(Vendor app, LMO app, Admin portal).

## Setup

```bash
cd backend
cp .env.example .env
# fill in DATABASE_URL, DIRECT_URL, JWT_SECRET (Supabase vars optional)

npm install
npm run prisma:generate
npm run prisma:push      # or prisma:migrate if you want tracked migrations
npm run seed
npm run dev               # http://localhost:3000
```

## Auth model

Three separate identity tables (`User` = vendor, `LMO`, `Admin`), each with
their own login endpoint but a shared JWT shape (`{ sub, role, email }`).
`requireAuth` + `requireRole(...)` middleware gate every non-public route.

Seeded credentials (see `prisma/seed.ts`):

| Role   | Email               | Password     |
|--------|---------------------|--------------|
| Vendor | vendor@example.com  | Vendor@123   |
| LMO    | lmo@example.com     | Lmo@12345    |
| Admin  | admin@example.com   | Admin@12345  |

## Application lifecycle

All status changes go through `services/status.service.ts`, which enforces
an explicit transition allow-list and writes an immutable
`ApplicationStatusHistory` row on every change — controllers never set
`application.status` directly.

```
SUBMITTED → DOCUMENTS_PENDING → DOCUMENTS_VERIFIED → SLOT_BOOKED
  → PAYMENT_PENDING → PAYMENT_COMPLETE → LMO_ASSIGNED
  → INSPECTION_IN_PROGRESS → INSPECTION_COMPLETE → PASSED|FAILED
  → CERTIFICATE_ISSUED | REJECTED
(CANCELLED reachable from most pre-inspection states)
```

## API surface

- `POST /api/auth/vendor/register`, `/vendor/login`, `/lmo/login`, `/admin/login`
- `/api/vendor/*` — instruments, applications, document upload, GATC search,
  appointment booking, mock payments, certificate download (JWT: VENDOR)
- `/api/lmo/*` — inspection queue, start inspection (GPS), discrepancies,
  photos, pass/fail submission (JWT: LMO)
- `/api/admin/*` — dashboard, LMO/GATC management, queue assignment,
  certificate approval, audit logs (JWT: ADMIN)
- `GET /api/verify/:qrToken` — public, no auth, returns masked verification
  info only (no vendor contact details)

## Storage

`services/storage.service.ts` uploads to Supabase Storage when
`SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` are set; otherwise it writes to
`./uploads` and the server serves that directory statically at
`http://localhost:3000/uploads/...`.

## Payments

`services/payment.service.ts` implements a two-phase mock Razorpay flow
(`createMockOrder` → client "checkout" → `verifyMockCallback`, HMAC-signed)
so swapping in real Razorpay keys later is a small, isolated change.
