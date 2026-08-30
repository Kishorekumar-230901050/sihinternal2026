// client/App.tsx
import "./global.css";

import { Toaster } from "@/components/ui/toaster";
import { createRoot } from "react-dom/client";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { CssBaseline, ThemeProvider, createTheme, Container, Box, CircularProgress } from "@mui/material";

import Navbar from "@/components/Navbar";
import DashboardPage from "@/pages/Dashboard";
import DevicesPage from "@/pages/Devices";
import AdminPage from "@/pages/Admin";
import AuditPage from "@/pages/Audit";
import NotFound from "./pages/NotFound";
import StoreProvider from "@/context/StoreProvider";
import LoginPage from "@/pages/Auth/Login";
import SignUpPage from "@/pages/Auth/SignUp";
import RegisterDevicePage from "@/pages/RegisterDevice";

import { AuthProvider, useAuth, type UserRole } from "@/context/AuthContext";

const queryClient = new QueryClient();

const theme = createTheme({
  palette: {
    mode: "light",
    background: { default: "#f3f4f6", paper: "#ffffff" },
    primary: { main: "#1a3a6b" },
    secondary: { main: "#2563eb" },
    error: { main: "#dc2626" },
    warning: { main: "#d97706" },
    success: { main: "#16a34a" },
    text: { primary: "#111827", secondary: "#6b7280" },
  },
  typography: { fontFamily: 'Inter, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial' },
  components: {
    MuiPaper: { styleOverrides: { root: { borderRadius: 6 } } },
    MuiButton: { styleOverrides: { root: { textTransform: 'none' as const, fontWeight: 600 } } },
    MuiTableCell: { styleOverrides: { root: { borderColor: '#e5e7eb' } } },
  },
});

// Loading component
const LoadingScreen: React.FC = () => (
  <Box
    sx={{
      minHeight: "100vh",
      display: "flex",
      justifyContent: "center",
      alignItems: "center",
      background: "#f3f4f6",
    }}
  >
    <CircularProgress sx={{ color: "#1a3a6b" }} />
  </Box>
);

// Role-aware private route with better type safety
interface PrivateRouteProps {
  children: JSX.Element;
  requiredRoles?: UserRole[];
}

const PrivateRoute: React.FC<PrivateRouteProps> = ({ children, requiredRoles }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  if (!user) {
    return <Navigate to="/auth/login" replace />;
  }

  // Check role-based access
  if (requiredRoles && requiredRoles.length > 0 && !requiredRoles.includes(user.role)) {
    // Redirect to dashboard if user doesn't have required role
    return <Navigate to="/" replace />;
  }

  return children;
};

const AppContent: React.FC = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <StoreProvider>
            <BrowserRouter>
              {user && <Navbar />}
              <Container maxWidth={false} sx={{ py: user ? 2 : 0, px: 0 }}>
                <Routes>
                  {/* Public / Auth Routes */}
                  <Route path="/auth/login" element={<LoginPage />} />
                  <Route path="/auth/signup" element={<SignUpPage />} />

                  {/* Public Device Registration for Manufacturers */}
                  <Route path="/register-device" element={<RegisterDevicePage />} />

                  {/* Protected Dashboard Route */}
                  <Route path="/" element={<PrivateRoute><DashboardPage /></PrivateRoute>} />

                  {/* Officer Routes (accessible to both officer and admin) */}
                  <Route path="/devices" element={<PrivateRoute><DevicesPage /></PrivateRoute>} />
                  <Route path="/audit" element={<PrivateRoute><AuditPage /></PrivateRoute>} />

                  {/* Admin-Only Routes */}
                  <Route
                    path="/admin"
                    element={
                      <PrivateRoute requiredRoles={["admin"]}>
                        <AdminPage />
                      </PrivateRoute>
                    }
                  />

                  {/* Catch-all 404 route */}
                  <Route path="*" element={<NotFound />} />
                </Routes>
              </Container>
            </BrowserRouter>
          </StoreProvider>
        </ThemeProvider>
      </TooltipProvider>
    </QueryClientProvider>
  );
};

const App = () => (
  <AuthProvider>
    <AppContent />
  </AuthProvider>
);

createRoot(document.getElementById("root")!).render(<App />);

export default App;
