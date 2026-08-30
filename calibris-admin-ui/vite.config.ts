import { defineConfig, Plugin } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { fileURLToPath, pathToFileURL } from "url";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 8080,
    fs: {
      allow: ["./", "./client", "./shared"],
      deny: [".env", ".env.*", "*.{crt,pem}", "**/.git/**", "server/**"],
    },
  },
  build: {
    outDir: "dist/spa",
  },
  plugins: [react(), expressPlugin()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./client"),
      "@shared": path.resolve(__dirname, "./shared"),
    },
  },
}));

function expressPlugin(): Plugin {
  return {
    name: "express-plugin",
    apply: "serve", // Only apply during development (serve mode)
    async configureServer(server) {
      // Lazy import with runtime path so build-time bundling does not try to resolve server code
      // Use Vite to transform the TypeScript file
      try {
        const serverPath = path.join(process.cwd(), "server", "index.ts");
        const { createServer: createExpressServer } = await server.ssrLoadModule("/server/index.ts");
        const app = createExpressServer();
        server.middlewares.use(app);
      } catch (error) {
        console.error("Failed to load Express server:", error);
      }
    },
  };
}
