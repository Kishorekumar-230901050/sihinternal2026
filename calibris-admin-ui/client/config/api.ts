// client/config/api.ts
// API configuration for frontend
// Automatically uses correct URL based on environment

// Get API base URL from environment variable or use localhost for development
export const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

// WebSocket URL (for Socket.IO connection)
export const WS_URL = import.meta.env.VITE_WS_URL || 'http://localhost:3000';

// Helper function to build API URLs
export const buildApiUrl = (endpoint: string): string => {
  // Remove leading slash if present
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint.slice(1) : endpoint;
  return `${API_BASE_URL}/${cleanEndpoint}`;
};

// Log configuration in development
if (import.meta.env.DEV) {
  console.log('🔧 API Configuration:');
  console.log(`  API URL: ${API_BASE_URL}`);
  console.log(`  WebSocket URL: ${WS_URL}`);
}
