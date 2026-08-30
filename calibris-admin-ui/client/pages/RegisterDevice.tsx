// client/pages/RegisterDevice.tsx
// Public page for manufacturers to register their devices
import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Alert,
  CircularProgress,
  Divider,
} from "@mui/material";
import DevicesIcon from "@mui/icons-material/Devices";

const API_BASE_URL = import.meta.env.VITE_API_URL || "/api";

interface DeviceFormData {
  device_id: string;
  owner_name: string;
  owner_email: string;
  owner_phone: string;
  company_name: string;
  device_type: string;
  location: string;
  city: string;
  state: string;
  latitude: string;
  longitude: string;
}

interface RegisteredDevice {
  device_id: number;
  owner: string;
  device_type: string;
  location: string;
}

const RegisterDevice: React.FC = () => {
  const [formData, setFormData] = useState<DeviceFormData>({
    device_id: "",
    owner_name: "",
    owner_email: "",
    owner_phone: "",
    company_name: "",
    device_type: "weighing-scale",
    location: "",
    city: "",
    state: "",
    latitude: "",
    longitude: "",
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<RegisteredDevice | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    setLoading(true);

    // Validation
    if (!formData.device_id || !formData.owner_name || !formData.owner_email || !formData.company_name) {
      setError("Please fill in all required fields (Device ID, Name, Email, Company)");
      setLoading(false);
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/devices/register`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          device_id: parseInt(formData.device_id),
          owner_name: formData.owner_name,
          owner_email: formData.owner_email,
          owner_phone: formData.owner_phone,
          company_name: formData.company_name,
          device_type: formData.device_type || "weighing-scale",
          location: formData.location,
          city: formData.city,
          state: formData.state,
          latitude: formData.latitude ? parseFloat(formData.latitude) : null,
          longitude: formData.longitude ? parseFloat(formData.longitude) : null,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || "Failed to register device");
      }

      setSuccess(data.device);
      // Clear form
      setFormData({
        device_id: "",
        owner_name: "",
        owner_email: "",
        owner_phone: "",
        company_name: "",
        device_type: "weighing-scale",
        location: "",
        city: "",
        state: "",
        latitude: "",
        longitude: "",
      });
    } catch (err: any) {
      setError(err.message || "Failed to register device");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #f3f4f6 0%, #1a2744 100%)",
        display: "flex",
        justifyContent: "center",
        alignItems: { xs: "flex-start", sm: "center" },
        padding: { xs: 1.5, sm: 3 },
        paddingTop: { xs: 2, sm: 3 },
      }}
    >
      <Paper
        elevation={6}
        sx={{
          width: "100%",
          maxWidth: { xs: "100%", sm: 600 },
          padding: { xs: 2.5, sm: 4 },
          background: "#ffffff",
          color: "white",
          borderRadius: { xs: "12px", sm: "16px" },
          border: "1px solid #2a3d6a",
        }}
      >
        {/* Header */}
        <Box sx={{ textAlign: "center", mb: { xs: 2, sm: 3 } }}>
          <DevicesIcon sx={{ fontSize: { xs: 40, sm: 48 }, color: "#1a3a6b", mb: 1 }} />
          <Typography variant="h4" sx={{ fontWeight: 700, fontSize: { xs: "1.4rem", sm: "2rem" } }}>
            Register Your Device
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.7, mt: 1, fontSize: { xs: "0.75rem", sm: "0.875rem" } }}>
            Calibris Tamper Detection System
          </Typography>
        </Box>

        {/* Success Message */}
        {success && (
          <Alert
            severity="success"
            sx={{
              mb: 3,
              backgroundColor: "#0d3320",
              color: "#4ade80",
              "& .MuiAlert-icon": { color: "#4ade80" },
            }}
          >
            <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
              Device Registered Successfully!
            </Typography>
            <Typography variant="body2" sx={{ mt: 1 }}>
              Your Device ID: <strong style={{ fontSize: "1.2em" }}>{success.device_id}</strong>
            </Typography>
            <Typography variant="body2" sx={{ mt: 1, opacity: 0.9 }}>
              Please save this Device ID. You will need it to configure your Luckfox device.
            </Typography>
          </Alert>
        )}

        {/* Error Message */}
        {error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {error}
          </Alert>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit}>
          {/* Device ID - Hardcoded in firmware */}
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: "#2563eb" }}>
            Device ID (from firmware)
          </Typography>

          <TextField
            label="Device ID *"
            name="device_id"
            fullWidth
            variant="filled"
            value={formData.device_id}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 3, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            placeholder="Enter the Device ID hardcoded in your Luckfox firmware"
            helperText="This is the ID programmed into your device's firmware"
          />

          <Divider sx={{ borderColor: "#2a3d6a", mb: 3 }} />

          {/* Owner Information */}
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: "#2563eb" }}>
            Owner Information
          </Typography>

          <TextField
            label="Owner Name *"
            name="owner_name"
            fullWidth
            variant="filled"
            value={formData.owner_name}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
          />

          <TextField
            label="Email Address *"
            name="owner_email"
            type="email"
            fullWidth
            variant="filled"
            value={formData.owner_email}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
          />

          <TextField
            label="Phone Number"
            name="owner_phone"
            fullWidth
            variant="filled"
            value={formData.owner_phone}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
          />

          <TextField
            label="Company/Business Name *"
            name="company_name"
            fullWidth
            variant="filled"
            value={formData.company_name}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 3, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
          />

          <Divider sx={{ borderColor: "#2a3d6a", mb: 3 }} />

          {/* Device Information */}
          <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: "#2563eb" }}>
            Device Information
          </Typography>

          <TextField
            label="Device Type"
            name="device_type"
            fullWidth
            variant="filled"
            value={formData.device_type}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            placeholder="e.g., weighing-scale, flow-meter"
          />

          <TextField
            label="Installation Location"
            name="location"
            fullWidth
            variant="filled"
            value={formData.location}
            onChange={handleChange}
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            placeholder="e.g., Main warehouse, Shop floor"
          />

          <Box sx={{ display: "flex", flexDirection: { xs: "column", sm: "row" }, gap: 2, mb: 2 }}>
            <TextField
              label="City"
              name="city"
              fullWidth
              variant="filled"
              value={formData.city}
              onChange={handleChange}
              InputProps={{ disableUnderline: true }}
              sx={{ background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            />
            <TextField
              label="State"
              name="state"
              fullWidth
              variant="filled"
              value={formData.state}
              onChange={handleChange}
              InputProps={{ disableUnderline: true }}
              sx={{ background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            />
          </Box>

          <Box sx={{ display: "flex", flexDirection: { xs: "column", sm: "row" }, gap: 2, mb: 3 }}>
            <TextField
              label="Latitude (optional)"
              name="latitude"
              fullWidth
              variant="filled"
              value={formData.latitude}
              onChange={handleChange}
              InputProps={{ disableUnderline: true }}
              sx={{ background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
              placeholder="e.g., 12.9716"
            />
            <TextField
              label="Longitude (optional)"
              name="longitude"
              fullWidth
              variant="filled"
              value={formData.longitude}
              onChange={handleChange}
              InputProps={{ disableUnderline: true }}
              sx={{ background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
              placeholder="e.g., 77.5946"
            />
          </Box>

          {/* Submit Button */}
          <Button
            type="submit"
            fullWidth
            variant="contained"
            disabled={loading}
            sx={{
              background: "#1a3a6b",
              py: 1.5,
              fontSize: "1rem",
              fontWeight: 600,
              "&:hover": { background: "#0284c7" },
            }}
          >
            {loading ? <CircularProgress size={24} color="inherit" /> : "Register Device"}
          </Button>
        </form>

        {/* Footer */}
        <Typography
          variant="body2"
          sx={{ textAlign: "center", mt: 3, opacity: 0.6 }}
        >
          Legal Metrology Department - Calibris Tamper Detection
        </Typography>
      </Paper>
    </Box>
  );
};

export default RegisterDevice;
