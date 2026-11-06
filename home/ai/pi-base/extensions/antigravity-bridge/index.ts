// Root entry so Pi's conventional extensions directory loads this package.
// The npm manifest exposes ./extensions via its `pi` key, which only applies
// when installed as a managed package; a local directory needs a root
// index.ts. The .js extension is the package's own import style (jiti
// resolves it to the TypeScript source).
export { default } from "./extensions/index.js";
