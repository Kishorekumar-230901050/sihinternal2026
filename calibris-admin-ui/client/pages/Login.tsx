// client/pages/Login.tsx
import React, { useState } from "react";
import {
  Box,
  TextField,
  Button,
  Paper,
  Typography,
  Alert,
  Avatar,
  InputAdornment,
  IconButton
} from "@mui/material";
import LockRounded from "@mui/icons-material/LockRounded";
import Visibility from "@mui/icons-material/Visibility";
import VisibilityOff from "@mui/icons-material/VisibilityOff";
import { useAuth } from "@/context/AuthContext";
import { useNavigate } from "react-router-dom";

const Login: React.FC = () => {
  const { login } = useAuth();
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errText, setErrText] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e?: React.FormEvent) => {
    e?.preventDefault();
    setErrText(null);
    setLoading(true);
    const result = await login(email.trim(), password, "officer");
    setLoading(false);
    if (!result.ok) {
      setErrText(result.error || "Login failed");
      return;
    }
    // success
    navigate("/");
  };

  return (
    <Box
      sx={{
        minHeight: "calc(100vh - 80px)", // leave space for navbar
        background: "#f3f4f6",
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        padding: 2,
      }}
    >
      <Paper
        elevation={3}
        sx={{
          width: 420,
          padding: 5,
          background: "#ffffff",
          color: "white",
          borderRadius: "12px",
          border: "1px solid #2a3d6a",
        }}
      >
        <Box sx={{ textAlign: "center", mb: 2 }}>
          <Avatar sx={{ bgcolor: "#0EA5E9", width: 64, height: 64, margin: "auto" }}>
            <LockRounded />
          </Avatar>
          <Typography variant="h5" sx={{ mt: 2 }}>
            Sign in to Calibris
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.8 }}>
            Enter your email and password
          </Typography>
        </Box>

        {errText && <Alert severity="error" sx={{ mb: 2 }}>{errText}</Alert>}

        <form onSubmit={handleLogin}>
          <TextField
            label="Email"
            fullWidth
            variant="filled"
            InputProps={{ disableUnderline: true }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="email"
          />

          <TextField
            label="Password"
            fullWidth
            variant="filled"
            type={showPassword ? "text" : "password"}
            InputProps={{
              disableUnderline: true,
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton
                    aria-label={showPassword ? "Hide password" : "Show password"}
                    onClick={() => setShowPassword((s) => !s)}
                    edge="end"
                    size="large"
                  >
                    {showPassword ? <VisibilityOff /> : <Visibility />}
                  </IconButton>
                </InputAdornment>
              ),
            }}
            sx={{ mb: 2, background: "rgba(255,255,255,0.06)", borderRadius: 1 }}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
          />

          <Button
            type="submit"
            fullWidth
            variant="contained"
            sx={{ background: "#0EA5E9", mt: 1 }}
            disabled={loading}
          >
            {loading ? "Signing in..." : "Sign in"}
          </Button>
        </form>
      </Paper>
    </Box>
  );
};

export default Login;
