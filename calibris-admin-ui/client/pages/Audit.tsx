import React, { useState, useEffect } from "react";
import {
  Box,
  Paper,
  Typography,
  List,
  ListItemButton,
  ListItemText,
  ListItemIcon,
  Chip,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Divider,
  Button,
  Card,
  CardContent,
  Stack,
  Alert,
  Tabs,
  Tab,
} from "@mui/material";
import DevicesIcon from "@mui/icons-material/Devices";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import LockOpenIcon from "@mui/icons-material/LockOpen";
import DownloadIcon from "@mui/icons-material/Download";
import GavelIcon from "@mui/icons-material/Gavel";
import { useStore } from "@/context/StoreContext";
import { API_BASE_URL } from "@/config/api";
import Footer from "@/components/Footer";

interface Device {
  device_id: number;
  device_type: string;
  owner: string;
  status: string;
  location: string;
  created_at: string;
  last_seen: string;
}

interface TamperEvent {
  id: number;
  tamper_type: string;
  severity: string;
  event_time: string;
  resolution_status: string;
  details: string;
  latitude: string;
  longitude: string;
  city: string;
  state: string;
  drift: string;
  settling_time: string;
  prev_hash: string;
  curr_hash: string;
  luckfox_log_id: string;
  pushed_at: string;
}

interface UnlockCommand {
  id: number;
  officer_id: string;
  reason: string;
  status: string;
  created_at: string;
  executed_at: string;
}

interface AuditData {
  device: Device;
  tamper_events: TamperEvent[];
  unlock_commands: UnlockCommand[];
  statistics: {
    total_tamper_events: number;
    total_unlocks: number;
    pending_unlocks: number;
    tamper_types: Record<string, number>;
    severity_breakdown: Record<string, number>;
    first_tamper: string | null;
    last_tamper: string | null;
  };
}

