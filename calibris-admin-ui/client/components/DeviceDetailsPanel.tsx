import { Box, Card, CardContent, Chip, Divider, Stack, Typography, Button, CircularProgress, Alert, Dialog, DialogTitle, DialogContent, DialogActions, DialogContentText, Table, TableBody, TableCell, TableHead, TableRow, IconButton, Tooltip as MuiTooltip } from "@mui/material";
import React, { useState, useEffect, useRef } from "react";
import { useStore } from "@/context/StoreContext";
import { Device } from "@/context/types";
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { API_BASE_URL } from "@/config/api";
import { getRelativeTime, formatTimestamp } from "@/utils/dateUtils";
import { soundAlert } from "@/utils/soundAlerts";
import VolumeUpIcon from '@mui/icons-material/VolumeUp';
import VolumeOffIcon from '@mui/icons-material/VolumeOff';

function statusColor(status: string) {
  switch (status) {
    case "OK":
    case "Online":
      return "success";
    case "Drifted":
      return "warning";
    case "Offline":
      return "default";
    case "Tampered":
    case "safe_mode":
      return "error";
    default:
      return "default";
  }
}


interface TamperStats {
  total_tampers: number;
  by_type: Array<{ tamper_type: string; count: string }>;
}

interface UnlockCommand {
  id: number;
  officer_id: string;
  reason: string;
  status: string;
  created_at: string;
  executed_at?: string;
}

interface TamperEvent {
  id: number;
  tamper_type: string;
  severity: string;
  event_time: string;
  resolution_status: string;
  details?: string;
}

// Polling-based status from backend
interface PollStatus {
  device_id: string;
  status: "safe_mode" | "online";
  is_tampered: boolean;
  can_unlock: boolean;
  last_poll_seconds_ago: number | null;
}

