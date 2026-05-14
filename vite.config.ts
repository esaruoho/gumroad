import UnpluginTypia from "@typia/unplugin/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import { resolve } from "path";
import AutoImport from "unplugin-auto-import/vite";
import { defineConfig, type Plugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";

function stripCjsExportsPlugin(): Plugin {
  return {
    name: "vite-plugin-strip-cjs-exports",
    transform(code, id) {
      if (!id.endsWith("utils/routes.js")) return null;
      const cleaned = code.replace(/^\s*module\.exports\s*=\s*routes;?\s*$/mu, "");
      if (cleaned !== code) return { code: cleaned, map: null };
      return null;
    },
  };
}

function requireContextPlugin(): Plugin {
  const aliases: Record<string, string> = {
    $assets: resolve(__dirname, "app/assets"),
    $app: resolve(__dirname, "app/javascript"),
  };

  return {
    name: "vite-plugin-require-context",
    transform(code) {
      if (!code.includes("require.context")) return null;

      const pattern = /require\.context\(\s*["']([^"']+)["'](?:\s*,\s*[^,)]+)?(?:\s*,\s*[^)]+)?\s*\)/gu;

      let transformed = code;
      let match;
      while ((match = pattern.exec(code)) !== null) {
        const [fullMatch, contextPath] = match;

        let resolvedDir = contextPath;
        for (const [alias, target] of Object.entries(aliases)) {
          if (resolvedDir.startsWith(alias)) {
            resolvedDir = resolvedDir.replace(alias, target);
            break;
          }
        }

        try {
          const files = fs.readdirSync(resolvedDir);
          const entries = files
            .filter((f: string) => !f.startsWith("."))
            .map((f: string) => {
              const fullPath = resolve(resolvedDir, f);
              return `"./${f}": new URL("${fullPath}", import.meta.url).href`;
            });

          const replacement = `((function() {
  const _map = { ${entries.join(", ")} };
  const ctx = (key) => _map[key];
  ctx.keys = () => Object.keys(_map);
  return ctx;
})())`;

          transformed = transformed.replace(fullMatch, replacement);
        } catch {
          continue;
        }
      }

      if (transformed !== code) {
        return { code: transformed, map: null };
      }
      return null;
    },
  };
}

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
    stripCjsExportsPlugin(),
    requireContextPlugin(),
    UnpluginTypia({ cache: true }),
    AutoImport({
      imports: [
        {
          "$app/utils/routes": [["*", "Routes"]],
        },
      ],
      dts: "app/javascript/types/auto-imports.d.ts",
    }),
  ],
  resolve: {
    alias: {
      $app: resolve(__dirname, "app/javascript"),
      $assets: resolve(__dirname, "app/assets"),
      $vendor: resolve(__dirname, "vendor/assets/javascripts"),
      jwplayer: resolve(__dirname, "vendor/assets/components/jwplayer-7.12.13/jwplayer"),
      "~fonts": resolve(__dirname, "app/assets/fonts"),
      "~images": resolve(__dirname, "app/assets/images"),
    },
    extensions: [".js", ".ts", ".tsx", ".jsx"],
  },
  define: {
    SSR: false,
    "process.env.NODE_ENV": JSON.stringify(process.env.NODE_ENV || "test"),
    "process.env.RAILS_ENV": JSON.stringify(process.env.RAILS_ENV || "test"),
    "process.env.PROTOCOL": JSON.stringify(process.env.PROTOCOL || "https"),
    "process.env": "({})",
  },
  css: {
    preprocessorOptions: {
      scss: {
        includePaths: [resolve(__dirname, "app/assets")],
      },
    },
  },
});
