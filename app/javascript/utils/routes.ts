const Routes = new Proxy({}, { get: () => () => "" }) as Record<string, (...args: unknown[]) => string>;
export default Routes;
