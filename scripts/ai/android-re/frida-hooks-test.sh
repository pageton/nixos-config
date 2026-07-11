#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/lib/test-helpers.sh"

# ── File existence checks ──

# Original hooks
assert_true "hook file exists: build fields" test -f "${SCRIPT_DIR}/frida-hook-build-fields.js"
assert_true "hook file exists: file exists" test -f "${SCRIPT_DIR}/frida-hook-file-exists.js"
assert_true "hook file exists: shared prefs" test -f "${SCRIPT_DIR}/frida-hook-shared-prefs.js"
assert_true "hook file exists: url log" test -f "${SCRIPT_DIR}/frida-hook-url-log.js"
assert_true "hook file exists: cert pinner" test -f "${SCRIPT_DIR}/frida-bypass-certificate-pinner.js"
assert_true "hook file exists: spoof build" test -f "${SCRIPT_DIR}/frida-spoof-build.js"
assert_true "hook file exists: crypto" test -f "${SCRIPT_DIR}/frida-hook-crypto.js"
assert_true "hook file exists: webview" test -f "${SCRIPT_DIR}/frida-hook-webview.js"
assert_true "hook file exists: network" test -f "${SCRIPT_DIR}/frida-hook-network.js"
assert_true "hook file exists: intent" test -f "${SCRIPT_DIR}/frida-hook-intent.js"

# New hooks
assert_true "hook file exists: root detection" test -f "${SCRIPT_DIR}/frida-hook-root-detection.js"
assert_true "hook file exists: frida detection" test -f "${SCRIPT_DIR}/frida-hook-frida-detection.js"
assert_true "hook file exists: dex classloader" test -f "${SCRIPT_DIR}/frida-hook-dex-classloader.js"
assert_true "hook file exists: sqlite" test -f "${SCRIPT_DIR}/frida-hook-sqlite.js"
assert_true "hook file exists: keystore" test -f "${SCRIPT_DIR}/frida-hook-keystore.js"
assert_true "hook file exists: clipboard" test -f "${SCRIPT_DIR}/frida-hook-clipboard.js"
assert_true "hook file exists: location" test -f "${SCRIPT_DIR}/frida-hook-location.js"
assert_true "hook file exists: content provider" test -f "${SCRIPT_DIR}/frida-hook-content-provider.js"
assert_true "hook file exists: settings" test -f "${SCRIPT_DIR}/frida-hook-settings.js"

# ── Content assertions: Java.perform wrapper ──

build_fields_contents="$(<"${SCRIPT_DIR}/frida-hook-build-fields.js")"
assert_contains "${build_fields_contents}" "Java.perform" "build fields hook uses Java.perform"

cert_bypass_contents="$(<"${SCRIPT_DIR}/frida-bypass-certificate-pinner.js")"
assert_contains "${cert_bypass_contents}" "CertificatePinner" "cert bypass hook targets CertificatePinner"
assert_contains "${cert_bypass_contents}" "SSLContext" "cert bypass hook targets SSLContext"
assert_contains "${cert_bypass_contents}" "TrustManagerImpl" "cert bypass hook targets TrustManagerImpl"

crypto_contents="$(<"${SCRIPT_DIR}/frida-hook-crypto.js")"
assert_contains "${crypto_contents}" "Java.perform" "crypto hook uses Java.perform"
assert_contains "${crypto_contents}" "javax.crypto.Cipher" "crypto hook targets Cipher"
assert_contains "${crypto_contents}" "hexdump" "crypto hook includes hex dump helper"

webview_contents="$(<"${SCRIPT_DIR}/frida-hook-webview.js")"
assert_contains "${webview_contents}" "Java.perform" "webview hook uses Java.perform"
assert_contains "${webview_contents}" "android.webkit.WebView" "webview hook targets WebView"

network_contents="$(<"${SCRIPT_DIR}/frida-hook-network.js")"
assert_contains "${network_contents}" "Java.perform" "network hook uses Java.perform"
assert_contains "${network_contents}" "java.net.Socket" "network hook targets Socket"
assert_contains "${network_contents}" "retrofit2" "network hook covers Retrofit"

intent_contents="$(<"${SCRIPT_DIR}/frida-hook-intent.js")"
assert_contains "${intent_contents}" "Java.perform" "intent hook uses Java.perform"
assert_contains "${intent_contents}" "startActivity" "intent hook targets startActivity"

# ── Content assertions: new hooks ──

root_detection_contents="$(<"${SCRIPT_DIR}/frida-hook-root-detection.js")"
assert_contains "${root_detection_contents}" "Java.perform" "root detection hook uses Java.perform"
assert_contains "${root_detection_contents}" "Runtime.exec" "root detection hook targets Runtime.exec"
assert_contains "${root_detection_contents}" "isDebuggerConnected" "root detection hook targets debugger detection"

