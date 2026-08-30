// client/components/Navbar.tsx
import React from "react";
import {
  AppBar,
  Toolbar,
  Box,
  Button,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Avatar,
  Menu,
  MenuItem,
  Divider,
  Typography,
} from "@mui/material";

import MenuIcon from '@mui/icons-material/Menu';
import NotificationsNoneIcon from '@mui/icons-material/NotificationsNone';
import { Link, useLocation, useNavigate } from "react-router-dom";

import { useAuth } from "@/context/AuthContext";

// Navigation links
const links = [
  { to: "/", label: "Dashboard" },
  { to: "/devices", label: "Devices" },
  { to: "/audit", label: "Audit" },
];

export default function Navbar() {
  const [open, setOpen] = React.useState(false);
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);

  const location = useLocation();
  const navigate = useNavigate();

  const { user, logout } = useAuth();

  const initials = user
    ? user.displayName
        .split(" ")
        .map((n) => n.charAt(0))
        .join("")
        .toUpperCase()
    : "U";

  const avatarMenuOpen = Boolean(anchorEl);

  const handleAvatarClick = (e: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(e.currentTarget);
  };

  const handleMenuClose = () => setAnchorEl(null);

  const handleLogout = async () => {
    handleMenuClose();
    await logout();
    navigate("/auth/login");
  };

  // Hide navbar on login-related pages
  const hideNavbar =
    location.pathname.startsWith("/auth/login") ||
    location.pathname.startsWith("/auth/signup") ||
    location.pathname.startsWith("/auth/verify-otp");

  if (hideNavbar) return null;

  return (
    <>
      {/* ── Tricolor Stripe ── */}
      <div className="tricolor-stripe">
        <div className="saffron" />
        <div className="white" />
        <div className="green" />
      </div>

      {/* ── Government Header Bar ── */}
      <AppBar
        position="sticky"
        className="top-nav"
        sx={{
          height: 64,
          background: '#1a3a6b',
          boxShadow: '0 1px 3px rgba(0,0,0,0.12)',
          borderBottom: 'none',
        }}
      >
        <Toolbar
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            minHeight: 64,
            px: 2,
          }}
        >
          {/* LEFT BLOCK — brand + links */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: { xs: 1, md: 2.5 },
              flexShrink: 0,
            }}
          >
            {/* Mobile menu button */}
            <Box sx={{ display: { xs: 'block', md: 'none' } }}>
              <IconButton aria-label="open menu" onClick={() => setOpen(true)} size="medium">
                <MenuIcon sx={{ color: 'rgba(255,255,255,0.9)' }} />
              </IconButton>
            </Box>

            {/* Brand block */}
            <Box
              component={Link}
              to="/"
              sx={{
                display: 'flex',
                flexDirection: 'column',
                textDecoration: 'none',
                color: '#ffffff',
                lineHeight: 1.2,
              }}
            >
              <Typography
                sx={{
                  fontWeight: 800,
                  fontSize: { xs: 15, md: 17 },
                  letterSpacing: '0.02em',
                  color: '#ffffff',
                }}
              >
                CALIBRIS
              </Typography>
              <Typography
                sx={{
                  fontSize: { xs: 9, md: 10 },
                  fontWeight: 500,
                  color: 'rgba(255,255,255,0.7)',
                  letterSpacing: '0.04em',
                  display: { xs: 'none', sm: 'block' },
                }}
              >
                भारत सरकार · Dept. of Legal Metrology
              </Typography>
            </Box>

            {/* Desktop Links */}
            <Box sx={{ display: { xs: 'none', md: 'flex' }, gap: 0.5, ml: 2 }}>
              {links.map((l) => {
                const isActive = location.pathname === l.to;
                return (
                  <Button
                    key={l.to}
                    component={Link}
                    to={l.to}
                    sx={{
                      color: isActive ? '#ffffff' : 'rgba(255,255,255,0.75)',
                      textTransform: 'none',
                      fontWeight: isActive ? 700 : 600,
                      fontSize: 14,
                      borderBottom: isActive ? '2px solid #ffffff' : '2px solid transparent',
                      borderRadius: 0,
                      paddingBottom: '4px',
                      px: 1.5,
                      '&:hover': { color: '#ffffff', backgroundColor: 'rgba(255,255,255,0.08)' },
                    }}
                  >
                    {l.label}
                  </Button>
                );
              })}

              {/* Admin only */}
              {user?.role === "admin" && (
                <Button
                  component={Link}
                  to="/admin"
                  sx={{
                    color: location.pathname === "/admin" ? '#ffffff' : 'rgba(255,255,255,0.75)',
                    textTransform: 'none',
                    fontWeight: location.pathname === "/admin" ? 700 : 600,
                    fontSize: 14,
                    borderBottom: location.pathname === "/admin" ? '2px solid #ffffff' : '2px solid transparent',
                    borderRadius: 0,
                    paddingBottom: '4px',
                    px: 1.5,
                    '&:hover': { color: '#ffffff', backgroundColor: 'rgba(255,255,255,0.08)' },
                  }}
                >
                  Admin
                </Button>
              )}
            </Box>
          </Box>

          {/* RIGHT SIDE — notifications + avatar */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1,
              flexShrink: 0,
            }}
          >
            <IconButton aria-label="notifications">
              <NotificationsNoneIcon sx={{ color: 'rgba(255,255,255,0.8)' }} />
            </IconButton>

            {/* Avatar Menu */}
            <IconButton onClick={handleAvatarClick}>
              <Avatar
                sx={{
                  width: 34,
                  height: 34,
                  bgcolor: 'rgba(255,255,255,0.2)',
                  color: '#ffffff',
                  fontWeight: 700,
                  fontSize: 14,
                }}
              >
                {initials}
              </Avatar>
            </IconButton>

            <Menu
              anchorEl={anchorEl}
              open={avatarMenuOpen}
              onClose={handleMenuClose}
              PaperProps={{
                sx: {
                  mt: 1.5,
                  background: '#ffffff',
                  color: '#111827',
                  border: '1px solid #d1d5db',
                  boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                },
              }}
            >
              {user && (
                <>
                  <MenuItem disabled>
                    <Box>
                      <div style={{ fontWeight: 600, color: '#111827' }}>{user.displayName}</div>
                      <div style={{ fontSize: "0.85em", color: '#6b7280', textTransform: "capitalize" }}>
                        {user.role}
                      </div>
                    </Box>
                  </MenuItem>
                  <Divider sx={{ borderColor: '#e5e7eb' }} />
                </>
              )}

              <MenuItem onClick={handleLogout} sx={{ color: '#111827' }}>
                Logout
              </MenuItem>
            </Menu>
          </Box>
        </Toolbar>
      </AppBar>

      {/* MOBILE DRAWER */}
      <Drawer open={open} onClose={() => setOpen(false)} anchor="left">
        <Box sx={{ width: 260, background: '#1a3a6b', height: '100%', pt: 2 }} role="presentation">
          <Box sx={{ px: 2, pb: 2, borderBottom: '1px solid rgba(255,255,255,0.15)' }}>
            <Typography sx={{ color: '#ffffff', fontWeight: 800, fontSize: 16 }}>
              CALIBRIS
            </Typography>
            <Typography sx={{ color: 'rgba(255,255,255,0.6)', fontSize: 10, mt: 0.5 }}>
              भारत सरकार · Dept. of Legal Metrology
            </Typography>
          </Box>
          <List>
            {links.map((l) => (
              <ListItem key={l.to} disablePadding>
                <ListItemButton
                  component={Link}
                  to={l.to}
                  onClick={() => setOpen(false)}
                  selected={location.pathname === l.to}
                  sx={{
                    '&.Mui-selected': {
                      backgroundColor: 'rgba(255,255,255,0.12)',
                    },
                  }}
                >
                  <ListItemText
                    primary={l.label}
                    primaryTypographyProps={{
                      sx: {
                        color: location.pathname === l.to ? '#ffffff' : 'rgba(255,255,255,0.8)',
                        fontWeight: 600,
                        fontSize: 14,
                      },
                    }}
                  />
                </ListItemButton>
              </ListItem>
            ))}

            {user?.role === "admin" && (
              <ListItem disablePadding>
                <ListItemButton
                  component={Link}
                  to="/admin"
                  onClick={() => setOpen(false)}
                >
                  <ListItemText
                    primary="Admin"
                    primaryTypographyProps={{
                      sx: { color: 'rgba(255,255,255,0.8)', fontWeight: 600, fontSize: 14 },
                    }}
                  />
                </ListItemButton>
              </ListItem>
            )}
          </List>
        </Box>
      </Drawer>
    </>
  );
}
