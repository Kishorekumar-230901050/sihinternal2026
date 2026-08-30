import React, { useMemo, useState, useEffect } from "react";
import StoreContext from "./StoreContext";
import { Filters, UserInfo } from "./types";
import { auditLogs, devices as mockDevices, events as mockEvents, users as mockUsers } from "@/data/mock";
import { API_BASE_URL } from "@/config/api";

interface Props {
  children: React.ReactNode;
}

const defaultFilters: Filters = {
  search: "",
  status: "All",
  officer: "All",
  location: "All",
  date: "",
  eventType: "All",
};

export default function StoreProvider({ children }: Props) {
  const [devices, setDevices] = useState<any[]>([]);
  const [events, setEvents] = useState<any[]>([]); // Now fetched from database
  const [users, setUsers] = useState(mockUsers || []);
  const [audit, setAudit] = useState(auditLogs || []);
  const [loading, setLoading] = useState(true);

  // selected device default: latest tampered device if available
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null);

  const [filters, setFiltersState] = useState<Filters>(defaultFilters);

  // Fetch devices from API on mount
  useEffect(() => {
    const fetchDevices = async () => {
      try {
        setLoading(true);
        const response = await fetch(`${API_BASE_URL}/devices`, {
          headers: {
            "ngrok-skip-browser-warning": "true",
          },
        });

        if (!response.ok) {
          console.warn("API fetch failed, using mock data");
          setDevices(mockDevices || []);
          setLoading(false);
          return;
        }

        const data = await response.json();
        console.log("✅ Fetched devices from API:", data);

        // Transform API response (snake_case) to match frontend format (camelCase)
        const transformedDevices = data.map((d: any) => ({
          id: d.id || d.device_id,
          deviceType: d.device_type || d.deviceType,
          owner: d.owner,
          status: d.status,
          lastUpdate: d.last_update || d.lastUpdate,
          location: d.location,
          lat: d.latitude || d.lat,
          lng: d.longitude || d.lng,
          latitude: d.latitude, // Keep both for compatibility
          longitude: d.longitude,
          city: d.city,
          state: d.state,
          tamperType: d.tamper_type || d.tamperType,
          tamperTime: d.tamper_time || d.tamperTime,
          tamperDetails: d.tamper_details || d.tamperDetails,
          drift: d.drift,
        }));

        console.log("✅ Transformed devices:", transformedDevices);
        console.log("📍 GPS Data check:", transformedDevices.map(d => ({
          id: d.id,
          lat: d.lat,
          lng: d.lng,
          latitude: d.latitude,
          longitude: d.longitude
        })));

        // Use ONLY real database data (no mock data)
        setDevices(transformedDevices);

        // Auto-select first tampered/safe_mode device
        const tamperedDevice = transformedDevices.find((d: any) =>
          d.status === "Tampered" || d.status === "safe_mode"
        );
        if (tamperedDevice) {
          setSelectedDeviceId(tamperedDevice.id);
        } else if (transformedDevices.length > 0) {
          setSelectedDeviceId(transformedDevices[0].id);
        }
      } catch (error) {
        console.error("❌ Error fetching devices:", error);
        // Fallback to mock data on error
        setDevices(mockDevices || []);
      } finally {
        setLoading(false);
      }
    };

    // Also fetch recent events from database
    const fetchEvents = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/devices/recent-activities?limit=50`, {
          headers: {
            "ngrok-skip-browser-warning": "true",
          },
        });

        if (response.ok) {
          const data = await response.json();
          // Transform to match expected format
          const transformedEvents = (data.activities || []).map((a: any) => ({
            id: a.id,
            deviceId: a.device_id,
            type: 'tamper', // All tamper events
            timestamp: a.event_time,
            severity: a.severity,
            tamperType: a.tamper_type,
            details: a.details,
          }));
          setEvents(transformedEvents);
        }
      } catch (error) {
        console.error("❌ Error fetching events:", error);
      }
    };

    fetchDevices();
    fetchEvents();

    // Refresh devices and events every 30 seconds
    const interval = setInterval(() => {
      fetchDevices();
      fetchEvents();
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  // Auth user state: initialize from localStorage so login persists across reloads
  const [user, setUserState] = useState<UserInfo | null>(() => {
    try {
      const raw = localStorage.getItem("calibris_user");
      return raw ? (JSON.parse(raw) as UserInfo) : null;
    } catch {
      return null;
    }
  });

  // Persist user to localStorage on change
  useEffect(() => {
    try {
      if (user) localStorage.setItem("calibris_user", JSON.stringify(user));
      else localStorage.removeItem("calibris_user");
    } catch {
      // ignore storage errors
    }
  }, [user]);

  const addEvent = (ev: any) => {
    setEvents((prev) => [ev, ...prev]);
  };

  const setFilters = (patch: Partial<Filters>) => {
    setFiltersState((prev) => ({ ...prev, ...patch }));
  };

  const clearFilters = () => {
    setFiltersState(defaultFilters);
    const latestTampered = (devices || [])
      .filter((d: any) => d.status === "Tampered")
      .sort((a: any, b: any) => new Date(b.lastUpdate).getTime() - new Date(a.lastUpdate).getTime())[0];
    setSelectedDeviceId(latestTampered ? latestTampered.id : null);
  };

  // Expose setUser to allow Login page / Navbar logout to update auth state
  const setUser = (u: UserInfo | null) => {
    setUserState(u);
  };

  const value = useMemo(
    () => ({
      devices,
      events,
      users,
      audit,
      user,
      filters,
      selectedDeviceId,
      setSelectedDeviceId,
      setFilters,
      clearFilters,
      addEvent,
      setUser,
    }),
    [devices, events, users, audit, user, filters, selectedDeviceId],
  );

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}
