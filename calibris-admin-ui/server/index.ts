// server/index.ts
import "dotenv/config";
import express from "express";
import cors from "cors";
import { handleDemo } from "./routes/demo";
import authRoutes from "./routes/auth";
import deviceRoutes from "./routes/devices";

export function createServer() {
  const app = express();

  // Middleware
 app.use(cors({
  origin: true,  // reflects the request origin
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));
  app.use(express.json());
  app.use(express.urlencoded({ extended: true }));

  // Health check for Railway
  app.get("/health", (_req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  // API info endpoint
  app.get("/api", (_req, res) => {
    res.json({
      message: "Calibris API",
      version: "1.0.0",
      endpoints: {
        health: "/health",
        ping: "/api/ping",
        demo: "/api/demo",
        auth: "/api/auth/*",
        devices: "/api/devices/*",
      },
    });
  });

  // Example API routes
  app.get("/api/ping", (_req, res) => {
    const ping = process.env.PING_MESSAGE ?? "ping";
    res.json({ message: ping });
  });

  app.get("/api/demo", handleDemo);

  // Mount auth routes at /api/auth
  app.use("/api/auth", authRoutes);

  // Mount device routes at /api/devices (connected to Postgres)
  app.use("/api/devices", deviceRoutes);

  return app;
}
