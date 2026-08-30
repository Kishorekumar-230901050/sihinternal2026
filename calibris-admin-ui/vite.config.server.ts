import { defineConfig } from "vite";
import path from "path";

// Server build configuration
export default defineConfig({
  build: {
    lib: {
      // Use cwd to ensure absolute path resolves in Railway/Nixpacks builds
      entry: path.resolve(process.cwd(), "server/node-build.ts"),
      name: "server",
      fileName: "production",
      formats: ["es"],
    },
    outDir: "dist/server",
    target: "node22",
    ssr: true,
    rollupOptions: {
      external: (id) => {
        // Externalize all node_modules
        if (id.includes('node_modules')) return true;
        // Externalize Node.js built-ins
        const builtins = ['fs', 'path', 'url', 'http', 'https', 'os', 'crypto', 'stream', 'util', 'events', 'buffer', 'querystring', 'child_process'];
        if (builtins.includes(id)) return true;
        // Externalize specific packages
        const packages = ['express', 'cors', 'dotenv', 'pg', 'zod'];
        if (packages.some(pkg => id === pkg || id.startsWith(pkg + '/'))) return true;
        return false;
      },
      output: {
        format: "es",
        entryFileNames: "[name].mjs",
      },
    },
    minify: false, // Keep readable for debugging
    sourcemap: true,
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./client"),
      "@shared": path.resolve(__dirname, "./shared"),
    },
  },
  define: {
    "process.env.NODE_ENV": '"production"',
  },
});
