import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { requireAuth, requireRole } from "../middlewares/auth";
import { upload } from "../middlewares/upload";
import {
  myQueue,
  startInspection,
  addDiscrepancy,
  uploadInspectionPhoto,
  submitResult,
} from "../controllers/inspection.controller";
import { getApplication } from "../controllers/application.controller";

const router = Router();
router.use(requireAuth, requireRole("LMO"));

router.get("/queue", asyncHandler(myQueue));
router.get("/applications/:id", asyncHandler(getApplication));
router.post("/applications/:applicationId/inspection/start", asyncHandler(startInspection));
router.post("/applications/:applicationId/inspection/discrepancies", upload.single("file"), asyncHandler(addDiscrepancy));
router.post("/applications/:applicationId/inspection/photos", upload.single("file"), asyncHandler(uploadInspectionPhoto));
router.post("/applications/:applicationId/inspection/result", asyncHandler(submitResult));

export default router;
