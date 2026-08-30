// server/production-server.ts
// Production backend server (API only - no frontend serving)
// Deployed on Railway

import express from "express";
import cors from "cors";
import deviceRoutes from "./routes/devices.js";
import authRoutes from "./routes/auth.js";
import { createServer } from "http";
import { initializeSocket } from "./socket.js";
import dotenv from "dotenv";

dotenv.config();

// Check if DATABASE_URL is set
if (!process.env.DATABASE_URL) {
  console.error('❌ ERROR: DATABASE_URL environment variable is not set!');
  console.error('Please set DATABASE_URL in your Railway environment variables.');
  console.error('Example: postgresql://user:password@host:port/database');
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3000;

// CORS configuration - allow frontend from Vercel and custom domain
app.use(cors({
  origin: true,  // reflects the request origin
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'ngrok-skip-browser-warning'],
  credentials: true
}));

app.use(express.json());

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    timestamp: new Date(),
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// API routes
app.use("/api/devices", deviceRoutes);
app.use("/api/auth", authRoutes);

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Calibris Backend API",
    version: "1.0.0",
    endpoints: {
      health: "/health",
      devices: "/api/devices",
      auth: "/api/auth",
      tamper: "/api/devices/:id/tamper",
      heartbeat: "/api/devices/:id/heartbeat"
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

// Error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("Error:", err);
  res.status(500).json({
    error: "Internal server error",
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Create HTTP server and initialize WebSocket
const server = createServer(app);
initializeSocket(server);

server.listen(PORT, () => {
  console.log(`🚀 Backend API server running on port ${PORT}`);
  console.log(`🔧 API: http://localhost:${PORT}/api`);
  console.log(`📝 Health: http://localhost:${PORT}/health`);
  console.log(`🔌 WebSocket server initialized`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`✅ CORS enabled for all origins`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
