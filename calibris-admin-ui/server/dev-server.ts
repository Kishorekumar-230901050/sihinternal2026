// server/dev-server.ts
// Development-only server (API only, no frontend serving)
import "dotenv/config";
import { createServer } from "http";
import { createServer as createExpressServer } from "./index";
import { initializeSocket } from "./socket";

const port = process.env.PORT || 3000;

const app = createExpressServer();
const httpServer = createServer(app);

// Initialize WebSocket server
initializeSocket(httpServer);

httpServer.listen(port, () => {
  console.log(`🚀 Backend API server running on port ${port}`);
  console.log(`🔧 API: http://localhost:${port}/api`);
  console.log(`📝 Health: http://localhost:${port}/health`);
  console.log(`🔌 WebSocket server initialized`);
});

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("🛑 Shutting down gracefully");
  process.exit(0);
});
