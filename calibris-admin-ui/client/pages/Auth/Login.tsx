import React, { useState } from "react";
import {
  Box,
  TextField,
  Button,
  Paper,
  Typography,
  Alert,
  InputAdornment,
  IconButton,
  ToggleButton,
  ToggleButtonGroup,
  CircularProgress,
} from "@mui/material";
import AdminPanelSettingsRounded from "@mui/icons-material/AdminPanelSettingsRounded";
import PersonRounded from "@mui/icons-material/PersonRounded";
import Visibility from "@mui/icons-material/Visibility";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import { useAuth, type UserRole } from "@/context/AuthContext";
import { useNavigate, Link } from "react-router-dom";

const LoginPage: React.FC = () => {
  const { login, user } = useAuth();
  const navigate = useNavigate();

  const [role, setRole] = useState<UserRole>("officer");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  // Redirect if already logged in
  React.useEffect(() => {
    if (user) {
      navigate("/");
    }
  }, [user, navigate]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    
    if (!email.trim() || !password) {
      setError("Please enter email and password");
      return;
    }

    setLoading(true);
    const result = await login(email.trim(), password, role);
    setLoading(false);

    if (!result.ok) {
      setError(result.error || "Login failed. Please try again.");
      return;
    }

    navigate("/");
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        background: "#f3f4f6",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        pt: { xs: 4, sm: 8 },
        px: { xs: 2, sm: 2 },
      }}
    >
      {/* Tricolor stripe at top */}
      <Box sx={{ position: 'fixed', top: 0, left: 0, right: 0, display: 'flex', height: 4, zIndex: 9999 }}>
        <Box sx={{ flex: 1, bgcolor: '#FF9933' }} />
        <Box sx={{ flex: 1, bgcolor: '#ffffff' }} />
        <Box sx={{ flex: 1, bgcolor: '#138808' }} />
      </Box>

      {/* Header text */}
      <Box sx={{ textAlign: "center", mb: 3 }}>
        <Typography sx={{ fontSize: { xs: 12, sm: 13 }, color: "#6b7280", fontWeight: 500 }}>
          भारत सरकार · Government of India
        </Typography>
        <Typography sx={{ fontSize: { xs: 18, sm: 22 }, color: "#1a3a6b", fontWeight: 800, mt: 0.5, letterSpacing: '0.02em' }}>
          Department of Legal Metrology
        </Typography>
      </Box>

      <Paper
        elevation={0}
        sx={{
          width: "100%",
          maxWidth: { xs: "100%", sm: 440 },
          p: { xs: 3, sm: 4 },
          background: "#ffffff",
          border: "1px solid #d1d5db",
          borderRadius: "8px",
        }}
      >
        {/* Header */}
        <Box sx={{ textAlign: "center", mb: 3 }}>
          <Typography variant="h5" sx={{ fontWeight: 700, color: "#111827", mb: 0.5 }}>
            Sign in to Calibris
          </Typography>
          <Typography variant="body2" sx={{ color: "#6b7280" }}>
            Enter your credentials to access the portal
          </Typography>
        </Box>

        {/* Role Selection */}
        <Box sx={{ mb: 3 }}>
          <Typography variant="body2" sx={{ mb: 1, color: "#374151", fontWeight: 600 }}>
            Sign in as:
          </Typography>
          <ToggleButtonGroup
            value={role}
            exclusive
            onChange={(e, newRole) => {
              if (newRole !== null) setRole(newRole);
            }}
            fullWidth
            sx={{
              "& .MuiToggleButton-root": {
                color: "#374151",
                border: "1px solid #d1d5db",
                py: 1,
                fontSize: 14,
                fontWeight: 600,
                "&.Mui-selected": {
                  backgroundColor: "#1a3a6b",
                  color: "#ffffff",
                  borderColor: "#1a3a6b",
                  "&:hover": {
                    backgroundColor: "#0f2748",
                  },
                },
                "&:hover": {
                  backgroundColor: "#f9fafb",
                },
              },
            }}
          >
            <ToggleButton value="officer">
              <PersonRounded sx={{ mr: 1, fontSize: 20 }} />
              Officer
            </ToggleButton>
            <ToggleButton value="admin">
              <AdminPanelSettingsRounded sx={{ mr: 1, fontSize: 20 }} />
              Admin
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>

        {/* Error Alert */}
        {error && (
          <Alert
            severity="error"
            sx={{ mb: 2 }}
          >
            {error}
          </Alert>
        )}

        {/* Login Form */}
        <form onSubmit={handleLogin}>
          <TextField
            label="Email Address"
            type="email"
            fullWidth
            variant="outlined"
            disabled={loading}
            size="small"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            sx={{ mb: 2 }}
          />

          <TextField
            label="Password"
            type={showPassword ? "text" : "password"}
            fullWidth
            variant="outlined"
            disabled={loading}
            size="small"
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    onClick={() => setShowPassword(!showPassword)}
                    edge="end"
                    size="small"
                    disabled={loading}
                  >
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            sx={{ mb: 3 }}
          />

          <Button
            type="submit"
            fullWidth
            variant="contained"
            disabled={loading}
            sx={{
              py: 1.2,
              fontSize: "0.95rem",
              fontWeight: 700,
              backgroundColor: "#1a3a6b",
              "&:hover": {
                backgroundColor: "#0f2748",
              },
              "&:disabled": {
                backgroundColor: "#9ca3af",
              },
            }}
          >
            {loading ? (
              <>
                <CircularProgress size={20} sx={{ mr: 1, color: '#ffffff' }} />
                Signing in...
              </>
            ) : (
              "Sign In"
            )}
          </Button>
        </form>

        {/* Divider */}
        <Box sx={{ my: 3, textAlign: "center" }}>
          <Typography variant="body2" sx={{ color: "#6b7280" }}>
            Don't have an account?
          </Typography>
        </Box>

        {/* Sign Up Link */}
        <Button
          component={Link}
          to="/auth/signup"
          fullWidth
          variant="outlined"
          disabled={loading}
          sx={{
            py: 1,
            fontSize: "0.9rem",
            fontWeight: 600,
            borderColor: "#d1d5db",
            color: "#1a3a6b",
            "&:hover": {
              borderColor: "#1a3a6b",
              backgroundColor: "#f9fafb",
            },
          }}
        >
          Create an Account
        </Button>

        {/* Manufacturer Registration */}
        <Box
          sx={{
            mt: 3,
            p: 2,
            backgroundColor: "#f9fafb",
            borderRadius: "6px",
            border: "1px solid #e5e7eb",
            textAlign: "center",
          }}
        >
          <Typography variant="body2" sx={{ color: "#6b7280", mb: 1 }}>
            Are you a manufacturer or device owner?
          </Typography>
          <Button
            component={Link}
            to="/register-device"
            variant="outlined"
            size="small"
            sx={{
              borderColor: "#d1d5db",
              color: "#374151",
              fontWeight: 600,
              "&:hover": {
                borderColor: "#374151",
                backgroundColor: "#f3f4f6",
              },
            }}
          >
            Register Your Device
          </Button>
        </Box>
      </Paper>
    </Box>
  );
};

export default LoginPage;
