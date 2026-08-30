# Project Documentation

## Overview
This repository implements a single-page application (SPA) with a lightweight Express server for demo API endpoints. The app focuses on device monitoring with maps, events, and admin/audit pages. The client is built with React + TypeScript, styled with Tailwind CSS and MUI, and uses Leaflet for mapping and Recharts for charts. Mock data is used in the client for rapid prototyping; the server contains placeholder/demo routes.


## Tech Stack
- Frontend
  - React (TypeScript)
  - Vite (dev tooling)
  - @mui/material (component primitives & theming)
  - Tailwind CSS (utility classes + global theme variables)
  - react-router-dom (routing)
  - react-leaflet + leaflet (interactive maps)
  - recharts (charts, used in dashboard)
  - Sonner/Toast UI (notification helpers in /client/components/ui)
  - Vitest (testing utilities present in repo)
- Backend
  - Express (TypeScript) - lightweight demo routes
  - Netlify serverless functions (netlify/functions/api.ts) for optional serverless endpoints
- Tooling
  - ESLint/TypeScript configuration via tsconfig.json
  - PostCSS (postcss.config.js)
  - Tailwind config (tailwind.config.ts)


## Repository Layout (important files)
Paths are relative to repository root.

- client/
  - App.tsx — application entry wiring (providers, theme, router). Do not modify top-level app entry unless intentionally changing global providers.
  - global.css — Tailwind import plus project CSS variables and base component classes (colors, panel, border, page-heading, grid helpers).
  - pages/
    - Index.tsx — top-level landing or default redirect route.
    - Dashboard.tsx — Dashboard view: metrics bar, full-bleed map with recent events panel, and unattended events table.
    - Devices.tsx — Devices list page: left column contains filters + devices table, right column shows selected device details (sticky on md+ with 70/30 split).
    - Map.tsx / MapPage.tsx — Map-focused page with FiltersPanel, full-width MapView, and a device table below.
    - Admin.tsx — Admin UI surface for administrative tasks (users, roles) placeholder.
    - Audit.tsx — Audit log view where actions and system events are surfaced.
    - NotFound.tsx — 404 route.
    - Auth/
      - Login.tsx — Login page, centered card layout.
      - SignUp.tsx — Signup page, centered card layout.
      - VerifyOtp.tsx — OTP verification page used for sign-up/login flows.
  - components/
    - MapView.tsx — Leaflet MapContainer wrapper that renders devices as CircleMarker pins and Popups. It computes map center and filters visible devices by props and global filters.
    - FiltersPanel.tsx — Reusable filter UI used on Map and Devices pages. Contains inputs: search (serial/model), status select, assigned officer, location (Indian cities included), and date.
    - Navbar.tsx and NavBar.tsx — Top navigation. Both exist in the tree; Navbar.tsx is the app's used navigation component. Note: historically capitalization mismatches (NavBar vs Navbar) have caused runtime errors. Ensure App.tsx imports the same symbol exported by the component file.
    - DeviceDetailsPanel.tsx — Panel showing details for the selected device (status, last seen, recent events).
    - EventsList.tsx — Compact list of recent device events used in dashboard and panels.
    - LoginForm.tsx / SignupForm.tsx / OtpForm.tsx — Small form components for auth flow.
    - ui/ — UI primitives (toasts, sonner wrappers, buttons, cards, etc.). Files of note:
      - ui/toast.tsx — root toast container, lives at top of DOM under #root; contains the <ol> container for toasts.
      - ui/sonner.tsx — live region and accessibility wrappers for notifications.

- client/context/
  - StoreContext.tsx — Typed React Context export and hook (useStore) describing the shape of global state (devices, events, users, filters, selectedDeviceId, setters).
  - StoreProvider.tsx — Provider implementation that initializes state (from client/data/mock.ts) and supplies setter callbacks; memoizes context value.
  - DeviceContext.tsx — (if present) more specialized device-scoped context used by nested components.
  - types.ts — TypeScript interfaces used across client and shared types (Device, DeviceEvent, UserInfo, Filters, AuditLogRow, etc.).

- client/data/mock.ts
  - Contains arrays of mock devices, events, users, and audit logs. Includes utility helpers such as countByStatus(). Devices include Indian locations, status tags (Tampered, Drifted, Online, Offline), lat/lng coordinates, and visual attributes used by MapView.

- client/lib/utils.ts
  - Small utility helpers used across the client. Tests are located in utils.spec.ts.

- public/
  - placeholder.svg, robots.txt — static assets.

- server/
  - index.ts — Express server bootstrap (CORS and JSON middleware), loads route modules from server/routes.
  - routes/demo.ts — Demo API routes; used as placeholders for future API wiring.
  - node-build.ts — helper for node build process.