frida_detection_contents="$(<"${SCRIPT_DIR}/frida-hook-frida-detection.js")"
assert_contains "${frida_detection_contents}" "Java.perform" "frida detection hook uses Java.perform"
assert_contains "${frida_detection_contents}" "27042" "frida detection hook checks port 27042"

dex_classloader_contents="$(<"${SCRIPT_DIR}/frida-hook-dex-classloader.js")"
assert_contains "${dex_classloader_contents}" "Java.perform" "dex classloader hook uses Java.perform"
assert_contains "${dex_classloader_contents}" "DexClassLoader" "dex classloader hook targets DexClassLoader"

sqlite_contents="$(<"${SCRIPT_DIR}/frida-hook-sqlite.js")"
assert_contains "${sqlite_contents}" "Java.perform" "sqlite hook uses Java.perform"
assert_contains "${sqlite_contents}" "SQLiteDatabase" "sqlite hook targets SQLiteDatabase"
assert_contains "${sqlite_contents}" "execSQL" "sqlite hook targets execSQL"

keystore_contents="$(<"${SCRIPT_DIR}/frida-hook-keystore.js")"
assert_contains "${keystore_contents}" "Java.perform" "keystore hook uses Java.perform"
assert_contains "${keystore_contents}" "KeyStore" "keystore hook targets KeyStore"

clipboard_contents="$(<"${SCRIPT_DIR}/frida-hook-clipboard.js")"
assert_contains "${clipboard_contents}" "Java.perform" "clipboard hook uses Java.perform"
assert_contains "${clipboard_contents}" "ClipboardManager" "clipboard hook targets ClipboardManager"

location_contents="$(<"${SCRIPT_DIR}/frida-hook-location.js")"
assert_contains "${location_contents}" "Java.perform" "location hook uses Java.perform"
assert_contains "${location_contents}" "LocationManager" "location hook targets LocationManager"

content_provider_contents="$(<"${SCRIPT_DIR}/frida-hook-content-provider.js")"
assert_contains "${content_provider_contents}" "Java.perform" "content provider hook uses Java.perform"
assert_contains "${content_provider_contents}" "ContentResolver" "content provider hook targets ContentResolver"

settings_contents="$(<"${SCRIPT_DIR}/frida-hook-settings.js")"
assert_contains "${settings_contents}" "Java.perform" "settings hook uses Java.perform"
assert_contains "${settings_contents}" "Settings" "settings hook targets Settings"

# ── Content assertions: enhanced hooks ──

shared_prefs_contents="$(<"${SCRIPT_DIR}/frida-hook-shared-prefs.js")"
assert_contains "${shared_prefs_contents}" "getInt" "shared prefs hook covers getInt"
assert_contains "${shared_prefs_contents}" "getAll" "shared prefs hook covers getAll"
assert_contains "${shared_prefs_contents}" "putBoolean" "shared prefs hook covers putBoolean"

file_exists_contents="$(<"${SCRIPT_DIR}/frida-hook-file-exists.js")"
assert_contains "${file_exists_contents}" "isFile" "file exists hook covers isFile"
assert_contains "${file_exists_contents}" "canRead" "file exists hook covers canRead"

url_log_contents="$(<"${SCRIPT_DIR}/frida-hook-url-log.js")"
assert_contains "${url_log_contents}" "URI" "url log hook covers URI"

spoof_build_contents="$(<"${SCRIPT_DIR}/frida-spoof-build.js")"
assert_contains "${spoof_build_contents}" "SUPPORTED_ABIS" "spoof build hook patches SUPPORTED_ABIS"
assert_contains "${spoof_build_contents}" "SystemProperties" "spoof build hook intercepts SystemProperties"
assert_contains "${spoof_build_contents}" "isFile" "spoof build hook covers File.isFile"
assert_contains "${spoof_build_contents}" "canRead" "spoof build hook covers File.canRead"

# ── Prompt file assertions ──

agents_prompt="$(<"${REPO_ROOT}/home/programs/ai-agents/android-re/prompts/AGENTS.md")"
assert_contains "${agents_prompt}" "search the web, official docs, GitHub, CVE databases" "agent prompt allows external research"
assert_contains "${agents_prompt}" "CVE" "agent prompt allows CVE research"
assert_contains "${agents_prompt}" "use subagents" "agent prompt allows subagents"

tools_prompt="$(<"${REPO_ROOT}/home/programs/ai-agents/android-re/prompts/TOOLS.md")"
assert_contains "${tools_prompt}" "Local Frida Hook Library" "tools prompt documents local hook library"
assert_contains "${tools_prompt}" "frida-hook-build-fields.js" "tools prompt references build fields hook"

workflow_prompt="$(<"${REPO_ROOT}/home/programs/ai-agents/android-re/prompts/WORKFLOW.md")"
assert_contains "${workflow_prompt}" "hook library" "workflow prompt mentions hook library"

echo "All Android RE hook library tests passed."
