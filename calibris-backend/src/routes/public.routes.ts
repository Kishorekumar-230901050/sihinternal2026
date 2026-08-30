import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { verifyPublic } from "../controllers/certificate.controller";

const router = Router();

router.get("/verify/:qrToken", asyncHandler(verifyPublic));

export default router;
