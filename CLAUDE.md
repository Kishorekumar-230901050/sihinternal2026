# CLAUDE.md - AI Instructions & Calibris Project Guide

## ⚙️ AI Behavioral Directives (Token Efficiency Rules)
- **Extreme Conciseness**: Be direct and telegraphic. Eliminate conversational filler, pleasantries, and unsolicited summaries.
- **Minimal Code Diffs**: When modifying code, show only targeted changes or precise replacements. Do not rewrite unchanged files or classes.
- **Fast Execution**: Prioritize actionable code and terminal commands over long explanations.
- **Assume Context**: Do not re-explain the architecture, PRD, or tech stack unless explicitly requested.

---

## 📌 Project Architecture
- `calibris-backend`: Express, TypeScript, Prisma 7, PostgreSQL, PDFKit, QRCode
- `calibris-admin-ui`: React, Vite, TailwindCSS
- `calibris-vendor-ui`: React, Vite
- `calibris-lmo-ui`: Flutter Mobile (Android/iOS)

---

## 👤 Pre-Seeded Test Accounts (`npm run seed`)
- Vendor: `vendor@example.com` / `Vendor@123`
- LMO: `lmo@example.com` / `Lmo@12345`
- Admin: `admin@example.com` / `Admin@12345`

---

## 🔄 Core MVP Lifecycle (PS 26036)
`Register Instrument` → `Submit App (PENDING)` → `Admin Assigns LMO` → `LMO Field Inspection (Observed vs Std, PASS/FAIL)` → `Auto-Gen PDF + QR` → `Public Verify /api/verify/:qrToken`

---

## ⚡ API Surface
```
POST /api/auth/{vendor,lmo,admin}/login
POST /api/auth/vendor/register

# Vendor (Bearer Token: VENDOR)
GET  /api/vendor/dashboard
GET  /api/vendor/instruments
POST /api/vendor/instruments          # { serialNumber, instrumentTypeId, model, capacity }
GET  /api/vendor/applications
POST /api/vendor/applications         # { instrumentId, gatcId, documents, photos }
GET  /api/vendor/certificates

# LMO Officer (Bearer Token: LMO)
GET  /api/lmo/dashboard
GET  /api/lmo/inspections
POST /api/lmo/inspections/:id/start   # { gpsLatitude, gpsLongitude }
POST /api/lmo/inspections/:id/result  # { status: "PASSED"|"FAILED", remarks }

# Admin (Bearer Token: ADMIN)
GET  /api/admin/dashboard
GET  /api/admin/applications
POST /api/admin/applications/:id/assign # { lmoId, slotDate }

# Public Verification (No Auth)
GET  /api/verify/:qrToken
```

---

## 🛠️ CLI Reference
```bash
# Backend Setup & Run
cd calibris-backend
npm i && npm run prisma:generate && npm run prisma:push && npm run seed && npm run dev

# Frontends
cd calibris-admin-ui && npm run dev
cd calibris-vendor-ui && npm run dev
cd calibris-lmo-ui && flutter run
```

---

## 🚀 Railway Deployment Settings
- **Root Directory**: `/calibris-backend`
- **Build**: `npm i && npx prisma generate && npm run build`
- **Start**: `npx prisma db push && npm run start`
- **Env**: `DATABASE_URL`, `DIRECT_URL`, `JWT_SECRET`, `PORT=3000`
