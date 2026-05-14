import { resolve } from "path";
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    outDir: "public/js",
    emptyOutDir: false,
    rollupOptions: {
      input: {
        'gumroad-embed': resolve(__dirname, 'app/javascript/widget/embed.ts'),
        'gumroad': resolve(__dirname, 'app/javascript/widget/overlay.ts'),
      },
      output: {
        entryFileNames: '[name].js',
        assetFileNames: '[name].[ext]',
      },
    },
  },
  define: {
    'process.env.PROTOCOL': JSON.stringify(process.env.PROTOCOL || 'https'),
    'process.env.DOMAIN': JSON.stringify(process.env.DOMAIN || 'gumroad.com'),
    'process.env.ROOT_DOMAIN': JSON.stringify(process.env.ROOT_DOMAIN || 'gumroad.com'),
    'process.env.SHORT_DOMAIN': JSON.stringify(process.env.SHORT_DOMAIN || 'gum.co'),
    'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'production'),
    'process.env': '({})',
  },
  css: {
    preprocessorOptions: {
      scss: {
        loadPaths: [resolve(__dirname, 'app/assets')],
      },
    },
  },
});
