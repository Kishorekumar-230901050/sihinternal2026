import "dotenv/config";
import express, { ErrorRequestHandler } from "express";
import cors from "cors";
import path from "node:path";
import { LOCAL_UPLOAD_DIR, isSupabaseConfigured } from "./services/storage.service";
import { InvalidTransitionError } from "./services/status.service";

import authRoutes from "./routes/auth.routes";
import vendorRoutes from "./routes/vendor.routes";
import lmoRoutes from "./routes/lmo.routes";
import adminRoutes from "./routes/admin.routes";
import publicRoutes from "./routes/public.routes";

const app = express();

app.use(cors());
app.use(express.json({ limit: "5mb" }));

// Local-disk upload fallback is served statically only when Supabase Storage
// isn't configured (see storage.service.ts).
if (!isSupabaseConfigured) {
  app.use("/uploads", express.static(LOCAL_UPLOAD_DIR));
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, storage: isSupabaseConfigured ? "supabase" : "local-disk" });
});

app.use("/api/auth", authRoutes);
app.use("/api/vendor", vendorRoutes);
app.use("/api/lmo", lmoRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api", publicRoutes); // GET /api/verify/:qrToken (public)

app.use((_req, res) => {
  res.status(404).json({ error: "Not found" });
});

const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  console.error(err);
  if (err instanceof InvalidTransitionError) {
    return res.status(409).json({ error: err.message });
  }
  if (err?.name === "MulterError" || /Unsupported file type/.test(err?.message ?? "")) {
    return res.status(400).json({ error: err.message });
  }
  res.status(500).json({ error: "Internal server error" });
};
app.use(errorHandler);

const PORT = Number(process.env.PORT) || 3000;
app.listen(PORT, () => {
  console.log(`CALIBRIS backend listening on http://localhost:${PORT}`);
  console.log(`Storage backend: ${isSupabaseConfigured ? "Supabase Storage" : "local disk (/uploads)"}`);
});