export default function AuditPage() {
  const { devices } = useStore();
  const [selectedDeviceId, setSelectedDeviceId] = useState<number | null>(null);
  const [auditData, setAuditData] = useState<AuditData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  const [generatingNotice, setGeneratingNotice] = useState(false);

  // Fetch audit data when device is selected
  useEffect(() => {
    if (!selectedDeviceId) {
      setAuditData(null);
      return;
    }

    const fetchAuditData = async () => {
      setLoading(true);
      setError(null);
      try {
        const response = await fetch(`${API_BASE_URL}/devices/${selectedDeviceId}/audit-logs`, {
          headers: { "ngrok-skip-browser-warning": "true" },
        });
        if (!response.ok) throw new Error("Failed to fetch audit logs");
        const data = await response.json();
        setAuditData(data);
      } catch (err: any) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchAuditData();
  }, [selectedDeviceId]);

  const formatDateTime = (dateStr: string) => {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleString("en-IN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  };

  const getSeverityColor = (severity: string) => {
    switch (severity?.toLowerCase()) {
      case "critical": return "error";
      case "high": return "error";
      case "medium": return "warning";
      case "low": return "info";
      default: return "default";
    }
  };

  const getStatusColor = (status: string) => {
    switch (status?.toLowerCase()) {
      case "executed": return "success";
      case "pending": return "warning";
      case "expired": return "error";
      default: return "default";
    }
  };

  // Generate Legal Notice PDF
  const generateLegalNotice = async () => {
    if (!auditData) return;

    setGeneratingNotice(true);

    // Create notice content
    const device = auditData.device;
    const stats = auditData.statistics;
    const tamperEvents = auditData.tamper_events;
    const unlockCommands = auditData.unlock_commands;

    // Create a new window for printing
    const printWindow = window.open("", "_blank");
    if (!printWindow) {
      alert("Please allow popups to generate the notice");
      setGeneratingNotice(false);
      return;
    }

    const noticeHTML = `
<!DOCTYPE html>
<html>
<head>
  <title>Legal Metrology Notice - Device ${device.device_id}</title>
  <style>
    @media print {
      body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
    body {
      font-family: 'Times New Roman', serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 40px;
      line-height: 1.6;
      color: #000;
    }
    .header {
      text-align: center;
      border-bottom: 3px double #000;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .emblem {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 40px;
      margin-bottom: 15px;
    }
    .emblem img {
      width: 80px;
      height: auto;
      object-fit: contain;
    }
    .ministry-name {
      font-size: 14px;
      font-weight: bold;
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    .department-name {
      font-size: 18px;
      font-weight: bold;
      color: #1a365d;
      margin: 10px 0;
    }
    .notice-title {
      font-size: 16px;
      font-weight: bold;
      text-decoration: underline;
      margin-top: 15px;
    }
    .notice-number {
      font-size: 12px;
      margin-top: 10px;
    }
    .section {
      margin: 25px 0;
    }
    .section-title {
      font-weight: bold;
      font-size: 14px;
      text-decoration: underline;
      margin-bottom: 10px;
      color: #1a365d;
    }
    .info-grid {
      display: grid;
      grid-template-columns: 200px 1fr;
      gap: 8px;
      margin: 10px 0;
    }
    .info-label {
      font-weight: bold;
    }
    .info-value {
      color: #333;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 15px 0;
      font-size: 12px;
    }
    th, td {
      border: 1px solid #000;
      padding: 8px;
      text-align: left;
    }
    th {
      background-color: #e8e8e8;
      font-weight: bold;
    }
    .severity-critical, .severity-high { color: #c53030; font-weight: bold; }
    .severity-medium { color: #d69e2e; }
    .severity-low { color: #3182ce; }
    .alert-box {
      background-color: #fff5f5;
      border: 2px solid #c53030;
      padding: 15px;
      margin: 20px 0;
      border-radius: 5px;
    }
    .alert-title {
      color: #c53030;
      font-weight: bold;
      font-size: 14px;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 15px;
      margin: 15px 0;
    }
    .stat-box {
      border: 1px solid #ccc;
      padding: 15px;
      text-align: center;
      background: #f7fafc;
    }
    .stat-value {
      font-size: 24px;
      font-weight: bold;
      color: #1a365d;
    }
    .stat-label {
      font-size: 12px;
      color: #666;
    }
    .footer {
      margin-top: 50px;
      border-top: 1px solid #000;
      padding-top: 20px;
    }
    .signature-section {
      display: flex;
      justify-content: space-between;
      margin-top: 60px;
    }
    .signature-box {
      text-align: center;
      width: 200px;
    }
    .signature-line {
      border-top: 1px solid #000;
      margin-top: 50px;
      padding-top: 5px;
    }
    .legal-text {
      font-size: 11px;
      color: #666;
      margin-top: 30px;
      padding: 15px;
      border: 1px solid #ccc;
      background: #fafafa;
    }
    .watermark {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%) rotate(-45deg);
      font-size: 100px;
      color: rgba(0,0,0,0.03);
      pointer-events: none;
      z-index: -1;
    }
  </style>
</head>
<body>
  <div class="watermark">OFFICIAL</div>

  <div class="header">
    <div class="emblem">
      <img src="${window.location.origin}/images/ashoka-emblem.png" alt="Ashoka Emblem" />
      <div>
        <div class="ministry-name">Government of India</div>
        <div class="ministry-name">Ministry of Consumer Affairs, Food & Public Distribution</div>
        <div class="department-name">Department of Legal Metrology</div>
      </div>
      <img src="${window.location.origin}/images/lmd-logo.png" alt="Legal Metrology Department Logo" />
    </div>
    <div class="notice-title">TAMPER DETECTION & DEVICE AUDIT REPORT</div>
    <div class="notice-number">
      Notice No.: LMD/TD/${new Date().getFullYear()}/${device.device_id}/${Date.now().toString().slice(-6)}<br>
      Date of Issue: ${new Date().toLocaleDateString("en-IN", { day: "2-digit", month: "long", year: "numeric" })}
    </div>
  </div>

  <div class="section">
    <div class="section-title">1. DEVICE INFORMATION</div>
    <div class="info-grid">
      <div class="info-label">Device ID:</div>
      <div class="info-value">${device.device_id}</div>
      <div class="info-label">Device Type:</div>
      <div class="info-value">${device.device_type || "Weighing Scale"}</div>
      <div class="info-label">Owner/Licensee:</div>
      <div class="info-value">${device.owner || "Not Registered"}</div>
      <div class="info-label">Installation Location:</div>
      <div class="info-value">${device.location || "Not Specified"}</div>
      <div class="info-label">Current Status:</div>
      <div class="info-value" style="color: ${device.status === 'online' ? '#38a169' : '#c53030'}; font-weight: bold;">${device.status?.toUpperCase() || "UNKNOWN"}</div>
      <div class="info-label">Registration Date:</div>
      <div class="info-value">${device.created_at ? new Date(device.created_at).toLocaleDateString("en-IN") : "N/A"}</div>
      <div class="info-label">Last Communication:</div>
      <div class="info-value">${device.last_seen ? new Date(device.last_seen).toLocaleString("en-IN") : "N/A"}</div>
    </div>
  </div>

  ${stats.total_tamper_events > 0 ? `
  <div class="alert-box">
    <div class="alert-title">TAMPER ALERT - IMMEDIATE ATTENTION REQUIRED</div>
    <p>This device has recorded <strong>${stats.total_tamper_events}</strong> tamper event(s).
    As per the Legal Metrology Act, 2009 and the Legal Metrology (General) Rules, 2011,
    any tampering with weighing or measuring instruments is a punishable offense under Section 25.</p>
  </div>
  ` : ''}

  <div class="section">
    <div class="section-title">2. AUDIT SUMMARY STATISTICS</div>
    <div class="stats-grid">
      <div class="stat-box">
        <div class="stat-value">${stats.total_tamper_events}</div>
        <div class="stat-label">Total Tamper Events</div>
      </div>
      <div class="stat-box">
        <div class="stat-value">${stats.total_unlocks}</div>
        <div class="stat-label">Authorized Unlocks</div>
      </div>
      <div class="stat-box">
        <div class="stat-value">${Object.keys(stats.tamper_types).length}</div>
        <div class="stat-label">Tamper Types Detected</div>
      </div>
    </div>
    <div class="info-grid">
      <div class="info-label">First Tamper Detected:</div>
      <div class="info-value">${stats.first_tamper ? new Date(stats.first_tamper).toLocaleString("en-IN") : "No tamper events"}</div>
      <div class="info-label">Last Tamper Detected:</div>
      <div class="info-value">${stats.last_tamper ? new Date(stats.last_tamper).toLocaleString("en-IN") : "No tamper events"}</div>
    </div>
    ${Object.keys(stats.tamper_types).length > 0 ? `
    <p><strong>Tamper Types Breakdown:</strong></p>
    <ul>
      ${Object.entries(stats.tamper_types).map(([type, count]) => `<li>${type}: ${count} occurrence(s)</li>`).join('')}
    </ul>
    ` : ''}
  </div>

  ${tamperEvents.length > 0 ? `
  <div class="section">
    <div class="section-title">3. DETAILED TAMPER EVENT LOG</div>
    <table>
      <thead>
        <tr>
          <th>S.No.</th>
          <th>Date & Time</th>
          <th>Tamper Type</th>
          <th>Severity</th>
          <th>Location</th>
          <th>Details</th>
        </tr>
      </thead>
      <tbody>
        ${tamperEvents.slice(0, 20).map((event, index) => `
        <tr>
          <td>${index + 1}</td>
          <td>${new Date(event.event_time).toLocaleString("en-IN")}</td>
          <td>${event.tamper_type || "Unknown"}</td>
          <td class="severity-${event.severity?.toLowerCase()}">${event.severity?.toUpperCase() || "N/A"}</td>
          <td>${event.city || ""}${event.city && event.state ? ", " : ""}${event.state || ""}<br>
              ${event.latitude && event.longitude ? `GPS: ${parseFloat(event.latitude).toFixed(6)}, ${parseFloat(event.longitude).toFixed(6)}` : ""}</td>
          <td>${event.details || "—"}</td>
        </tr>
        `).join('')}
      </tbody>
    </table>
    ${tamperEvents.length > 20 ? `<p><em>Showing first 20 of ${tamperEvents.length} events. Complete log available on request.</em></p>` : ''}
  </div>
  ` : ''}

  ${unlockCommands.length > 0 ? `
  <div class="section">
    <div class="section-title">4. DEVICE UNLOCK HISTORY</div>
    <p>The following authorized unlock commands have been issued for this device:</p>
    <table>
      <thead>
        <tr>
          <th>S.No.</th>
          <th>Command Date</th>
          <th>Officer Name</th>
          <th>Officer Email</th>
          <th>Role</th>
          <th>Reason for Unlock</th>
          <th>Status</th>
          <th>Executed At</th>
        </tr>
      </thead>
      <tbody>
        ${unlockCommands.map((cmd, index) => `
        <tr>
          <td>${index + 1}</td>
          <td>${new Date(cmd.created_at).toLocaleString("en-IN")}</td>
          <td>${cmd.officer_name || cmd.officer_id || "Unknown"}</td>
          <td>${cmd.officer_email || "—"}</td>
          <td>${cmd.officer_role || "—"}</td>
          <td>${cmd.reason || "Remote unlock via dashboard"}</td>
          <td style="color: ${cmd.status === 'executed' ? '#38a169' : cmd.status === 'pending' ? '#d69e2e' : '#c53030'}">${cmd.status?.toUpperCase()}</td>
          <td>${cmd.executed_at ? new Date(cmd.executed_at).toLocaleString("en-IN") : "—"}</td>
        </tr>
        `).join('')}
      </tbody>
    </table>
  </div>
  ` : ''}

  <div class="section">
    <div class="section-title">5. LEGAL PROVISIONS & PENALTIES</div>
    <p>As per the <strong>Legal Metrology Act, 2009</strong>:</p>
    <ul>
      <li><strong>Section 25:</strong> Whoever tampers with, or causes to be tampered with, any weight or measure or other goods with intention to sell shall be punished with fine which may extend to twenty-five thousand rupees for the first offence.</li>
      <li><strong>Section 26:</strong> For second or subsequent offence, punishment shall be imprisonment for a term which may extend to six months, or with fine not less than twenty-five thousand rupees.</li>
      <li><strong>Section 27:</strong> Any person who manufactures, sells or uses non-standard weight or measure shall be punished with fine which may extend to ten thousand rupees.</li>
    </ul>
  </div>

  <div class="section">
    <div class="section-title">6. RECOMMENDATIONS</div>
    <ul>
      ${stats.total_tamper_events > 0 ? `
      <li>Immediate inspection of the device by authorized Legal Metrology Officer is recommended.</li>
      <li>Device owner/licensee should be summoned for explanation regarding the detected tamper events.</li>
      <li>If tampering is confirmed, appropriate legal action should be initiated under relevant sections of the Legal Metrology Act, 2009.</li>
      ` : `
      <li>Device is operating within compliance parameters.</li>
      <li>Regular periodic inspection is recommended as per schedule.</li>
      `}
      <li>All future unlock requests should be documented with proper authorization.</li>
    </ul>
  </div>

  <div class="footer">
    <div class="legal-text">
      <strong>DISCLAIMER:</strong> This is a computer-generated report from the Calibris Tamper Monitoring System.
      The data presented is sourced from automated sensors and logging systems. This report is intended for official
      use by the Department of Legal Metrology and authorized personnel only. Any unauthorized use, reproduction,
      or distribution is prohibited under the Information Technology Act, 2000.
    </div>

    <div class="signature-section">
      <div class="signature-box">
        <div class="signature-line">
          Inspecting Officer<br>
          <small>Name & Designation</small>
        </div>
      </div>
      <div class="signature-box">
        <div class="signature-line">
          Controller of Legal Metrology<br>
          <small>District/State</small>
        </div>
      </div>
    </div>

    <p style="text-align: center; margin-top: 30px; font-size: 11px; color: #666;">
      Generated on: ${new Date().toLocaleString("en-IN")} | System: Calibris Tamper Monitoring v1.0<br>
      Department of Legal Metrology, Government of India
    </p>
  </div>
</body>
</html>
    `;

    printWindow.document.write(noticeHTML);
    printWindow.document.close();

    // Wait for content to load then trigger print
    printWindow.onload = () => {
      setTimeout(() => {
        printWindow.print();
        setGeneratingNotice(false);
      }, 500);
    };
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2 }, height: "calc(100vh - 100px)", display: "flex", flexDirection: "column" }}>
      <h1 className="page-heading" style={{ fontSize: "clamp(1.25rem, 4vw, 1.5rem)" }}>Audit Logs</h1>
      <Typography variant="body2" sx={{ color: "#94a3b8", mb: { xs: 1.5, sm: 2 }, fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>
        Select a device to view detailed tamper logs, unlock history, and generate legal notices for the Legal Metrology Department.
      </Typography>

      <Box sx={{ display: "flex", flexDirection: { xs: "column", md: "row" }, gap: { xs: 1.5, sm: 2 }, flex: 1, minHeight: 0 }}>
        {/* Left Panel - Device List */}
        <Paper
          className="panel"
          sx={{
            width: { xs: "100%", md: 280 },
            p: 0,
            overflow: "auto",
            flexShrink: 0,
            maxHeight: { xs: "200px", md: "none" },
          }}
        >
          <Box sx={{ p: 2, borderBottom: "1px solid rgba(148,163,184,.15)" }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
              Registered Devices ({devices.length})
            </Typography>
          </Box>
          <List dense sx={{ p: 0 }}>
            {devices.map((device: any) => (
              <ListItemButton
                key={device.id}
                selected={selectedDeviceId === device.id}
                onClick={() => setSelectedDeviceId(device.id)}
                sx={{
                  borderBottom: "1px solid rgba(148,163,184,.1)",
                  "&.Mui-selected": {
                    backgroundColor: "rgba(59, 130, 246, 0.15)",
                  },
                }}
              >
                <ListItemIcon sx={{ minWidth: 36 }}>
                  <DevicesIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText
                  primary={`Device #${device.id}`}
                  secondary={device.location || device.deviceType || "Unknown"}
                  primaryTypographyProps={{ fontSize: 14 }}
                  secondaryTypographyProps={{ fontSize: 12 }}
                />
                <Chip
                  label={device.status || "online"}
                  size="small"
                  color={
                    device.status === "safe_mode" || device.status === "Tampered"
                      ? "error"
                      : device.status === "online"
                      ? "success"
                      : "default"
                  }
                  sx={{ fontSize: 10 }}
                />
              </ListItemButton>
            ))}
          </List>
        </Paper>

        {/* Right Panel - Audit Details */}
        <Paper className="panel" sx={{ flex: 1, p: 0, overflow: "hidden", display: "flex", flexDirection: "column" }}>
          {!selectedDeviceId ? (
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", color: "#64748b" }}>
              <Typography>Select a device to view audit logs</Typography>
            </Box>
          ) : loading ? (
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%" }}>
              <CircularProgress />
            </Box>
          ) : error ? (
            <Box sx={{ p: 3 }}>
              <Alert severity="error">{error}</Alert>
            </Box>
          ) : auditData ? (
            <Box sx={{ display: "flex", flexDirection: "column", height: "100%" }}>
              {/* Device Header */}
              <Box sx={{ p: { xs: 1.5, sm: 2 }, borderBottom: "1px solid rgba(148,163,184,.15)" }}>
                <Stack direction={{ xs: "column", sm: "row" }} justifyContent="space-between" alignItems={{ xs: "flex-start", sm: "center" }} spacing={1}>
                  <Box>
                    <Typography variant="h6" sx={{ fontSize: { xs: "1rem", sm: "1.25rem" } }}>Device #{auditData.device.device_id}</Typography>
                    <Typography variant="body2" sx={{ color: "#94a3b8", fontSize: { xs: "0.7rem", sm: "0.875rem" } }}>
                      {auditData.device.device_type || "Weighing Scale"} | {auditData.device.location || "Location not set"}
                    </Typography>
                  </Box>
                  <Button
                    variant="contained"
                    color="primary"
                    size="small"
                    startIcon={generatingNotice ? <CircularProgress size={14} /> : <GavelIcon sx={{ fontSize: { xs: 16, sm: 20 } }} />}
                    onClick={generateLegalNotice}
                    disabled={generatingNotice}
                    sx={{ fontSize: { xs: "0.7rem", sm: "0.875rem" }, py: { xs: 0.5, sm: 1 } }}
                  >
                    {generatingNotice ? "Generating..." : "Generate Legal Notice"}
                  </Button>
                </Stack>
              </Box>

              {/* Statistics Cards */}
              <Box sx={{ p: { xs: 1.5, sm: 2 }, borderBottom: "1px solid rgba(148,163,184,.15)" }}>
                <Stack direction="row" spacing={{ xs: 1, sm: 2 }} sx={{ overflowX: "auto" }}>
                  <Card sx={{ flex: 1, minWidth: { xs: 80, sm: "auto" }, background: "rgba(239, 68, 68, 0.1)", border: "1px solid rgba(239, 68, 68, 0.3)" }}>
                    <CardContent sx={{ py: { xs: 1, sm: 1.5 }, px: { xs: 1, sm: 2 }, "&:last-child": { pb: { xs: 1, sm: 1.5 } } }}>
                      <Typography variant="h4" sx={{ color: "#ef4444", fontWeight: 700, fontSize: { xs: "1.25rem", sm: "2rem" } }}>
                        {auditData.statistics.total_tamper_events}
                      </Typography>
                      <Typography variant="body2" sx={{ color: "#94a3b8", fontSize: { xs: "0.65rem", sm: "0.875rem" } }}>Tamper Events</Typography>
                    </CardContent>
                  </Card>
                  <Card sx={{ flex: 1, minWidth: { xs: 80, sm: "auto" }, background: "rgba(34, 197, 94, 0.1)", border: "1px solid rgba(34, 197, 94, 0.3)" }}>
                    <CardContent sx={{ py: { xs: 1, sm: 1.5 }, px: { xs: 1, sm: 2 }, "&:last-child": { pb: { xs: 1, sm: 1.5 } } }}>
                      <Typography variant="h4" sx={{ color: "#22c55e", fontWeight: 700, fontSize: { xs: "1.25rem", sm: "2rem" } }}>
                        {auditData.statistics.total_unlocks}
                      </Typography>
                      <Typography variant="body2" sx={{ color: "#94a3b8", fontSize: { xs: "0.65rem", sm: "0.875rem" } }}>Authorized Unlocks</Typography>
                    </CardContent>
                  </Card>
                  <Card sx={{ flex: 1, minWidth: { xs: 80, sm: "auto" }, background: "rgba(245, 158, 11, 0.1)", border: "1px solid rgba(245, 158, 11, 0.3)" }}>
                    <CardContent sx={{ py: { xs: 1, sm: 1.5 }, px: { xs: 1, sm: 2 }, "&:last-child": { pb: { xs: 1, sm: 1.5 } } }}>
                      <Typography variant="h4" sx={{ color: "#f59e0b", fontWeight: 700, fontSize: { xs: "1.25rem", sm: "2rem" } }}>
                        {auditData.statistics.pending_unlocks}
                      </Typography>
                      <Typography variant="body2" sx={{ color: "#94a3b8", fontSize: { xs: "0.65rem", sm: "0.875rem" } }}>Pending Unlocks</Typography>
                    </CardContent>
                  </Card>
                </Stack>
              </Box>

              {/* Tabs */}
              <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} sx={{ px: 2, borderBottom: "1px solid rgba(148,163,184,.15)" }}>
                <Tab icon={<WarningAmberIcon />} iconPosition="start" label={`Tamper Events (${auditData.tamper_events.length})`} />
                <Tab icon={<LockOpenIcon />} iconPosition="start" label={`Unlock History (${auditData.unlock_commands.length})`} />
              </Tabs>

              {/* Tab Content */}
              <Box sx={{ flex: 1, overflow: "auto", p: 0 }}>
                {activeTab === 0 && (
                  <TableContainer>
                    <Table size="small" stickyHeader>
                      <TableHead>
                        <TableRow>
                          <TableCell>Date & Time</TableCell>
                          <TableCell>Tamper Type</TableCell>
                          <TableCell>Severity</TableCell>
                          <TableCell>Location</TableCell>
                          <TableCell>Details</TableCell>
                          <TableCell>Hash Verification</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {auditData.tamper_events.length === 0 ? (
                          <TableRow>
                            <TableCell colSpan={6} align="center" sx={{ py: 4, color: "#64748b" }}>
                              No tamper events recorded for this device
                            </TableCell>
                          </TableRow>
                        ) : (
                          auditData.tamper_events.map((event) => (
                            <TableRow key={event.id} hover>
                              <TableCell sx={{ whiteSpace: "nowrap" }}>{formatDateTime(event.event_time)}</TableCell>
                              <TableCell>
                                <Chip label={event.tamper_type || "Unknown"} size="small" variant="outlined" />
                              </TableCell>
                              <TableCell>
                                <Chip
                                  label={event.severity || "N/A"}
                                  size="small"
                                  color={getSeverityColor(event.severity) as any}
                                />
                              </TableCell>
                              <TableCell>
                                {event.city || event.state ? (
                                  <>
                                    {event.city}{event.city && event.state ? ", " : ""}{event.state}
                                    {event.latitude && event.longitude && (
                                      <Typography variant="caption" display="block" sx={{ color: "#64748b" }}>
                                        GPS: {parseFloat(event.latitude).toFixed(4)}, {parseFloat(event.longitude).toFixed(4)}
                                      </Typography>
                                    )}
                                  </>
                                ) : "—"}
                              </TableCell>
                              <TableCell sx={{ maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis" }}>
                                {event.details || "—"}
                              </TableCell>
                              <TableCell sx={{ fontSize: 10, fontFamily: "monospace" }}>
                                {event.prev_hash && event.curr_hash ? (
                                  <>
                                    <Typography variant="caption" display="block" sx={{ color: "#64748b" }}>
                                      Prev: {event.prev_hash.slice(0, 12)}...
                                    </Typography>
                                    <Typography variant="caption" display="block" sx={{ color: "#64748b" }}>
                                      Curr: {event.curr_hash.slice(0, 12)}...
                                    </Typography>
                                  </>
                                ) : "—"}
                              </TableCell>
                            </TableRow>
                          ))
                        )}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}

                {activeTab === 1 && (
                  <TableContainer>
                    <Table size="small" stickyHeader>
                      <TableHead>
                        <TableRow>
                          <TableCell>Command ID</TableCell>
                          <TableCell>Date & Time</TableCell>
                          <TableCell>Officer ID</TableCell>
                          <TableCell>Reason</TableCell>
                          <TableCell>Status</TableCell>
                          <TableCell>Executed At</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {auditData.unlock_commands.length === 0 ? (
                          <TableRow>
                            <TableCell colSpan={6} align="center" sx={{ py: 4, color: "#64748b" }}>
                              No unlock commands recorded for this device
                            </TableCell>
                          </TableRow>
                        ) : (
                          auditData.unlock_commands.map((cmd) => (
                            <TableRow key={cmd.id} hover>
                              <TableCell>#{cmd.id}</TableCell>
                              <TableCell sx={{ whiteSpace: "nowrap" }}>{formatDateTime(cmd.created_at)}</TableCell>
                              <TableCell>{cmd.officer_id}</TableCell>
                              <TableCell>{cmd.reason || "Remote unlock via dashboard"}</TableCell>
                              <TableCell>
                                <Chip
                                  label={cmd.status}
                                  size="small"
                                  color={getStatusColor(cmd.status) as any}
                                />
                              </TableCell>
                              <TableCell sx={{ whiteSpace: "nowrap" }}>
                                {cmd.executed_at ? formatDateTime(cmd.executed_at) : "—"}
                              </TableCell>
                            </TableRow>
                          ))
                        )}
                      </TableBody>
                    </Table>
                  </TableContainer>
                )}
              </Box>

              {/* Export Button */}
              <Box sx={{ p: 2, borderTop: "1px solid rgba(148,163,184,.15)" }}>
                <Button
                  variant="outlined"
                  startIcon={<DownloadIcon />}
                  onClick={() => {
                    // Export as CSV
                    const events = auditData.tamper_events;
                    const headers = ["ID", "Date", "Tamper Type", "Severity", "City", "State", "Latitude", "Longitude", "Details"];
                    const rows = events.map(e => [
                      e.id,
                      new Date(e.event_time).toISOString(),
                      e.tamper_type || "",
                      e.severity || "",
                      e.city || "",
                      e.state || "",
                      e.latitude ? String(e.latitude) : "",
                      e.longitude ? String(e.longitude) : "",
                      `"${(e.details || "").replace(/"/g, '""')}"`
                    ]);
                    const csv = [headers.join(","), ...rows.map(r => r.join(","))].join("\n");
                    const blob = new Blob([csv], { type: "text/csv" });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement("a");
                    a.href = url;
                    a.download = `audit_device_${selectedDeviceId}_${new Date().toISOString().split("T")[0]}.csv`;
                    a.click();
                  }}
                >
                  Export CSV
                </Button>
              </Box>
            </Box>
          ) : null}
        </Paper>
      </Box>

      <Footer />
    </Box>
  );
}
