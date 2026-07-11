# Android RE Toolkit

Automated emulator environment setup (rooted AVD with Frida, mitmproxy, device spoofing), Frida instrumentation hooks for runtime analysis, static analysis tooling, and OpenCode workspace integration.

Parent: `scripts/ai/AGENTS.md`

---

## Files

| File                                 | Purpose                                                                                                  |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `re-avd.sh`                          | Main environment manager: 10-phase start sequence (cleanup, boot, proxy, root, spoof, CA, Frida, health) |
| `re-avd-test.sh`                     | Unit tests for re-avd.sh                                                                                 |
| `re-static.sh`                       | Static analysis: `prepare` (apktool+jadx), `hashes`, `inventory`, `diff` (8-way comparison)              |
| `opencode-android-re.sh`             | OpenCode session launcher (called by `oc*are` wrappers)                                                  |
| `mimo-android-re.sh`                 | MiMoCode session launcher (called by `mi*are` wrappers)                                                  |
| `_helpers.sh`                        | Shared helpers: `adb_prop`, `emulator_online`, `resolve_niri_android_workspace`                          |
| `_spoof-table.sh`                    | Declarative Pixel 7 spoof: 60+ properties, 14 files to hide, 9 services to stop                         |
| `_emulator.sh`                       | Emulator management helpers (sourced library)                                                            |
| `_frida.sh`                          | Frida helper functions (sourced library)                                                                 |
| `_mitm.sh`                           | mitmproxy helper functions (sourced library)                                                             |
| `_spoof.sh`                          | Device spoof helper functions (sourced library)                                                          |
| `_status.sh`                         | Status check helper functions (sourced library)                                                          |
| `_tmux.sh`                           | tmux helper functions (sourced library)                                                                  |
| `frida-spoof-build.js`               | Frida: overrides Build fields, SUPPORTED_ABIS, SystemProperties, hides emulator files (exists/isFile/canRead) |
| `frida-bypass-certificate-pinner.js` | Frida: bypasses 9 SSL pinning implementations (OkHttp, Conscrypt, SSLContext, CertChainCleaner, CertPathValidator) |
| `frida-hook-build-fields.js`         | Frida: logs android.os.Build fields (read-only diagnostic)                                               |
| `frida-hook-file-exists.js`          | Frida: logs File.exists/isFile/canRead for 23+ root/emulator/frida patterns                              |
| `frida-hook-shared-prefs.js`         | Frida: logs all SharedPreferences reads/writes (14 method hooks)                                         |
| `frida-hook-url-log.js`              | Frida: logs URL/URI construction (10 constructors)                                                       |
| `frida-hook-crypto.js`              | Frida: logs Cipher/Mac/MessageDigest/Signature with hex dumps, KeyGenerator, KeyAgreement, SecureRandom  |
| `frida-hook-webview.js`              | Frida: logs WebView.loadUrl, evaluateJavascript, addJavascriptInterface, shouldOverrideUrlLoading         |
| `frida-hook-network.js`              | Frida: logs Socket/SSLSocket/OkHttp/Retrofit/HttpURLConnection, response codes, SSL overrides             |
| `frida-hook-intent.js`               | Frida: logs startActivity, BroadcastReceiver, ContentResolver.query                                       |
| `frida-hook-root-detection.js`       | Frida: logs 11 root/emulator/debugger detection vectors                                                  |
| `frida-hook-frida-detection.js`      | Frida: logs 11 Frida artifact detection vectors (port 27042, /proc, threads)                             |
| `frida-hook-dex-classloader.js`      | Frida: logs 8 dynamic code loading mechanisms (DexClassLoader, InMemoryDexClassLoader, etc.)              |
| `frida-hook-sqlite.js`               | Frida: logs 9 SQLite operations (open, execSQL, query, insert, update, delete)                           |
| `frida-hook-keystore.js`             | Frida: logs 7 Android Keystore operations (getInstance, getEntry, getKey, setEntry, KeyGenParameterSpec) |
| `frida-hook-clipboard.js`            | Frida: logs clipboard read/write operations                                                              |
| `frida-hook-location.js`             | Frida: logs 10 location/GPS access operations                                                            |
| `frida-hook-content-provider.js`     | Frida: logs 7 ContentResolver operations (query, insert, update, delete, call, openInputStream/Output)   |
| `frida-hook-settings.js`             | Frida: logs system settings access (adb/debug/proxy/verifier filters)                                    |
| `frida-hooks-test.sh`                | Unit tests verifying hook files exist and use `Java.perform`                                             |

---

## Conventions

- `_` prefix for sourced libraries (`_helpers.sh`, `_spoof-table.sh`, `_emulator.sh`, `_frida.sh`, `_mitm.sh`, `_spoof.sh`, `_status.sh`, `_tmux.sh`) — no `set -euo pipefail`.
- Frida hooks follow: `Java.perform(function() { ... })` with tagged console output (`[cert-bypass]`, `[url-log]`, etc.).
- Spoof table is the single source of truth for device identity.
- Environment-variable-driven: ~30 env vars (`AVD_NAME`, `FRIDA_VERSION`, `MITM_PORT`, etc.) with sensible defaults.
- 10-phase start sequence in `re-avd.sh start` is strictly ordered.

---

## Gotchas

- `_spoof-table.sh` and `frida-spoof-build.js` must be kept in sync — both define the Pixel 7 spoof profile independently. `frida-spoof-build.js` also patches `SUPPORTED_ABIS` and intercepts `SystemProperties.get` for CPU ABI props.
- `frida-spoof-build.js` patches Build fields, SUPPORTED_ABIS, SystemProperties AND hides emulator files via File.exists/isFile/canRead. `frida-hook-build-fields.js` is read-only/diagnostic only. `frida-hook-root-detection.js` monitors detection vectors without bypassing them.
- `re-avd.sh start` kills ALL running emulators on start — be careful if other AVDs are running.
- Frida server deployed to `/data/local/tmp/` on the emulator (configurable via `FRIDA_BIN`).
- `opencode-android-re.sh` reads `ANDROID_RE_OPENCODE_PROFILE` env var (set by Nix wrapper).
- Niri window rule matches title `^android-re` — do not change the Alacritty title without updating niri config.
- Runtime tools required: `adb`, `emulator`, `frida`/`frida-ps`, `mitmdump`, `apktool`, `jadx`.

---

## Dependencies

- `../../lib/logging.sh`, `../../lib/require.sh` (via `_helpers.sh`), `../../lib/test-helpers.sh`
- Nix modules: `ai-agents/android-re/` (wrapper binaries, prompt injection)
- Nix helpers: `ai-agents/helpers/_android-re-launchers.nix` wraps `opencode-android-re.sh`
