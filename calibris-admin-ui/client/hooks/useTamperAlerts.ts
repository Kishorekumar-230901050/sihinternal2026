// client/hooks/useTamperAlerts.ts
// Custom hook to listen for real-time tamper alerts via WebSocket

import { useEffect, useState } from "react";
import { io, Socket } from "socket.io-client";
import { toast } from "sonner";
import { WS_URL } from "@/config/api";

interface TamperLog {
  id: number;
  device_id: string;
  tamper_type: string;
  details: string;
  event_time: string;
  resolution_status: string;
  settling_time: number;
  renewal_cycle: number;
  latitude: number;
  longitude: number;
  city: string;
  state: string;
  drift: number;
  prev_hash: string;
  curr_hash: string;
  luckfox_log_id: string;
  pushed_at: string;
}

export function useTamperAlerts() {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [latestAlert, setLatestAlert] = useState<TamperLog | null>(null);
  const [alertHistory, setAlertHistory] = useState<TamperLog[]>([]);

  useEffect(() => {
    // Connect to WebSocket server
    const socketInstance = io(WS_URL, {
      transports: ["websocket", "polling"],
    });

    socketInstance.on("connect", () => {
      console.log("✅ Connected to WebSocket server");
    });

    socketInstance.on("disconnect", () => {
      console.log("❌ Disconnected from WebSocket server");
    });

    // Listen for INDIVIDUAL tamper alerts (real-time from C library)
    socketInstance.on("tamper:alert", (tamperLog: TamperLog) => {
      console.log("🚨 Tamper alert received:", tamperLog);

      setLatestAlert(tamperLog);
      setAlertHistory((prev) => [tamperLog, ...prev].slice(0, 50)); // Keep last 50 alerts

      // Show toast notification for individual alert
      toast.error(`Tamper Detected!`, {
        description: `Device ${tamperLog.device_id} - ${tamperLog.tamper_type} at ${tamperLog.city}, ${tamperLog.state}`,
        duration: 10000,
      });
    });

    // Listen for BATCH tamper alerts (from anna.sh sync)
    socketInstance.on("tamper:batch", (batch: any) => {
      console.log("📦 Batch alert received:", batch);

      // Add all logs to history
      setAlertHistory((prev) => [...batch.logs, ...prev].slice(0, 50));

      // Set the most recent one as latest
      if (batch.logs.length > 0) {
        setLatestAlert(batch.logs[0]);
      }

      // Show ONE toast for the batch
      const typeList = Object.entries(batch.type_counts)
        .map(([type, count]) => `${count}× ${type}`)
        .join(", ");

      toast.warning(`${batch.count} Tamper Events Synced`, {
        description: `Device ${batch.device_id}: ${typeList}`,
        duration: 8000,
      });
    });

    setSocket(socketInstance);

    // Cleanup on unmount
    return () => {
      socketInstance.disconnect();
    };
  }, []);

  return {
    socket,
    latestAlert,
    alertHistory,
    isConnected: socket?.connected || false,
  };
}
