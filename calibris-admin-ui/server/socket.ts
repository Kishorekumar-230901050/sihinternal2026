// server/socket.ts
// WebSocket server for real-time tamper alerts

import { Server as HttpServer } from "http";
import { Server as SocketIOServer } from "socket.io";

let io: SocketIOServer | null = null;

export function initializeSocket(httpServer: HttpServer) {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: "*", // In production, specify your frontend URL
      methods: ["GET", "POST"],
    },
  });

  io.on("connection", (socket) => {
    console.log(`✅ Client connected: ${socket.id}`);

    socket.on("disconnect", () => {
      console.log(`❌ Client disconnected: ${socket.id}`);
    });
  });

  return io;
}

export function getIO(): SocketIOServer {
  if (!io) {
    throw new Error("Socket.IO not initialized. Call initializeSocket() first.");
  }
  return io;
}

// Emit single tamper alert to all connected clients (for real-time individual alerts)
export function emitTamperAlert(tamperLog: any) {
  if (io) {
    console.log(`🚨 Broadcasting tamper alert: ${tamperLog.device_id}`);
    io.emit("tamper:alert", tamperLog);
  }
}

// Emit batch tamper alert (for anna.sh bulk sync)
export function emitBatchTamperAlert(deviceId: number, tamperLogs: any[]) {
  if (io) {
    console.log(`📦 Broadcasting batch alert: ${tamperLogs.length} logs from device ${deviceId}`);

    // Count tamper types
    const typeCounts: Record<string, number> = {};
    tamperLogs.forEach(log => {
      const type = log.tamper_type || 'unknown';
      typeCounts[type] = (typeCounts[type] || 0) + 1;
    });

    // Emit batch summary event
    io.emit("tamper:batch", {
      device_id: deviceId,
      count: tamperLogs.length,
      type_counts: typeCounts,
      first_event_time: tamperLogs[0]?.event_time,
      last_event_time: tamperLogs[tamperLogs.length - 1]?.event_time,
      logs: tamperLogs, // Full logs for alert history
    });
  }
}
