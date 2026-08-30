import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { requireAuth, requireRole } from "../middlewares/auth";
import {
  dashboard,
  createLmo,
  listLmos,
  createGatc,
  listQueue,
  assignLmo,
  approveCertificate,
  rejectApplication,
  listAuditLogs,
} from "../controllers/admin.controller";
import { getApplication } from "../controllers/application.controller";

const router = Router();
router.use(requireAuth, requireRole("ADMIN"));

router.get("/dashboard", asyncHandler(dashboard));

router.post("/lmos", asyncHandler(createLmo));
router.get("/lmos", asyncHandler(listLmos));

router.post("/gatcs", asyncHandler(createGatc));

router.get("/queue", asyncHandler(listQueue));
router.get("/applications/:id", asyncHandler(getApplication));
router.post("/applications/:applicationId/assign-lmo", asyncHandler(assignLmo));
router.post("/applications/:applicationId/approve-certificate", asyncHandler(approveCertificate));
router.post("/applications/:applicationId/reject", asyncHandler(rejectApplication));

router.get("/audit-logs", asyncHandler(listAuditLogs));

export default router;