- netlify/functions/api.ts & netlify.toml
  - Serverless function used if deploying under Netlify functions. Contains light demo API handlers.

- shared/api.ts
  - Shared API type definitions between client and server, keeping request/response shapes consistent.

- Configuration
  - tailwind.config.ts — Tailwind customization and plugin registration.
  - vite.config.ts / vite.config.server.ts — Vite dev and build configuration, includes aliasing used across imports.
  - package.json — scripts and dependencies.


## Styling and Theming
- Two styling systems are used in tandem:
  1. Tailwind CSS is used for utility classes and base styles. global.css imports Tailwind directives and defines CSS variables in :root.
  2. MUI (@mui/material) provides components and a ThemeProvider (dark theme used). The app uses MUI components while overriding visuals via CSS variables and sx props where needed.

- Theme variables (global.css, :root)
  - --bg, --panel, --border, --text, --muted, --accent
  - Status colors: --ok, --danger, --warn
  - --radius for base border-radius

- Common base classes
  - .panel — used throughout for Paper/Card containers to apply consistent panel background, border and radius.
  - .page-heading — standardized H1 spacing/weight.
  - .grid-2-1 — utility grid used to present a 2fr/1fr layout on large screens (used on dashboard for map/events).

- Layout patterns
  - Full-bleed content: the main container uses full width while internal Containers apply padding to achieve full-bleed map and panels.
  - 70/30 split: Devices page uses `gridTemplateColumns: { xs: '1fr', md: '70% 30%' }` to create a left column for the table and a right column for details (sticky on md+).
  - Sticky panels: right-side details panel is positioned `position: sticky` with `top` set to account for the navbar height.


## Core Components & Behavior (functions & props)
This section summarizes key components and the important functions/props they expose.

- App.tsx
  - Wraps the app with providers: ThemeProvider (MUI), StoreProvider (context), routing (BrowserRouter), Toast providers.
  - Renders Navbar and the main container with <Routes> defined for pages. Ensure Navbar import matches its export name.

- MapView.tsx
  - Props: height?: number | string; statusFilter?: string | string[]
  - Uses react-leaflet's MapContainer, TileLayer (OpenStreetMap), CircleMarker for device pins and Popup for device details.
  - Computes `visibleDevices` via useMemo considering global filters from useStore and the component's statusFilter prop.
  - Event handlers on markers call setSelectedDeviceId and navigate to detail routes.

- FiltersPanel.tsx
  - Props: compact?: boolean
  - Reads and writes `filters` via useStore(). Inputs include search, status select, assigned officer, location select (includes Indian city options), and date selector.
  - Uses MUI TextField components with size="small" and `sx` width adjustments for compact mode.

- Navbar.tsx
  - Renders top AppBar with navigation links (Dashboard, Devices, Map, Admin, Audit), notifications button, and user avatar.
  - Responsive behavior: shows a hamburger IconButton on small screens that opens a Drawer with the same navigation links.
  - Uses useLocation() to highlight active route.

- StoreProvider.tsx / StoreContext.tsx
  - Exposes typed state: devices: Device[]; events: DeviceEvent[]; users: UserInfo[]; auditLogs: AuditLogRow[]; filters: Filters; selectedDeviceId: string | null; setters for each.
  - Initializes state from client/data/mock.ts.
  - useStore() hook performs a runtime check and returns context value.

- Auth forms (LoginForm/SignupForm/OtpForm)
  - useState for local fields, validate basic inputs, and invoke placeholder fetch calls to `POST /api/auth/*` or to the demo serverless functions.
  - On success, navigate to dashboard. OTP verification page uses a code field and calls the verification endpoint.


## API & Server placeholders
- server/routes/demo.ts and netlify/functions/api.ts contain placeholder/demo endpoints such as:
  - GET /api/ping
  - POST /api/demo or POST /api/auth/login (placeholders)

- shared/api.ts contains TypeScript shapes for requests/responses. The client currently uses mock data in the StoreProvider; to integrate a real API, wire StoreProvider setters to fetch/subscribe to backend endpoints and replace mock initialization.


## Authentication Flow (UI-level)
- Login (client/pages/Auth/Login.tsx)
  - Centered card with LoginForm component (email/serial/password fields depending on flow). Submits credentials to a placeholder API endpoint.
  - Provides link to SignUp.

- Signup (SignUp.tsx)
  - SignupForm collects name/phone/email and triggers sending an OTP via placeholder endpoint. On success, navigate to VerifyOtp.

- Verify OTP (VerifyOtp.tsx)
  - OtpForm accepts the one-time code and submits verification to placeholder endpoint. On success, the app sets the authenticated user state in useStore (or local/session storage depending on your chosen auth strategy) and navigates to Dashboard.

- AuthGuard (implicit)
  - Routes should be guarded by checking user authentication state from useStore(). If not present, redirect to /login. This is currently implemented in route definitions or should be added where necessary.


