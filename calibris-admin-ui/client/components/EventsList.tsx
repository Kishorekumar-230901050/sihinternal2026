import { List, ListItemButton, ListItemText, ListItemIcon, Chip, CircularProgress, Box, Typography } from "@mui/material";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import ChangeCircleIcon from "@mui/icons-material/ChangeCircle";
import React, { useState, useEffect } from "react";
import { useStore } from "@/context/StoreContext";
import { useNavigate } from "react-router-dom";
import { API_BASE_URL } from "@/config/api";
import { useTamperAlerts } from "@/hooks/useTamperAlerts";

interface TamperActivity {
  id: number;
  device_id: string;
  tamper_type: string;
  severity: string;
  event_time: string;
  details?: string;
  latitude?: number;
  longitude?: number;
  device_type?: string;
  device_location?: string;
}

export default function EventsList({ limit }: { limit?: number }) {
  const { setSelectedDeviceId } = useStore();
  const navigate = useNavigate();
  const [activities, setActivities] = useState<TamperActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const { latestAlert } = useTamperAlerts();

  useEffect(() => {
    const fetchActivities = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/devices/recent-activities?limit=${limit || 20}`);
        if (response.ok) {
          const data = await response.json();
          setActivities(data.activities || []);
        }
      } catch (err) {
        console.error("Error fetching recent activities:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchActivities();

    // Refresh every 30 seconds (WebSocket handles real-time updates)
    const interval = setInterval(fetchActivities, 30000);
    return () => clearInterval(interval);
  }, [limit]);

  // Real-time update when new tamper alert arrives via WebSocket
  useEffect(() => {
    if (latestAlert) {
      // Add new alert to the top of the list if it's not already there
      setActivities((prev) => {
        const exists = prev.some(a => a.id === latestAlert.id);
        if (!exists) {
          return [latestAlert as any, ...prev].slice(0, limit || 20);
        }
        return prev;
      });
    }
  }, [latestAlert, limit]);

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
        <CircularProgress size={24} />
      </Box>
    );
  }

  if (activities.length === 0) {
    return (
      <Box sx={{ py: 4, textAlign: 'center' }}>
        <Typography variant="body2" sx={{ color: "#6b7280" }}>
          No recent tamper events
        </Typography>
      </Box>
    );
  }

  return (
    <List dense sx={{ p: 0 }}>
      {activities.map((activity) => (
        <ListItemButton
          key={activity.id}
          onClick={() => {
            setSelectedDeviceId(activity.device_id);
            navigate(`/devices?serial=${encodeURIComponent(activity.device_id)}`);
          }}
          sx={{ borderBottom: "1px solid rgba(148,163,184,.1)" }}
        >
          <ListItemIcon sx={{ minWidth: 32 }}>
            {activity.severity === "high" || activity.severity === "critical" ?
              <ErrorOutlineIcon color="error" /> :
              <ChangeCircleIcon color="warning" />
            }
          </ListItemIcon>
          <ListItemText
            primary={`${activity.tamper_type.charAt(0).toUpperCase() + activity.tamper_type.slice(1)} Detected`}
            secondary={`Device ID: ${activity.device_id}${activity.device_location ? ` • ${activity.device_location}` : ''}`}
          />
          <Chip
            label={new Date(activity.event_time).toLocaleTimeString()}
            size="small"
            variant="outlined"
          />
        </ListItemButton>
      ))}
    </List>
  );
}
