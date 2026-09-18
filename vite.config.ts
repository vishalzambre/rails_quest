import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

export default defineConfig({
  plugins: [RubyPlugin()],
  build: {
    target: "es2018",
    sourcemap: false,
    chunkSizeWarningLimit: 900
  },
  server: {
    host: "0.0.0.0",
    port: 3036,
    strictPort: true,
    hmr: {
      host: "localhost",
      clientPort: 3036
    }
  }
})