export default function DeviceDetailsPanel() {
  const { devices, selectedDeviceId, user } = useStore();
  const [unlocking, setUnlocking] = useState(false);
  const [unlockError, setUnlockError] = useState<string | null>(null);
  const [unlockSuccess, setUnlockSuccess] = useState(false);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);
  const [tamperStats, setTamperStats] = useState<TamperStats | null>(null);
  const [unlockHistory, setUnlockHistory] = useState<UnlockCommand[]>([]);
  const [recentEvents, setRecentEvents] = useState<TamperEvent[]>([]);
  const [loadingStats, setLoadingStats] = useState(false);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const previousStatusRef = useRef<string | null>(null);
  // Polling-based status from backend
  const [pollStatus, setPollStatus] = useState<PollStatus | null>(null);

  // normalize selected id so we can compare numeric ids and numeric strings safely
  const selId =
    typeof selectedDeviceId === "string" && /^\d+$/.test(selectedDeviceId)
      ? Number(selectedDeviceId)
      : selectedDeviceId;

  const device = devices.find((d) => d.id === selId) as Device | undefined;

  // Monitor device status for tamper alerts
  useEffect(() => {
    if (!device) {
      previousStatusRef.current = null;
      return;
    }

    const currentStatus = device.status;
    const previousStatus = previousStatusRef.current;

    // Play sound alert if device just became tampered/safe_mode
    if (soundEnabled && previousStatus && previousStatus !== currentStatus) {
      if (currentStatus === "Tampered" || currentStatus === "safe_mode") {
        soundAlert.playTamperAlert();
      }
    }

    previousStatusRef.current = currentStatus;
  }, [device?.status, soundEnabled]);

  // Toggle sound alerts
  useEffect(() => {
    if (soundEnabled) {
      soundAlert.enable();
    } else {
      soundAlert.disable();
    }
  }, [soundEnabled]);

  // Poll device status from backend every 10 seconds (poll tracker based)
  useEffect(() => {
    if (!device) {
      setPollStatus(null);
      return;
    }

    const fetchPollStatus = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/devices/${device.id}/status`);
        if (response.ok) {
          const data = await response.json();
          setPollStatus(data);

          // Play sound if device just entered safe mode
          if (soundEnabled && data.status === "safe_mode" && pollStatus?.status !== "safe_mode") {
            soundAlert.playTamperAlert();
          }
        }
      } catch (err) {
        console.error("Error fetching poll status:", err);
      }
    };

    // Fetch immediately
    fetchPollStatus();

    // Poll every 5 seconds
    const interval = setInterval(fetchPollStatus, 5000);
    return () => clearInterval(interval);
  }, [device?.id, soundEnabled]);

  // Fetch tamper stats, unlock history, and recent events when device changes
  useEffect(() => {
    if (!device) {
      setTamperStats(null);
      setUnlockHistory([]);
      setRecentEvents([]);
      return;
    }

    const fetchDeviceData = async () => {
      setLoadingStats(true);
      try {
        // Fetch tamper statistics
        const statsResponse = await fetch(`${API_BASE_URL}/devices/${device.id}/tamper-stats`);
        if (statsResponse.ok) {
          const statsData = await statsResponse.json();
          setTamperStats(statsData);
        }

        // Fetch unlock history
        const historyResponse = await fetch(`${API_BASE_URL}/devices/${device.id}/unlock-history`);
        if (historyResponse.ok) {
          const historyData = await historyResponse.json();
          setUnlockHistory(historyData.unlock_commands || []);
        }

        // Fetch recent tamper events
        const eventsResponse = await fetch(`${API_BASE_URL}/devices/${device.id}/recent-events?limit=5`);
        if (eventsResponse.ok) {
          const eventsData = await eventsResponse.json();
          setRecentEvents(eventsData.events || []);
        }
      } catch (err) {
        console.error("Error fetching device data:", err);
      } finally {
        setLoadingStats(false);
      }
    };

    fetchDeviceData();
  }, [device?.id]);

  // Handle unlock device
  const handleUnlockDevice = async () => {
    if (!device) return;

    setShowConfirmDialog(false);
    setUnlocking(true);
    setUnlockError(null);
    setUnlockSuccess(false);

    try {
      const response = await fetch(`${API_BASE_URL}/devices/${device.id}/unlock`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          officer_id: user?.id || "unknown",  // Firebase UID for lookup
          officer_email: user?.email || "unknown",  // Email as backup
          reason: "Remote unlock via dashboard",
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || "Failed to unlock device");
      }

      const data = await response.json();

      // Check if unlock was already pending
      if (data.already_pending) {
        setUnlockError("Unlock command already pending. Device will unlock within 60 seconds.");
      } else {
        setUnlockSuccess(true);
        setTimeout(() => setUnlockSuccess(false), 10000);

        // Poll status rapidly after unlock to detect when device confirms
        const rapidPoll = setInterval(async () => {
          try {
            const statusRes = await fetch(`${API_BASE_URL}/devices/${device.id}/status`);
            if (statusRes.ok) {
              const statusData = await statusRes.json();
              setPollStatus(statusData);
              // Stop rapid polling once device is online
              if (statusData.status === "online") {
                clearInterval(rapidPoll);
              }
            }
          } catch (e) {
            // ignore errors during rapid poll
          }
        }, 1000); // Poll every 1 second after unlock

        // Stop rapid polling after 30 seconds max
        setTimeout(() => clearInterval(rapidPoll), 30000);
      }
    } catch (err: any) {
      setUnlockError(err.message || "Failed to unlock device");
    } finally {
      setUnlocking(false);
    }
  };

  if (!device)
    return (
      <Card elevation={0} sx={{ background: "#ffffff", border: "1px solid #d1d5db", height: "100%" }}>
        <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
          <Typography variant="h6" sx={{ fontSize: { xs: "1rem", sm: "1.25rem" } }}>Device Details</Typography>
          <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.8rem", sm: "0.875rem" } }}>
            Select a device to view details.
          </Typography>
        </CardContent>
      </Card>
    );

  // Prepare chart data from real tamper statistics
  const chartData = tamperStats?.by_type
    .filter(item => item.tamper_type) // Filter out null/undefined tamper types
    .map(item => ({
      name: item.tamper_type.charAt(0).toUpperCase() + item.tamper_type.slice(1),
      value: parseInt(item.count)
    })) || [];

  return (
    <Card elevation={0} sx={{ background: "#ffffff", border: "1px solid #d1d5db", height: "100%" }}>
      <CardContent sx={{ p: { xs: 2, sm: 3 } }}>
        <Stack spacing={{ xs: 1.5, sm: 2 }}>
          {/* Header */}
          <Stack direction="row" justifyContent="space-between" alignItems="center" flexWrap="wrap" gap={1}>
            <Typography variant="h6" sx={{ fontSize: { xs: "1rem", sm: "1.25rem" } }}>Device Details</Typography>
            <Stack direction="row" spacing={1} alignItems="center">
              <MuiTooltip title={soundEnabled ? "Mute alerts" : "Enable sound alerts"}>
                <IconButton size="small" onClick={() => setSoundEnabled(!soundEnabled)}>
                  {soundEnabled ? <VolumeUpIcon fontSize="small" /> : <VolumeOffIcon fontSize="small" />}
                </IconButton>
              </MuiTooltip>
              {/* Show polling-based status if available, otherwise database status */}
              {pollStatus?.status === "safe_mode" ? (
                <MuiTooltip title={`Device is polling (${pollStatus.last_poll_seconds_ago}s ago) - Safe Mode Active`}>
                  <Chip label="SAFE MODE" color="error" size="small" sx={{ fontWeight: 700 }} />
                </MuiTooltip>
              ) : (
                <Chip label={device.status || "Online"} color={statusColor(device.status as string)} size="small" />
              )}
            </Stack>
          </Stack>

          <Divider />

          {/* Device ID */}
          <Box>
            <Typography variant="body2" sx={{ color: "#6b7280" }}>
              Device ID
            </Typography>
            <Typography fontWeight={700}>{device.id}</Typography>
          </Box>

          {/* Row 1: Device Type + Owner */}
          <Box display="grid" gridTemplateColumns={{ xs: "1fr", sm: "1fr 1fr" }} gap={{ xs: 1.5, sm: 2 }}>
            <Box>
              <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>
                Device Type
              </Typography>
              <Typography sx={{ fontSize: { xs: "0.85rem", sm: "1rem" } }}>{device.deviceType ?? "—"}</Typography>
            </Box>

            <Box>
              <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Owner</Typography>
              <Typography sx={{ fontSize: { xs: "0.85rem", sm: "1rem" } }}>{device.owner ?? "—"}</Typography>
            </Box>
          </Box>

          {/* Row 2: Location + Last Update */}
          <Box display="grid" gridTemplateColumns={{ xs: "1fr", sm: "1fr 1fr" }} gap={{ xs: 1.5, sm: 2 }}>
            <Box>
              <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Location</Typography>
              <Typography sx={{ fontSize: { xs: "0.85rem", sm: "1rem" } }}>{device.location ?? "—"}</Typography>
            </Box>

            <Box>
              <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Last Seen</Typography>
              <MuiTooltip title={formatTimestamp(device.lastUpdate ?? null)}>
                <Typography sx={{ cursor: "help", fontSize: { xs: "0.85rem", sm: "1rem" } }}>{getRelativeTime(device.lastUpdate ?? null)}</Typography>
              </MuiTooltip>
            </Box>
          </Box>

          {/* Tamper Fields (show when device is in safe mode based on polling or has tampered status) */}
          {(pollStatus?.status === "safe_mode" || device.status === "safe_mode" || device.status === "Tampered") && (
            <>
              <Divider />

              <Box display="grid" gridTemplateColumns={{ xs: "1fr", sm: "1fr 1fr" }} gap={{ xs: 1.5, sm: 2 }}>
                <Box>
                  <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Tamper Type</Typography>
                  <Typography sx={{ fontSize: { xs: "0.85rem", sm: "1rem" } }}>{device.tamperType ?? "—"}</Typography>
                </Box>

                <Box>
                  <Typography variant="body2" sx={{ color: "#6b7280", fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>Tamper Time</Typography>
                  <Typography sx={{ fontSize: { xs: "0.85rem", sm: "1rem" } }}>{formatTimestamp(device.tamperTime ?? null)}</Typography>
                </Box>
              </Box>

              <Box>
                <Typography variant="body2" sx={{ color: "#6b7280" }}>Details</Typography>
                <Typography>{device.tamperDetails ?? "No additional details available."}</Typography>
              </Box>
            </>
          )}

          <Divider />

          {/* Analytics - Tamper Events History (ALWAYS SHOW IF DATA EXISTS) */}
          <Box>
            <Typography variant="subtitle1" sx={{ mb: 2, fontWeight: 600 }}>
              Tamper Events Analytics
            </Typography>

            {loadingStats ? (
              <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
                <CircularProgress size={32} />
              </Box>
            ) : (tamperStats && tamperStats.total_tampers > 0) ? (
              <Box>
                {/* Total Count Card */}
                <Box sx={{
                  p: 2,
                  mb: 2,
                  background: 'linear-gradient(135deg, rgba(96,165,250,.15) 0%, rgba(59,130,246,.1) 100%)',
                  border: '1px solid rgba(96,165,250,.3)',
                  borderRadius: 2,
                  textAlign: 'center'
                }}>
                  <Typography variant="h3" sx={{ fontWeight: 700, color: '#2563eb', mb: 0.5 }}>
                    {tamperStats?.total_tampers || 0}
                  </Typography>
                  <Typography variant="body2" sx={{ color: "#6b7280" }}>
                    Total Tamper Events
                  </Typography>
                </Box>

                {/* Chart */}
                <Box sx={{ width: "100%", height: 220, mb: 2 }}>
                  <ResponsiveContainer>
                    <BarChart data={chartData}>
                      <XAxis
                        dataKey="name"
                        stroke="#6b7280"
                        tick={{ fill: '#6b7280', fontSize: 12 }}
                      />
                      <YAxis
                        stroke="#6b7280"
                        tick={{ fill: '#6b7280', fontSize: 12 }}
                      />
                      <Tooltip
                        labelStyle={{ color: "#111827", fontWeight: 600 }}
                        contentStyle={{
                          background: "#ffffff",
                          border: "1px solid #d1d5db",
                          borderRadius: 8,
                          padding: 12
                        }}
                        cursor={{ fill: 'rgba(37,99,235,.1)' }}
                      />
                      <Bar
                        dataKey="value"
                        fill="#2563eb"
                        radius={[8, 8, 0, 0]}
                      />
                    </BarChart>
                  </ResponsiveContainer>
                </Box>

                {/* Breakdown Cards */}
                <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(2, 1fr)', sm: 'repeat(2, 1fr)' }, gap: { xs: 1, sm: 1.5 } }}>
                  {chartData.map((item, idx) => {
                    const percentage = ((item.value / (tamperStats?.total_tampers || 1)) * 100).toFixed(1);
                    const colors = [
                      { bg: 'rgba(239,68,68,.1)', border: 'rgba(239,68,68,.3)', text: '#ef4444' }, // red
                      { bg: 'rgba(249,115,22,.1)', border: 'rgba(249,115,22,.3)', text: '#f97316' }, // orange
                      { bg: 'rgba(234,179,8,.1)', border: 'rgba(234,179,8,.3)', text: '#eab308' }, // yellow
                      { bg: 'rgba(34,197,94,.1)', border: 'rgba(34,197,94,.3)', text: '#22c55e' }, // green
                      { bg: 'rgba(168,85,247,.1)', border: 'rgba(168,85,247,.3)', text: '#a855f7' }, // purple
                      { bg: 'rgba(236,72,153,.1)', border: 'rgba(236,72,153,.3)', text: '#ec4899' }, // pink
                    ];
                    const color = colors[idx % colors.length];

                    return (
                      <Box
                        key={item.name}
                        sx={{
                          p: 1.5,
                          background: color.bg,
                          border: `1px solid ${color.border}`,
                          borderRadius: 1.5
                        }}
                      >
                        <Typography variant="caption" sx={{ color: "#6b7280", display: 'block', mb: 0.5 }}>
                          {item.name}
                        </Typography>
                        <Typography variant="h6" sx={{ fontWeight: 700, color: color.text }}>
                          {item.value} <Typography component="span" variant="caption" sx={{ color: "#64748b" }}>({percentage}%)</Typography>
                        </Typography>
                      </Box>
                    );
                  })}
                </Box>
              </Box>
            ) : (
              <Box sx={{
                py: 6,
                px: 3,
                textAlign: 'center',
                border: '1px dashed #d1d5db',
                borderRadius: 2,
                background: 'rgba(148,163,184,.05)'
              }}>
                <Typography variant="body2" sx={{ color: "#6b7280", mb: 0.5 }}>
                  No tamper events recorded
                </Typography>
                <Typography variant="caption" sx={{ color: "#64748b" }}>
                  Device status: {device.status}
                </Typography>
              </Box>
            )}
          </Box>

          <Divider />

          {/* Unlock Command History */}
          {unlockHistory.length > 0 && (
            <>
              <Typography variant="subtitle1">Unlock History</Typography>
              <Box sx={{ maxHeight: 200, overflowY: 'auto' }}>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ color: "#6b7280", borderColor: "#d1d5db" }}>Officer</TableCell>
                      <TableCell sx={{ color: "#6b7280", borderColor: "#d1d5db" }}>Status</TableCell>
                      <TableCell sx={{ color: "#6b7280", borderColor: "#d1d5db" }}>Date</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {unlockHistory.slice(0, 5).map((cmd) => (
                      <TableRow key={cmd.id}>
                        <TableCell sx={{ borderColor: "#d1d5db", fontSize: "0.875rem" }}>
                          {cmd.officer_id}
                        </TableCell>
                        <TableCell sx={{ borderColor: "#d1d5db" }}>
                          <Chip
                            label={cmd.status}
                            size="small"
                            color={cmd.status === 'executed' ? 'success' : cmd.status === 'pending' ? 'warning' : 'default'}
                          />
                        </TableCell>
                        <TableCell sx={{ borderColor: "#d1d5db", fontSize: "0.875rem" }}>
                          {formatTimestamp(cmd.executed_at || cmd.created_at)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </Box>
              <Divider />
            </>
          )}

          {/* Recent Tamper Events */}
          {recentEvents.length > 0 && (
            <>
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>Recent Tamper Events</Typography>
              <Box sx={{ maxHeight: 280, overflowY: 'auto' }}>
                {recentEvents.map((event, idx) => {
                  const colors = [
                    { bg: 'rgba(239,68,68,.08)', border: 'rgba(239,68,68,.25)', text: '#ef4444' },
                    { bg: 'rgba(249,115,22,.08)', border: 'rgba(249,115,22,.25)', text: '#f97316' },
                    { bg: 'rgba(234,179,8,.08)', border: 'rgba(234,179,8,.25)', text: '#eab308' },
                  ];
                  const color = colors[idx % colors.length];

                  return (
                    <Box
                      key={event.id}
                      sx={{
                        p: 2,
                        mb: 1.5,
                        background: color.bg,
                        border: `1px solid ${color.border}`,
                        borderRadius: 1.5
                      }}
                    >
                      <Stack direction="row" justifyContent="space-between" alignItems="flex-start" mb={0.5}>
                        <Typography variant="body2" sx={{ fontWeight: 600, color: color.text }}>
                          {event.tamper_type ? (event.tamper_type.charAt(0).toUpperCase() + event.tamper_type.slice(1)) : 'Unknown'}
                        </Typography>
                        <Chip
                          label={event.resolution_status || 'detected'}
                          size="small"
                          sx={{
                            height: 20,
                            fontSize: '0.7rem',
                            backgroundColor: event.resolution_status === 'resolved' ? 'rgba(34,197,94,.2)' : 'rgba(148,163,184,.2)',
                            color: event.resolution_status === 'resolved' ? '#22c55e' : '#6b7280'
                          }}
                        />
                      </Stack>
                      <Typography variant="caption" sx={{ color: "#6b7280", display: 'block', mb: 0.5 }}>
                        {new Date(event.event_time).toLocaleString()}
                      </Typography>
                      {event.severity && (
                        <Typography variant="caption" sx={{ color: "#64748b", display: 'block' }}>
                          Severity: {event.severity}
                        </Typography>
                      )}
                    </Box>
                  );
                })}
              </Box>
              <Divider />
            </>
          )}

          {/* Unlock Status Messages */}
          {unlockSuccess && (
            <Alert severity="success">
              Unlock command sent successfully! Device will unlock within 60 seconds.
            </Alert>
          )}
          {unlockError && (
            <Alert severity="error" onClose={() => setUnlockError(null)}>
              {unlockError}
            </Alert>
          )}

          {/* Actions */}
          <Stack spacing={1}>
            {/* Show unlock button based on polling status (can_unlock) */}
            {pollStatus?.can_unlock ? (
              <Button
                variant="contained"
                color="warning"
                onClick={() => setShowConfirmDialog(true)}
                disabled={unlocking}
                startIcon={unlocking ? <CircularProgress size={20} /> : null}
              >
                {unlocking ? "Unlocking..." : "Unlock Device"}
              </Button>
            ) : (
              <Button
                variant="outlined"
                color="inherit"
                disabled
                sx={{ color: "#64748b", borderColor: "#d1d5db" }}
              >
                Device Online - No Unlock Needed
              </Button>
            )}
            <Button variant="outlined" color="error">Revoke Device</Button>
          </Stack>
        </Stack>
      </CardContent>

      {/* Confirmation Dialog */}
      <Dialog
        open={showConfirmDialog}
        onClose={() => setShowConfirmDialog(false)}
      >
        <DialogTitle>Unlock Device?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to unlock Device #{device?.id}? This will remotely exit safe mode and restore normal operation.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowConfirmDialog(false)}>Cancel</Button>
          <Button onClick={handleUnlockDevice} variant="contained" color="warning" autoFocus>
            Unlock
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
}
