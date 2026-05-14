import path from "path";
import ts from "typescript";
import tsCast from "ts-safe-cast/transformer.js";

let program;
let compilerOptions;

function ensureProgram(rootDir) {
  if (program) return;
  const configPath = ts.findConfigFile(
    rootDir || process.cwd(),
    ts.sys.fileExists,
    "tsconfig.json",
  );
  const configFile = ts.readConfigFile(configPath, ts.sys.readFile);
  const parsed = ts.parseJsonConfigFileContent(
    configFile.config,
    ts.sys,
    path.dirname(configPath),
  );
  compilerOptions = parsed.options;

  // Create a program with all project files so the transformer has full
  // type information for every source file it encounters.
  program = ts.createProgram(parsed.fileNames, compilerOptions);
}

export default function tsSafeCastPlugin() {
  return {
    name: "vite-plugin-ts-safe-cast",
    enforce: "pre",
    configResolved(config) {
      ensureProgram(config.root);
    },
    transform(code, id) {
      // Only process .ts and .tsx files
      if (!/\.(ts|tsx)$/u.test(id)) return null;
      if (id.includes("node_modules")) return null;
      // Quick check: does this file import from ts-safe-cast?
      if (!code.includes("ts-safe-cast")) return null;

      ensureProgram();

      // Try to get the source file from the program.
      // The id from Vite is an absolute path; the program should have it
      // if it's included in tsconfig.
      let sourceFile = program.getSourceFile(id);

      // Fallback: if the program doesn't have this file (path mismatch),
      // try resolving via realpath
      if (!sourceFile) {
        try {
          const realPath = ts.sys.realpath?.(id) ?? id;
          sourceFile = program.getSourceFile(realPath);
        } catch {
          // ignore
        }
      }

      // Last resort: create a standalone source file and a minimal program
      // just for this file. The transformer needs a Program to resolve types,
      // so we create one on the fly.
      if (!sourceFile) {
        const tmpHost = ts.createCompilerHost(compilerOptions);
        const originalGetSourceFile = tmpHost.getSourceFile;
        tmpHost.getSourceFile = (fileName, languageVersion, onError) => {
          if (path.resolve(fileName) === path.resolve(id)) {
            return ts.createSourceFile(fileName, code, languageVersion, true);
          }
          return originalGetSourceFile.call(
            tmpHost,
            fileName,
            languageVersion,
            onError,
          );
        };
        const tmpProgram = ts.createProgram([id], compilerOptions, tmpHost);
        sourceFile = tmpProgram.getSourceFile(id);
        if (!sourceFile) return null;

        const transformer = tsCast(tmpProgram);
        const result = ts.transform(sourceFile, [transformer]);
        const printer = ts.createPrinter();
        const transformed = printer.printFile(result.transformed[0]);
        result.dispose();
        return { code: transformed, map: null };
      }

      const transformer = tsCast(program);
      const result = ts.transform(sourceFile, [transformer]);
      const printer = ts.createPrinter();
      const transformed = printer.printFile(result.transformed[0]);
      result.dispose();

      return { code: transformed, map: null };
    },
  };
}
