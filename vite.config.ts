import UnpluginTypia from "@typia/unplugin/vite";
import react from "@vitejs/plugin-react";
import fs from "fs";
import { resolve } from "path";
import AutoImport from "unplugin-auto-import/vite";
import { defineConfig, type Plugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";

// Custom plugin to strip the CommonJS `module.exports = routes;` line from the
// js-routes-generated app/javascript/utils/routes.js when Vite transforms it.
// routes.js intentionally ships BOTH ESM `export const` statements and a CJS
// `module.exports` assignment so it can be consumed by webpack (CJS) and Vite
// (ESM) during the side-by-side migration. Vite warns on mixed CJS/ESM and
// the warning causes admin pages to render blank in CI. We strip the CJS line
// in-memory only; the on-disk file is unchanged so webpack still works.
function stripCjsExportsPlugin(): Plugin {
  return {
    name: "vite-plugin-strip-cjs-exports",
    transform(code, id) {
      if (!id.endsWith("utils/routes.js")) return null;
      const cleaned = code.replace(/^\s*module\.exports\s*=\s*routes;?\s*$/m, "");
      if (cleaned !== code) return { code: cleaned, map: null };
      return null;
    },
  };
}

// Custom plugin to transform webpack's require.context() into Vite-compatible code.
// This allows shared files to work with both webpack (which natively supports require.context)
// and Vite (which doesn't) during the side-by-side migration period.
function requireContextPlugin(): Plugin {
  const aliases: Record<string, string> = {
    $assets: resolve(__dirname, "app/assets"),
    $app: resolve(__dirname, "app/javascript"),
  };

  return {
    name: "vite-plugin-require-context",
    transform(code, id) {
      if (!code.includes("require.context")) return null;

      // Match: require.context("path") or require.context("path", recursive, regex)
      const pattern = /require\.context\(\s*["']([^"']+)["'](?:\s*,\s*[^,)]+)?(?:\s*,\s*[^)]+)?\s*\)/g;

      let transformed = code;
      let match;
      while ((match = pattern.exec(code)) !== null) {
        const [fullMatch, contextPath] = match;

        // Resolve the alias in the path
        let resolvedDir = contextPath;
        for (const [alias, target] of Object.entries(aliases)) {
          if (resolvedDir.startsWith(alias)) {
            resolvedDir = resolvedDir.replace(alias, target);
            break;
          }
        }

        // Read directory contents and build a map
        try {
          const files = fs.readdirSync(resolvedDir);
          const entries = files
            .filter((f: string) => !f.startsWith("."))
            .map((f: string) => {
              const fullPath = resolve(resolvedDir, f);
              return `"./${f}": new URL("${fullPath}", import.meta.url).href`;
            });

          // Build a function that mimics require.context behavior
          const replacement = `((function() {
  const _map = { ${entries.join(", ")} };
  const ctx = (key) => _map[key];
  ctx.keys = () => Object.keys(_map);
  return ctx;
})())`;

          transformed = transformed.replace(fullMatch, replacement);
        } catch {
          // If directory doesn't exist, skip transformation
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
    UnpluginTypia(),
    AutoImport({
      imports: [
        {
          // Replaces webpack ProvidePlugin({ Routes: "$app/utils/routes" })
          // Makes all route helpers available as Routes.xxx() without explicit imports
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
      // Webpack ~ prefix aliases for SCSS url() references
      "~fonts": resolve(__dirname, "app/assets/fonts"),
      "~images": resolve(__dirname, "app/assets/images"),
    },
    extensions: [".js", ".ts", ".tsx", ".jsx"],
  },
  define: {
    SSR: false,
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'test'),
    'process.env.RAILS_ENV': JSON.stringify(process.env.RAILS_ENV || 'test'),
    'process.env.PROTOCOL': JSON.stringify(process.env.PROTOCOL || 'https'),
    // Fallback so any other process.env.FOO won't throw.
    // The value is a code expression: {} is an empty object literal.
    'process.env': '({})',
  },
  css: {
    preprocessorOptions: {
      scss: {
        includePaths: [resolve(__dirname, "app/assets")],
      },
    },
  },
});
