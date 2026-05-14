// Admin entrypoint for Vite
// Mirrors app/javascript/packs/admin.ts but using Vite conventions

// Import admin styles
import "../packs/admin.scss";

// Import the admin Inertia app
import { createInertiaApp } from "@inertiajs/react";
import React, { createElement } from "react";
import { createRoot } from "react-dom/client";

import AdminAppWrapper, { GlobalProps } from "../inertia/admin_app_wrapper";
import Layout from "../layouts/Admin";

const AdminLayout = (page: React.ReactNode) => React.createElement(Layout, { children: page });

type PageComponent = React.ComponentType & { layout?: (page: React.ReactNode) => React.ReactElement };

const isPageComponent = (value: unknown): value is PageComponent => typeof value === "function";

// Vite uses import.meta.glob instead of webpack's dynamic import.
// Restrict to admin pages only (webpack used dynamic import() which was
// lazy per-page; a `**/*.tsx` glob would pull every Inertia page into the
// admin bundle). Include a .jsx fallback for legacy files.
const pages = {
  ...import.meta.glob("../pages/Admin/**/*.tsx"),
  ...import.meta.glob("../pages/Admin/**/*.jsx"),
};

const resolvePageComponent = async (name: string): Promise<PageComponent> => {
  const tsxPath = `../pages/${name}.tsx`;
  const jsxPath = `../pages/${name}.jsx`;
  const resolver = pages[tsxPath] ?? pages[jsxPath];
  if (!resolver) {
    throw new Error(`Admin page component not found: ${name} (tried ${tsxPath}, ${jsxPath})`);
  }
  const module = (await resolver()) as { default?: unknown };
  if (module && typeof module === "object" && "default" in module && isPageComponent(module.default)) {
    const component = module.default;
    component.layout = AdminLayout;
    return component;
  }
  throw new Error(`Invalid page component: ${name}`);
};

void createInertiaApp<GlobalProps>({
  progress: false,
  resolve: (name: string) => resolvePageComponent(name),
  setup({ el, App, props }) {
    const global = props.initialPage.props;

    const root = createRoot(el);
    root.render(createElement(AdminAppWrapper, { global, children: createElement(App, props) }));
  },
  title: (title: string) => (title ? `${title} - Admin` : "Admin"),
});
