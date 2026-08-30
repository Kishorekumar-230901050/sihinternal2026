// client/components/TamperAlertListener.tsx
// Component to listen for real-time tamper alerts with auto-dismissing banner

import { useState, useEffect } from "react";
import { useTamperAlerts } from "../hooks/useTamperAlerts";
import {
  Alert,
  AlertTitle,
  Box,
  IconButton,
  Chip,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Slide
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import NotificationsIcon from "@mui/icons-material/Notifications";
import WarningIcon from "@mui/icons-material/Warning";

export function TamperAlertListener() {
  const { isConnected, latestAlert, alertHistory } = useTamperAlerts();
  const [showBanner, setShowBanner] = useState(false);
  const [currentBannerId, setCurrentBannerId] = useState<number | null>(null);

  // Auto-show banner when new alert arrives, auto-dismiss after 10 seconds
  useEffect(() => {
    if (latestAlert && latestAlert.id !== currentBannerId) {
      setShowBanner(true);
      setCurrentBannerId(latestAlert.id);

      // Auto-dismiss after 10 seconds
      const timer = setTimeout(() => {
        setShowBanner(false);
      }, 10000);

      return () => clearTimeout(timer);
    }
  }, [latestAlert, currentBannerId]);

  const formatTimeAgo = (timestamp: string) => {
    const now = new Date();
    const eventTime = new Date(timestamp);
    const diffMs = now.getTime() - eventTime.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffMins < 1440) return `${Math.floor(diffMins / 60)}h ago`;
    return `${Math.floor(diffMins / 1440)}d ago`;
  };

  return (
    <Box sx={{ width: '100%' }}>
      {/* Connection Status Badge - Top Right */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6" sx={{ fontWeight: 700 }}>
          <NotificationsIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          Real-time Alert System
        </Typography>
        <Chip
          icon={isConnected ? <span style={{ fontSize: '12px' }}>🟢</span> : <span style={{ fontSize: '12px' }}>🔴</span>}
          label={isConnected ? "WebSocket Connected" : "Disconnected"}
          color={isConnected ? "success" : "error"}
          size="small"
        />
      </Box>

      {/* CRITICAL ALERT BANNER - Auto-dismiss after 10 seconds */}
      <Slide direction="down" in={showBanner && latestAlert !== null} mountOnEnter unmountOnExit>
        <Alert
          severity="error"
          sx={{
            mb: 3,
            border: '2px solid #ef4444',
            '& .MuiAlert-message': { width: '100%' }
          }}
          action={
            <IconButton
              aria-label="close"
              color="inherit"
              size="small"
              onClick={() => setShowBanner(false)}
            >
              <CloseIcon fontSize="inherit" />
            </IconButton>
          }
        >
          <AlertTitle sx={{ fontSize: '1.1rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1 }}>
            <WarningIcon /> CRITICAL ALERT - Just Now
          </AlertTitle>
          {latestAlert && (
            <Box sx={{ mt: 1 }}>
              <Typography variant="h6" sx={{ mb: 1 }}>
                Device {latestAlert.device_id} - {latestAlert.tamper_type}
              </Typography>
              <Box sx={{ display: 'flex', gap: 3, flexWrap: 'wrap', fontSize: '0.9rem' }}>
                <Typography variant="body2">
                  <strong>Location:</strong> {latestAlert.city}, {latestAlert.state}
                  {latestAlert.latitude && latestAlert.longitude && (
                    <> ({Number(latestAlert.latitude).toFixed(4)}°N, {Number(latestAlert.longitude).toFixed(4)}°E)</>
                  )}
                </Typography>
                {latestAlert.prev_hash && latestAlert.curr_hash && (
                  <Typography variant="body2">
                    <strong>Hash:</strong> {latestAlert.prev_hash.substring(0, 8)}... → {latestAlert.curr_hash.substring(0, 8)}...
                  </Typography>
                )}
                {latestAlert.drift !== null && latestAlert.drift !== undefined && (
                  <Typography variant="body2">
                    <strong>Drift:</strong> {latestAlert.drift}°C
                  </Typography>
                )}
              </Box>
              {latestAlert.details && (
                <Typography variant="body2" sx={{ mt: 1, fontStyle: 'italic' }}>
                  {latestAlert.details}
                </Typography>
              )}
            </Box>
          )}
        </Alert>
      </Slide>

      {/* RECENT TAMPER EVENTS TABLE - Always Visible */}
      {alertHistory.length > 0 && (
        <Paper sx={{ p: 2, border: '1px solid #e5e7eb' }}>
          <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
            Recent Tamper Events (Last {Math.min(alertHistory.length, 10)})
          </Typography>
          <TableContainer sx={{ maxHeight: 400 }}>
            <Table size="small" stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 700 }}>Device</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Type</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Location</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Time</TableCell>
                  <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {alertHistory.slice(0, 10).map((alert, index) => (
                  <TableRow
                    key={`${alert.id}-${index}`}
                    hover
                    sx={{
                      '&:nth-of-type(odd)': { backgroundColor: 'rgba(0, 0, 0, 0.02)' },
                      cursor: 'pointer'
                    }}
                  >
                    <TableCell>
                      <strong>Device {alert.device_id}</strong>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={alert.tamper_type}
                        size="small"
                        color="error"
                        variant="outlined"
                      />
                    </TableCell>
                    <TableCell>{alert.city}, {alert.state}</TableCell>
                    <TableCell>{formatTimeAgo(alert.event_time)}</TableCell>
                    <TableCell>
                      <Chip
                        label={alert.resolution_status || "ACTIVE"}
                        size="small"
                        color={alert.resolution_status ? "success" : "warning"}
                      />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      )}
    </Box>
  );
}
