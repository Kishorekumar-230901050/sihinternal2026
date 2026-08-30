---
name: calibris-backend
description: End-to-end implementation instructions for the 9 MVP pillars of the Legal Metrology Verification Platform (PS 26036).
---

# Calibris Backend Skill Guide (PS 26036 MVP)

Follow these concise step-by-step instructions to implement and maintain the 9 core MVP features.

---

## 1. 👤 Authentication & RBAC
- **Roles**: `OWNER` / `VENDOR`, `LMO`, `ADMIN`.
- **JWT Payload**: `{ sub: user.id, role: user.role }`.
- **Endpoints**:
  - `POST /api/auth/vendor/login` / `POST /api/auth/lmo/login` / `POST /api/auth/admin/login`
  - `POST /api/auth/vendor/register`
- **Middleware**:
  - `requireAuth`: Verifies `Authorization: Bearer <token>`.
  - `requireRole(...roles)`: Rejects with `403 Forbidden` if unauthorized.

---

## 2. ⚖️ Instrument Registration
- **Data Model**: `Instrument` linked to `vendorId`, `instrumentTypeId`, `serialNumber`, `manufacturer`, `model`, `capacity`, `accuracyClass`, `uniqueId` (`CLM-IND-2026-XXXXX`).
- **Endpoints**:
  - `POST /api/vendor/instruments`: Accepts `{ serialNumber, model, manufacturer, capacity, uniqueId }`. Auto-resolves default `instrumentTypeId` if omitted.
  - `GET /api/vendor/instruments`: Lists all instruments for authenticated vendor.

---

## 3. 📝 Verification Application
- **Data Model**: `Application` linked to `instrumentId`, `vendorId`, `assignedLmoId`, `status`, `slotDate`, `slotTime`.
- **Status Enum**: `SUBMITTED` ➔ `DOCUMENTS_VERIFIED` ➔ `SCHEDULED` ➔ `INSPECTION_IN_PROGRESS` ➔ `PASSED` / `FAILED` ➔ `CERTIFICATE_ISSUED`.
- **Endpoints**:
  - `POST /api/vendor/applications`: Creates application in `SUBMITTED` status.
  - `POST /api/vendor/applications/:id/documents`: Multipart upload via `multer` for PDFs & photos to `/uploads`.

---

## 4. 📅 LMO Assignment & Scheduling
- **Endpoints**:
  - `GET /api/admin/applications`: Lists all pending applications.
  - `POST /api/admin/applications/:id/assign`: Assigns `lmoId` and sets `slotDate`/`slotTime` (`status -> SCHEDULED`).
  - `GET /api/lmo/queue`: Returns applications assigned to the authenticated LMO.

---

## 5. 📱 Field Verification & Error Calculation
- **Model**: `Inspection` (`applicationId`, `lmoId`, `observedValue`, `standardValue`, `error`, `permissibleError`, `status: PASSED|FAILED`, `photoUrl`, `remarks`).
- **Calculation Formula**:
  $$\text{Error} = |\text{Observed Value} - \text{Standard Value}|$$
  $$\text{Result} = (\text{Error} \le \text{Permissible Error}) \ ? \ \text{"PASSED"} : \text{"FAILED"}$$
- **Endpoints**:
  - `POST /api/lmo/inspections/:id/start`: Records GPS timestamp.
  - `POST /api/lmo/inspections/:id/result`: Submits measurement results and evidence photo. Auto-triggers certificate generation on `PASSED`.

---

## 6. 📜 Digital Certificate & PDF Generation
- **Model**: `Certificate` (`certificateNumber`, `applicationId`, `instrumentId`, `lmoId`, `qrToken`, `pdfUrl`, `validFrom`, `validUntil`).
- **Generation Logic**:
  1. Generate QR Code containing public verification URL (`https://yourapp.com/verify/:qrToken`).
  2. Compile official PDF via `pdfkit` with Government Header, instrument specs, QR image, and digital seal.
  3. Save to `/uploads/certificates/VC-2026-XXXXX.pdf`.

---

## 7. 🔗 Public QR Verification
- **Endpoint**: `GET /api/verify/:qrToken` (Public, no auth token required).
- **Response**:
  ```json
  {
    "success": true,
    "certificateNumber": "VC-2026-00124",
    "status": "VALID",
    "instrument": {
      "type": "Electronic Weighing Scale",
      "serialNumber": "ET-2026-099",
      "manufacturer": "Essae Teraoka"
    },
    "verifiedDate": "2026-09-05",
    "validUntil": "2027-09-04",
    "officer": "Officer Rajesh Kumar (LMO-001)"
  }
  ```

---

## 8. ⏰ Expiry Tracking
- **Calculation**:
  $$\text{Days Left} = \left\lceil \frac{\text{Valid Until} - \text{Now}}{86400000} \right\rceil$$
  - $\text{Days} > 30 \implies \text{VALID (🟢)}$
  - $0 \le \text{Days} \le 30 \implies \text{EXPIRING\_SOON (🟡)}$
  - $\text{Days} < 0 \implies \text{EXPIRED (🔴)}$

---

## 9. 📊 Role-Based Dashboards
- `GET /api/vendor/dashboard`: `{ myInstruments, pendingApps, verifiedCount, expiringSoonCount }`
- `GET /api/lmo/dashboard`: `{ assignedCount, pendingCount, completedCount, todayInspections }`
- `GET /api/admin/dashboard`: `{ totalInstruments, pendingApplications, verifiedCertificates, expiredCertificates }`
