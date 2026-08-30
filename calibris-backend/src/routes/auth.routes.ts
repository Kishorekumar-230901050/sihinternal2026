import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { registerVendor, loginVendor, loginLmo, loginAdmin } from "../controllers/auth.controller";

const router = Router();

router.post("/vendor/register", asyncHandler(registerVendor));
router.post("/vendor/login", asyncHandler(loginVendor));
router.post("/lmo/login", asyncHandler(loginLmo));
router.post("/admin/login", asyncHandler(loginAdmin));

export default router;
