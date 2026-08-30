// client/pages/Dashboard.tsx
import React from "react";
import { Paper, Typography, Box } from "@mui/material";
import { useStore } from "@/context/StoreContext";
import { countByStatus } from "@/data/mock";
import StatCard from "@/components/StatCard";
import Footer from "@/components/Footer";
import MapView from "@/components/MapView";
import EventsList from "@/components/EventsList";
import { TamperAlertListener } from "@/components/TamperAlertListener";

export default function DashboardPage() {
  const { devices } = useStore();

  // Calculate online/offline status based on last_seen timestamp
  const calculateDeviceStatus = (devices: any[]) => {
    const now = new Date().getTime();
    const OFFLINE_THRESHOLD = 2 * 60 * 1000; // 2 minutes in milliseconds

    return devices.map((device: any) => {
      if (device.last_seen) {
        const lastSeen = new Date(device.last_seen).getTime();
        const timeDiff = now - lastSeen;

        // If device hasn't reported in 2 minutes, mark as offline
        if (timeDiff > OFFLINE_THRESHOLD && device.status !== 'Tampered' && device.status !== 'Drifted') {
          return { ...device, status: 'Offline' };
        } else if (timeDiff <= OFFLINE_THRESHOLD && device.status !== 'Tampered' && device.status !== 'Drifted') {
          return { ...device, status: 'Online' };
        }
      }
      return device;
    });
  };

  const devicesWithStatus = calculateDeviceStatus(devices);
  const counts = countByStatus(devicesWithStatus);

  // Filter for all devices with valid GPS coordinates
  const devicesWithGPS = (Array.isArray(devices) ? devices : []).filter((d: any) => {
    const lat = Number(d.lat ?? d.latitude ?? NaN);
    const lng = Number(d.lng ?? d.longitude ?? NaN);
    return Number.isFinite(lat) && Number.isFinite(lng);
  });

  return (
    <Box sx={{ py: { xs: 1, sm: 2 }, px: 0, width: '100%' }}>
      <Typography
        variant="h5"
        sx={{
          px: { xs: 2, sm: 3 },
          mb: { xs: 2, sm: 3 },
          fontWeight: 700,
          fontSize: { xs: '1.25rem', sm: '1.5rem' },
          color: '#111827',
        }}
      >
        Dashboard
      </Typography>

      {/* Real-time Tamper Alerts */}
      <Box sx={{ px: { xs: 2, sm: 3 }, mb: { xs: 2, sm: 3 } }}>
        <TamperAlertListener />
      </Box>

      {/* Metrics bar */}
      <Box sx={{
        display: 'grid',
        gridTemplateColumns: { xs: 'repeat(2, 1fr)', sm: 'repeat(4, 1fr)' },
        gap: { xs: 1.5, sm: 2 },
        px: { xs: 2, sm: 3 },
        mb: { xs: 2, sm: 3 },
      }}>
        <StatCard label="Total Devices" value={counts.total} color="#1a3a6b" />
        <StatCard label="Online" value={counts.online} color="#16a34a" />
        <StatCard label="Offline" value={counts.offline} color="#6b7280" />
        <StatCard label="Tampered" value={counts.tampered} color="#dc2626" />
      </Box>

      {/* Map + Events */}
      <Box sx={{ width: '100%', px: { xs: 2, sm: 3 }, mb: { xs: 2, sm: 3 } }}>
        <Box sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', md: '2fr 1fr' },
          gap: { xs: 2, sm: 3 },
          width: '100%',
        }}>
          {/* Map Section */}
          <Box sx={{ minHeight: { xs: '300px', md: '520px' } }}>
            <Paper
              className="panel"
              sx={{
                height: '100%',
                p: { xs: 1.5, sm: 2 },
                display: 'flex',
                flexDirection: 'column',
              }}
            >
              <Typography
                variant="h6"
                sx={{
                  mb: 1,
                  fontWeight: 700,
                  fontSize: { xs: '1rem', sm: '1.1rem' },
                  color: '#111827',
                }}
              >
                Device Locations
              </Typography>
              <Box sx={{ flex: 1, minHeight: { xs: 250, sm: 480 }, borderRadius: 1, overflow: 'hidden' }}>
                <MapView height="100%" devices={devicesWithGPS} />
              </Box>
            </Paper>
          </Box>

          {/* Recent Events Section */}
          <Box sx={{ minHeight: { xs: '250px', md: '520px' } }}>
            <Paper
              className="panel"
              sx={{
                height: '100%',
                p: { xs: 1.5, sm: 2 },
                overflow: 'auto',
              }}
            >
              <Typography
                variant="h6"
                sx={{
                  mb: 1,
                  fontWeight: 700,
                  fontSize: { xs: '1rem', sm: '1.1rem' },
                  color: '#111827',
                }}
              >
                Recent Events
              </Typography>
              <EventsList limit={8} />
            </Paper>
          </Box>
        </Box>
      </Box>

      <Footer />
    </Box>
  );
}
