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

// Vite uses import.meta.glob instead of webpack's dynamic import
const pages = import.meta.glob("../pages/**/*.tsx");

const resolvePageComponent = async (name: string): Promise<PageComponent> => {
  const path = `../pages/${name}.tsx`;
  const resolver = pages[path];
  if (!resolver) {
    throw new Error(`Admin page component not found: ${name} (tried ${path})`);
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
