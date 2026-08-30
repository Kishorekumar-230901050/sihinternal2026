import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { requireAuth, requireRole } from "../middlewares/auth";
import { upload } from "../middlewares/upload";
import { listInstrumentTypes, registerInstrument, listMyInstruments, vendorDashboard } from "../controllers/instrument.controller";
import { createApplication, uploadDocument, getApplication, listMyApplications, cancelApplication } from "../controllers/application.controller";
import { findGatcs, getGatc } from "../controllers/gatc.controller";
import { bookAppointment, gatcAvailability } from "../controllers/appointment.controller";
import { createOrder, simulateCheckout, verifyPayment, getReceipt } from "../controllers/payment.controller";
import { getMyCertificate } from "../controllers/certificate.controller";

const router = Router();
router.use(requireAuth, requireRole("VENDOR"));

router.get("/dashboard", asyncHandler(vendorDashboard));

// Instruments
router.get("/instrument-types", asyncHandler(listInstrumentTypes));
router.post("/instruments", asyncHandler(registerInstrument));
router.get("/instruments", asyncHandler(listMyInstruments));

// Applications
router.post("/applications", asyncHandler(createApplication));
router.get("/applications", asyncHandler(listMyApplications));
router.get("/applications/:id", asyncHandler(getApplication));
router.post("/applications/:id/cancel", asyncHandler(cancelApplication));
router.post("/applications/:applicationId/documents", upload.single("file"), asyncHandler(uploadDocument));

// GATC search
router.get("/gatcs", asyncHandler(findGatcs));
router.get("/gatcs/:id", asyncHandler(getGatc));
router.get("/gatcs/availability/slots", asyncHandler(gatcAvailability));

// Appointments
router.post("/appointments", asyncHandler(bookAppointment));

// Payments
router.post("/payments/orders", asyncHandler(createOrder));
router.post("/payments/simulate-checkout", asyncHandler(simulateCheckout));
router.post("/payments/verify", asyncHandler(verifyPayment));
router.get("/payments/:orderRef/receipt", asyncHandler(getReceipt));

// Certificate
router.get("/applications/:applicationId/certificate", asyncHandler(getMyCertificate));

export default router;
