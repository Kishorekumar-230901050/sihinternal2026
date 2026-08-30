// client/components/MapView.tsx
import React, { useEffect, useRef, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useStore } from "@/context/StoreContext";

/**
 * Robust MapView (Google Maps)
 *
 * - Accepts props: height, devices (optional), statusFilter (optional)
 * - Ensures map initializes after container has positive size
 * - Uses IntersectionObserver + ResizeObserver + retry timers
 * - Tracks mapReady state and creates markers when mapReady || devices changes
 * - Rebuilds markers in-place (clear old ones, add new ones)
 *
 * Usage: <MapView height={360} devices={filtered} />
 */

type Props = {
  height?: number | string;
  devices?: any[]; // filtered list from page
  statusFilter?: string[]; // optional
};

const INDIA_CENTER = { lat: 20.5937, lng: 78.9629 };

function markerSvgDataUrl(color = "#9E9E9E") {
  const svg = `<?xml version="1.0" encoding="utf-8"?><svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24"><path fill="${color}" d="M12 2C8.14 2 5 5.14 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.86-3.14-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5S10.62 6.5 12 6.5s2.5 1.12 2.5 2.5S13.38 11.5 12 11.5z"/></svg>`;
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`;
}

function escapeHtml(s: string) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export default function MapView(props: Props) {
  const { height = 520, devices: devicesProp, statusFilter } = props;
  const { devices: devicesFromStore = [], setSelectedDeviceId } = useStore();
  const navigate = useNavigate();

  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<google.maps.Map | null>(null);
  const markersRef = useRef<google.maps.Marker[]>([]);
  const infoWindowsRef = useRef<google.maps.InfoWindow[]>([]);
  const roRef = useRef<ResizeObserver | null>(null);
  const ioRef = useRef<IntersectionObserver | null>(null);
  const initAttemptsRef = useRef(0);

  const [mapReady, setMapReady] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // resolve devices (prop preferred)
  const devices = useMemo(() => {
    const list = Array.isArray(devicesProp) ? devicesProp : Array.isArray(devicesFromStore) ? devicesFromStore : [];
    if (!Array.isArray(statusFilter) || statusFilter.length === 0) return list;
    const allowed = statusFilter.map((s) => String(s).toLowerCase());
    return list.filter((d: any) => {
      const s = String(d.status ?? "").toLowerCase();
      return allowed.some((a) => s.includes(a));
    });
  }, [devicesProp, devicesFromStore, statusFilter]);

  // load Google Maps SDK once
  useEffect(() => {
    const key = (import.meta.env as any).VITE_PUBLIC_GOOGLE_MAPS_KEY;
    console.log("🗺️ MapView: Checking Google Maps API key...", key ? "✓ Found" : "✗ Missing");
    if (!key) {
      console.error("VITE_PUBLIC_GOOGLE_MAPS_KEY missing. Map won't load.");
      setIsLoading(false);
      return;
    }
    if ((window as any).google && (window as any).google.maps) {
      console.log("🗺️ MapView: Google Maps SDK already loaded");
      setIsLoading(false);
      return;
    }
    const id = "google-maps-js";
    if (document.getElementById(id)) {
      console.log("🗺️ MapView: Google Maps script tag already exists");
      setIsLoading(false);
      return;
    }
    console.log("🗺️ MapView: Loading Google Maps SDK...");
    const s = document.createElement("script");
    s.id = id;
    s.src = `https://maps.googleapis.com/maps/api/js?key=${encodeURIComponent(key)}`;
    s.async = true;
    s.defer = true;
    s.onload = () => {
      console.log("🗺️ MapView: Google Maps SDK loaded successfully");
      setIsLoading(false);
    };
    s.onerror = () => {
      console.error("Failed to load Google Maps script");
      setIsLoading(false);
    };
    document.head.appendChild(s);
  }, []);

  // helper: try initialize map when container has non-zero size & SDK loaded
  const tryInitMap = () => {
    const el = containerRef.current;
    if (!el) {
      console.log("🗺️ MapView: Container ref not available");
      return false;
    }
    if (!(window as any).google || !(window as any).google.maps) {
      console.log("🗺️ MapView: Google Maps SDK not loaded yet");
      return false;
    }
    const rect = el.getBoundingClientRect();
    console.log("🗺️ MapView: Container size:", rect.width, "x", rect.height);
    if (rect.width === 0 || rect.height === 0) {
      console.log("🗺️ MapView: Container has zero size, waiting...");
      return false;
    }
    if (!mapRef.current) {
      console.log("🗺️ MapView: Initializing Google Map...");
      mapRef.current = new google.maps.Map(el, {
        center: INDIA_CENTER,
        zoom: 5,
        mapTypeControl: false,
        streetViewControl: false,
      });
      console.log("🗺️ MapView: Map initialized successfully!");
      setMapReady(true);
    } else {
      setMapReady(true);
    }
    return true;
  };

  // trigger resize + fit helper
  const triggerResizeAndFit = (map: google.maps.Map | null, fit?: () => void) => {
    try {
      if (!map) return;
      google.maps.event.trigger(map, "resize");
      if (typeof fit === "function") fit();
    } catch {}
  };

  // set up IntersectionObserver + ResizeObserver + polling to initialize map reliably
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    // IntersectionObserver: initialize when in viewport
    if ("IntersectionObserver" in window) {
      ioRef.current = new IntersectionObserver((entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting) {
            tryInitMap();
            setTimeout(() => triggerResizeAndFit(mapRef.current), 120);
          }
        }
      }, { threshold: 0.01 });
      ioRef.current.observe(el);
    }

    // ResizeObserver: when container size changes, try init and trigger resize
    if ("ResizeObserver" in window) {
      roRef.current = new (window as any).ResizeObserver(() => {
        tryInitMap();
        setTimeout(() => triggerResizeAndFit(mapRef.current), 80);
      });
      roRef.current.observe(el);
    }

    // fallback polling (for environments where script loads late)
    const poll = setInterval(() => {
      initAttemptsRef.current++;
      const ok = tryInitMap();
      if (ok || initAttemptsRef.current > 20) {
        clearInterval(poll);
        setTimeout(() => triggerResizeAndFit(mapRef.current), 160);
      }
    }, 120);

    // attempt once on window load too
    const onLoad = () => {
      tryInitMap();
      setTimeout(() => triggerResizeAndFit(mapRef.current), 180);
    };
    window.addEventListener("load", onLoad);

    return () => {
      clearInterval(poll);
      window.removeEventListener("load", onLoad);
      try {
        if (ioRef.current) { ioRef.current.disconnect(); ioRef.current = null; }
        if (roRef.current) { roRef.current.disconnect(); roRef.current = null; }
      } catch {}
    };
  }, []);

  // clear markers helper
  const clearMarkers = () => {
    try {
      markersRef.current.forEach((m) => m.setMap(null));
    } catch {}
    markersRef.current = [];
    try {
      infoWindowsRef.current.forEach((iw) => { try { iw.close(); } catch {} });
    } catch {}
    infoWindowsRef.current = [];
  };

  // Build markers whenever mapReady becomes true OR devices change.
  useEffect(() => {
    const map = mapRef.current;
    if (!map || !mapReady) {
      // Try to ensure map gets initialized; observers/polling will set mapReady eventually
      console.log("🗺️ MapView: Map not ready yet, attempting init...");
      tryInitMap();
      return;
    }

    console.log(`🗺️ MapView: Building markers for ${devices.length} devices`);
    clearMarkers();

    const bounds = new google.maps.LatLngBounds();
    let anyMarker = false;

    for (const d of devices) {
      const lat = Number(d.lat ?? d.latitude ?? d.y ?? d.latitude_deg ?? NaN);
      const lng = Number(d.lng ?? d.longitude ?? d.x ?? d.longitude_deg ?? NaN);
      if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
        console.log(`🗺️ MapView: Skipping device ${d.id} - invalid coordinates:`, lat, lng);
        continue;
      }
      console.log(`🗺️ MapView: Adding marker for device ${d.id} at ${lat}, ${lng}`);

      const s = String(d.status ?? "").toLowerCase();
      let color = "#9E9E9E";
      if (s.includes("tamper") || s.includes("detected") || s.includes("tampered")) color = "#D32F2F";
      else if (s.includes("drift") || s.includes("drifted")) color = "#F59E0B";
      else if (s === "ok" || s === "online") color = "#388E3C";
      else if (s === "offline") color = "#757575";

      const marker = new google.maps.Marker({
        position: { lat, lng },
        map,
        icon: { url: markerSvgDataUrl(color), scaledSize: new google.maps.Size(32, 32) },
        title: String(d.id ?? d.product_id ?? ""),
      });

      const infoHtml = `
        <div style="max-width:320px">
          <div><strong>${escapeHtml(String(d.id ?? d.product_id ?? "(unknown)"))}</strong></div>
          <div style="color:${color};font-weight:600">${escapeHtml(String(d.status ?? ""))}</div>
          <div>${escapeHtml(String(d.location ?? ""))}</div>
        </div>
      `;
      const infoWindow = new google.maps.InfoWindow({ content: infoHtml });

      marker.addListener("mouseover", () => {
        try { infoWindow.open(map, marker); } catch {}
      });
      marker.addListener("mouseout", () => {
        try { infoWindow.close(); } catch {}
      });
      marker.addListener("click", () => {
        try { setSelectedDeviceId(d.id ?? d.product_id); } catch {}
        try { infoWindow.open(map, marker); } catch {}
        try { navigate(`/devices?serial=${encodeURIComponent(String(d.id ?? d.product_id ?? ""))}`); } catch {}
      });

      markersRef.current.push(marker);
      infoWindowsRef.current.push(infoWindow);
      try { bounds.extend({ lat, lng }); } catch {}
      anyMarker = true;
    }

    try {
      if (anyMarker) map.fitBounds(bounds);
      else {
        map.setCenter(INDIA_CENTER);
        map.setZoom(5);
      }
    } catch (e) {
      // fitBounds can fail if the map's size is temporarily 0; we'll retry below
      console.warn("fitBounds error (will retry):", e);
    }

    // retry resize+fit a few times after layout settles
    [120, 300, 700].forEach((delay) => {
      setTimeout(() => {
        try {
          google.maps.event.trigger(map, "resize");
          if (anyMarker) map.fitBounds(bounds);
        } catch {}
      }, delay);
    });

    // done
  }, [devices, mapReady]); // IMPORTANT: rebuild when mapReady is true OR devices change

  // cleanup on unmount
  useEffect(() => {
    return () => {
      clearMarkers();
      try {
        if (roRef.current) { roRef.current.disconnect(); roRef.current = null; }
        if (ioRef.current) { ioRef.current.disconnect(); ioRef.current = null; }
      } catch {}
    };
  }, []);

  // Compute height values - ensure minimum height for percentage-based heights
  const computedHeight = typeof height === "number" ? `${height}px` : height;
  const minHeightValue = typeof height === "number" ? `${height}px` : "400px";

  return (
    <div style={{
      width: "100%",
      height: computedHeight,
      minHeight: minHeightValue,
      borderRadius: 8,
      overflow: "hidden",
      position: "relative",
      backgroundColor: "#1a1a2e"
    }}>
      {isLoading && (
        <div style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          color: "#fff",
          fontSize: "14px",
          zIndex: 10
        }}>
          Loading map...
        </div>
      )}
      <div
        ref={containerRef}
        style={{
          width: "100%",
          height: "100%",
          minHeight: minHeightValue
        }}
        aria-label="Device map"
      />
    </div>
  );
}
