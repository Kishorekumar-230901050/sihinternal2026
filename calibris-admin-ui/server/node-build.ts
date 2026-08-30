// server/node-build.ts
import path from "path";
import { fileURLToPath } from "url";
import { createServer } from "./index";
import express from "express"; // <-- FIXED: don't import as * because express.static won't work properly

// Basic runtime logging to debug start failures in hosted environments
console.log("[startup] node-build entry loading...");

const port = process.env.PORT || 3000;

let app: ReturnType<typeof createServer>;
try {
  app = createServer();
  console.log("[startup] createServer() succeeded");
} catch (err) {
  console.error("[startup] createServer() failed", err);
  // Exit non-zero so platform logs the failure
  process.exit(1);
}

// In production, serve the built SPA files
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distPath = path.join(__dirname, "../dist/spa");

// -----------------------------
// Serve static frontend files
// -----------------------------
app.use(express.static(distPath));

// -----------------------------
// React Router fallback handling
// -----------------------------
app.use((req, res, next) => {
  // Let API routes pass through to your Express server
  if (req.path.startsWith("/api/") || req.path.startsWith("/health")) {
    return next();
  }

  // For any non-API routes, serve the React SPA entrypoint
  res.sendFile(path.join(distPath, "index.html"));
});

// -----------------------------
// Start server
// -----------------------------
app.listen(port, () => {
  console.log(`🚀 Calibris server running on port ${port}`);
  console.log(`📱 Frontend: http://localhost:${port}`);
  console.log(`🔧 API: http://localhost:${port}/api`);
});

// Surface unhandled errors to logs so healthcheck failures are visible
process.on("unhandledRejection", (reason) => {
  console.error("[unhandledRejection]", reason);
});

process.on("uncaughtException", (err) => {
  console.error("[uncaughtException]", err);
  process.exit(1);
});

// -----------------------------
// Graceful shutdown
// -----------------------------
process.on("SIGTERM", () => {
  console.log("🛑 Received SIGTERM, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("🛑 Received SIGINT, shutting down gracefully");
  process.exit(0);
});
