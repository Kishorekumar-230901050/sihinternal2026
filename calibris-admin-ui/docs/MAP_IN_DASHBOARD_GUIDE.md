# Map in Dashboard - Test Guide

## ✅ Changes Made

1. **Removed Map from Navbar**
   - Map link no longer appears in navigation
   - Navigation now shows: Dashboard | Devices | Audit | Admin (if admin)

2. **Moved Map to Dashboard**
   - Map now displays inside the Dashboard with the title "Device Locations"
   - Shows pins for ALL devices with valid coordinates
   - Map takes up 2/3 of the dashboard width
   - Recent events list on the right side

3. **Fixed Map Visibility**
   - Added proper container sizing with flex layout
   - Set minimum height of 480px for map
   - Added overflow hidden to prevent layout issues
   - Map now initializes properly inside the dashboard layout

## 🧪 How to Test

### Step 1: Login
```
Go to http://localhost:8080/auth/login
Email: 11kaviya11@gmail.com
Password: [your password]
Role: Select "Admin"
Click Sign In
```

### Step 2: View Dashboard
```
You should see:
✓ Dashboard page loads
✓ Statistics cards at top (Total Devices, Online, Offline, Tampered, Drifted)
✓ Map section with title "Device Locations"
✓ Colored device pins visible on the map
✓ Recent events list on the right
```

### Step 3: Verify Map Pins
```
Expected pins:
- Red pins = Tampered devices
- Orange pins = Drifted devices  
- Green pins = Online devices
- Gray pins = Offline devices

Device locations (should be visible):
- Mumbai (19.07°N, 72.87°E) - Red
- Bengaluru (12.97°N, 77.59°E) - Orange
- Chennai (13.08°N, 80.27°E) - Red
- Delhi (28.61°N, 77.20°E) - Red
- Hyderabad (17.36°N, 78.47°E) - Green
- Kolkata (22.57°N, 88.36°E) - Green
- Pune (18.52°N, 73.86°E) - Green
- Ahmedabad (23.02°N, 72.57°E) - Green
- Jaipur (26.91°N, 75.78°E) - Green
- Lucknow (26.85°N, 80.94°E) - Green
```

### Step 4: Interact with Map
```
1. Hover over any pin → Device info popup should appear
2. Click on pin → Should navigate to Devices page with that device selected
3. Zoom in/out → Map should respond smoothly
4. Drag map → Should pan smoothly
```

### Step 5: Verify Navbar
```
Click navigation items:
✓ Dashboard → Shows map and statistics
✓ Devices → Shows device list and details
✓ Audit → Shows audit logs
✓ Admin → Shows admin panel (if logged in as admin)
✓ No Map link visible in navbar
```

## 🎨 Visual Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  Calibris  Dashboard │ Devices │ Audit │ Admin      [Avatar]   │
├─────────────────────────────────────────────────────────────────┤
│                        Dashboard                                 │
│                                                                  │
│ [Total] [Online] [Offline] [Tampered] [Drifted]                │
│                                                                  │
│ ┌──────────────────────────────────┐ ┌────────────────────┐   │
│ │   Device Locations              │ │  Recent Events     │   │
│ │   (MAP WITH COLORED PINS)        │ │  [Event List]      │   │
│ │   ┌──────────────────────────┐  │ │                    │   │
│ │   │     🗺️ Google Map         │  │ │                    │   │
│ │   │   🔴 🔴 🟠 🟢 🟢         │  │ │                    │   │
│ │   │   (colored pins)          │  │ │                    │   │
│ │   └──────────────────────────┘  │ │                    │   │
│ └──────────────────────────────────┘ └────────────────────┘   │
│                                                                  │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ Unattended Events  [Tamper Events] [Drift Events]        │   │
│ │ [Table with events]                                      │   │
│ └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔧 Technical Changes

### Files Modified:

1. **client/components/Navbar.tsx**
   - Removed `{ to: "/map", label: "Map" }` from links array
   - Navigation now only shows: Dashboard, Devices, Audit, Admin (conditional)

2. **client/pages/Dashboard.tsx**
   - Removed filter logic for tampered/drifted devices only
   - Now passes ALL devices to MapView
   - Added "Device Locations" title above map
   - Updated container styling for proper flex layout
   - Set minimum heights to ensure map is visible

3. **client/App.tsx**
   - Removed `import MapPage from "@/pages/MapPage"`
   - Removed `<Route path="/map" element={<PrivateRoute><MapPage /></PrivateRoute>} />`

### MapView Component (unchanged):
- Still handles all the map initialization logic
- Automatically creates markers for all devices with valid coordinates
- Color-codes pins based on device status
- Shows device info on hover
- Navigates to device details on click

## ✨ Features

- **All Devices Visible**: Map shows pins for all devices, not just tampered/drifted
- **Color-Coded Status**: 
  - 🔴 Red = Tampered
  - 🟠 Orange = Drifted
  - 🟢 Green = Online
  - ⚫ Gray = Offline
- **Interactive Pins**: Hover for info, click to navigate
- **Responsive Layout**: Works on mobile and desktop
- **No Separate Page**: Map integrated into dashboard for faster access

## 🐛 If Map Pins Still Not Visible

1. **Check browser console** (F12 → Console)
   - Look for Google Maps API errors
   - Check if VITE_GOOGLE_MAPS_KEY is loaded

2. **Verify devices have coordinates**
   ```
   Open console and paste:
   > JSON.parse(localStorage.getItem('calibris_devices')).slice(0,3).map(d => ({id: d.id, lat: d.lat, lng: d.lng}))
   
   Should show devices with lat/lng values
   ```

3. **Check map container size**
   ```
   Open DevTools (F12) → Elements
   Find the map container div
   Check that it has width > 0 and height > 0
   ```

4. **Refresh page**
   - Hard refresh: Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   - Clear localStorage: Console → `localStorage.clear()`
   - Reload page

## 📊 Device Coordinates (Hardcoded in mock.ts)

All devices have valid lat/lng coordinates defined:
- Device 10001: 19.0760, 72.8777 (Mumbai)
- Device 10002: 12.9716, 77.5946 (Bengaluru)
- Device 10003: 13.0827, 80.2707 (Chennai)
- Device 10004: 28.6139, 77.2090 (Delhi)
- Device 10005: 17.3850, 78.4867 (Hyderabad)
- Device 10006: 22.5726, 88.3639 (Kolkata)
- Device 10007: 18.5204, 73.8567 (Pune)
- Device 10008: 23.0225, 72.5714 (Ahmedabad)
- Device 10009: 26.9124, 75.7873 (Jaipur)
- Device 10010: 26.8467, 80.9462 (Lucknow)

## ✅ Success Criteria

- [ ] Navbar has NO Map link
- [ ] Dashboard shows map with title "Device Locations"
- [ ] Map container is visible and properly sized
- [ ] All device pins are visible on the map
- [ ] Pins are color-coded by status (red/orange/green/gray)
- [ ] Hovering over pins shows device info
- [ ] Clicking pins navigates to device details
- [ ] Map is responsive on mobile and desktop
- [ ] No console errors related to map or mapview
- [ ] Build completes successfully with no errors

---

**You're all set!** The map has been moved to the dashboard and should now display all device locations with colored pins. 🗺️
