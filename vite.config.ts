import { fileURLToPath } from "node:url";
import path from "path";

import UnpluginTypia from "@typia/unplugin/vite";
import react from "@vitejs/plugin-react";
import AutoImport from "unplugin-auto-import/vite";
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";

const rootPath = path.dirname(fileURLToPath(import.meta.url));

function stripCjsExportsPlugin() {
  return {
    name: "strip-cjs-exports",
    transform(code: string, id: string) {
      if (id.endsWith("routes.js")) {
        return code.replace(/^Object\.defineProperty\(exports.*$/m, "").replace(/^exports\.\w+\s*=.*$/gm, "");
      }
    },
  };
}

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
    UnpluginTypia({ cache: true }),
    AutoImport({
      imports: [{ "$app/utils/routes": [["*", "Routes"]] }],
    }),
    stripCjsExportsPlugin(),
  ],
  resolve: {
    alias: {
      $app: path.join(rootPath, "app/javascript"),
      $assets: path.join(rootPath, "app/assets"),
      $vendor: path.join(rootPath, "vendor/assets/javascripts"),
      jwplayer: path.join(rootPath, "vendor/assets/components/jwplayer-7.12.13/jwplayer"),
      "~fonts": path.join(rootPath, "app/assets/fonts"),
      "~images": path.join(rootPath, "app/assets/images"),
    },
  },
  define: {
    SSR: false,
    "process.env.NODE_ENV": JSON.stringify(process.env.NODE_ENV || "test"),
    "process.env.RAILS_ENV": JSON.stringify(process.env.RAILS_ENV || "test"),
    "process.env.PROTOCOL": JSON.stringify(process.env.PROTOCOL || "https"),
    "process.env": "{}",
  },
  css: {
    preprocessorOptions: {
      scss: {
        loadPaths: [path.join(rootPath, "app/assets")],
      },
    },
  },
});