## Error Handling & Known Fixes
- NavBar vs Navbar runtime error: If App.tsx imports a named or default export but renders a differently-cased component (<NavBar /> vs <Navbar />), React throws ReferenceError. Fix: ensure the import matches the exported identifier in client/components/Navbar.tsx (or remove duplicate NavBar file) and update App.tsx to render the exported symbol.

- Leaflet CSS: If map tiles or icons do not render correctly, ensure leaflet CSS is imported in global styles or index entry (leaflet's default marker images require its CSS and correct icon asset paths). MapView merges L.Icon.Default.mergeOptions to resolve missing marker images where needed.

- Toast/Notifications accessibility: ui/toast.tsx and ui/sonner.tsx include live region wrappers for screen readers; ensure they are mounted once under root and not duplicated.

- Dev server / build checks: Use `npm run dev` and `npm run build` scripts from package.json for local verification. For debugging, follow the repository's "debugging-errors" guidance (available rule) which recommends inspecting stack traces and running type checks.


## User requests implemented (high-level)
The project has implemented or configured the following user-specified requirements:
- Indian locations included in mock devices and FiltersPanel location select options.
- Device pins use explicit status colors (Tampered => red, Drifted => orange, OK/Online => green/blue variants) applied via CircleMarker pathOptions.
- Devices page uses a responsive 70/30 layout with the details panel set to sticky at md+ breakpoints.
- Dashboard map is full-bleed within the content area and events/recent lists are placed in a 2:1 grid on large screens.
- Toast and Sonner wrappers included for in-app notifications and accessibility.


## Extending to production
- Replace mock data in client/context/StoreProvider.tsx by wiring the provider's initialization and setters to real API calls (use fetch or a query client). Move authentication into a dedicated auth provider and persist tokens securely (httpOnly cookies or secure storage depending on the backend).
- Consider connecting an MCP database integration (Neon or Supabase) to host device, event and user data. See "MCP integrations" section below.
- If deploying to Netlify or Vercel enable the respective MCP and configure build/deploy settings.


## Recommended MCP Integrations (available to suggest)
When helpful, connect one or more of these integrations via the MCP popover ([Open MCP popover](#open-mcp-popover)):
- Neon — serverless Postgres, good for production device/event storage and auth. (Step: Connect to Neon via the MCP popover.)
- Netlify — hosting and serverless functions; useful if using the existing netlify/functions handlers. (Connect to Netlify)
- Zapier — automations and notifications integrations.
- Figma — convert designs to code using Builder.io's Figma plugin (Get Plugin link in MCP Servers).
- Supabase — DB + auth + real-time subscriptions as an alternative to Neon.
- Builder.io — headless CMS and content management (Connect to Builder.io).
- Linear — issue tracking automation.
- Notion — documentation and knowledge management for project docs.
- Sentry — error monitoring and runtime error aggregation.
- Context7 — documentation lookup for frameworks used.
- Semgrep — security scanning and SAST.
- Prisma Postgres — ORM tooling for Postgres-backed deployments.

Which MCP(s) to connect depends on your next steps (database vs deployment vs monitoring). To connect MCPs, open the MCP popover in the UI and follow the provider-specific prompts.


## Developer notes & next steps
- If you plan to integrate an API: implement fetch calls in StoreProvider and migrate mock data into backend endpoints with proper pagination and filtering. Keep shared/api.ts in sync with server request/response shapes.
- If adding authentication: create an AuthProvider (separate from StoreProvider) and protect routes using an AuthGuard component that uses the auth state.
- Ensure only a single Navbar component is used; remove or consolidate duplicate NavBar/NavBar.tsx files to avoid confusion.
- Import Leaflet CSS in global entry if not already present: `import 'leaflet/dist/leaflet.css';`


## Quick reference: Important file paths
- client/App.tsx
- client/global.css
- client/pages/Dashboard.tsx
- client/pages/Devices.tsx
- client/pages/Map.tsx
- client/components/MapView.tsx
- client/components/FiltersPanel.tsx
- client/components/Navbar.tsx
- client/components/NavBar.tsx (duplicate — review)
- client/components/DeviceDetailsPanel.tsx
- client/components/EventsList.tsx
- client/components/LoginForm.tsx
- client/components/OtpForm.tsx
- client/context/StoreProvider.tsx
- client/context/StoreContext.tsx
- client/data/mock.ts
- server/index.ts
- server/routes/demo.ts
- netlify/functions/api.ts


---
This document was generated to capture the app architecture, component responsibilities, styling conventions, and practical next steps for development and deployment. If you want, I can now:
- generate a smaller developer README (shorter) or
- create a migration plan to swap mock data for a Neon/Supabase backend and implement authentication.

Choose one and I will proceed.
