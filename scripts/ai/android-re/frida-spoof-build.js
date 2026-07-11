// Frida script: Override android.os.Build fields to match the Pixel 7 spoof profile.
// This closes the gap where resetprop fixes shell-level props but Java-level
// Build fields (cached by Zygote at startup) still show emulator values.
//
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-spoof-build.js
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-spoof-build.js --no-pause

// Pixel 7 (panther) profile — must match _spoof-table.sh values
var SPOOF = {
	BOARD: "gs101",
	BRAND: "google",
	DEVICE: "panther",
	DISPLAY: "UQ1A.240205.002",
	FINGERPRINT:
		"google/panther/panther:14/UQ1A.240205.002/12069354:user/release-keys",
	HARDWARE: "pixel",
	HOST: "abfarm-release-rbe-64-00075",
	ID: "UQ1A.240205.002",
	MANUFACTURER: "Google",
	MODEL: "Pixel 7",
	PRODUCT: "panther",
	SERIAL: "",
	TAGS: "release-keys",
	TYPE: "user",
};

// Build.VERSION fields — must match _spoof-table.sh version properties
var SPOOF_VERSION = {
	CODENAME: "REL",
	INCREMENTAL: "12069354",
	RELEASE: "14",
	SDK_INT: 34,
	SECURITY_PATCH: "2024-02-05",
};

// CPU ABI — emulator reports x86_64; real Pixel 7 is arm64-v8a
var SPOOF_ABIS = [
	"arm64-v8a",
	"armeabi-v7a",
	"armeabi",
];

// Emulator-indicator files to hide — must match SPOOF_HIDE_FILES in _spoof-table.sh
var HIDDEN_PATHS = [
	"/dev/goldfish_pipe",
	"/dev/qemu_pipe",
	"/dev/socket/genyd",
	"/dev/socket/genymotion",
	"/dev/socket/qemud",
	"/dev/qemu_trace",
	"/system/lib/libgoldfish-ril.so",
	"/system/lib64/libgoldfish-ril.so",
	"/system/lib/libgoldfish_icd.so",
	"/system/lib64/libgoldfish_icd.so",
	"/system/bin/qemu-props",
	"/system/bin/qemud",
	"/system/lib/libc_malloc_debug_qemu.so",
	"/system/lib64/libc_malloc_debug_qemu.so",
];

Java.perform(() => {
	var Build = Java.use("android.os.Build");
	var BuildVersion;
	var File;
	var SystemProperties;
	var fields = Object.keys(SPOOF);
	var patched = 0;
	var failed = 0;
	var idx;
	var value;

	// Override static Build fields
	for (idx = 0; idx < fields.length; idx++) {
		value = SPOOF[fields[idx]];
		if (value === "") continue;
		try {
			Build[fields[idx]].value = value;
			patched++;
		} catch (e) {
			failed++;
			console.log("[spoof-build] FAILED: " + fields[idx] + " -> " + e);
		}
	}

	// Build.VERSION fields
	try {
		BuildVersion = Java.use("android.os.Build$VERSION");
		var versionFields = Object.keys(SPOOF_VERSION);
		for (idx = 0; idx < versionFields.length; idx++) {
			try {
				BuildVersion[versionFields[idx]].value =
					SPOOF_VERSION[versionFields[idx]];
				patched++;
			} catch (e) {
				// SDK_INT is a special case — it's a static int, not a String
			}
		}
	} catch (e) {
		// ignore
	}

	// Build.SUPPORTED_ABIS — override the String[] array
	try {
		var abis = Java.array("java.lang.String", SPOOF_ABIS);
		Build.SUPPORTED_ABIS.value = abis;
		patched++;
		console.log(
			"[spoof-build] SUPPORTED_ABIS overridden to " + SPOOF_ABIS.join(", "),
		);
	} catch (e) {
		failed++;
		console.log("[spoof-build] FAILED: SUPPORTED_ABIS -> " + e);
	}

	// Override SystemProperties at the Java level for props that some apps
	// read via SystemProperties.get() instead of Build fields.
	try {
		SystemProperties = Java.use("android.os.SystemProperties");
		var originalGet = SystemProperties.get.overload("java.lang.String");

		originalGet.implementation = function (key) {
			var result = originalGet.call(this, key);

			// Override CPU ABI props (most reliable emulator tell)
			if (key === "ro.product.cpu.abi") return "arm64-v8a";
			if (key === "ro.product.cpu.abi2") return "armeabi-v7a";
			if (key === "ro.product.cpu.abilist")
				return "arm64-v8a,armeabi-v7a,armeabi";

			// Suppress QEMU tells
			if (key === "ro.kernel.qemu") return "0";
			if (key === "ro.boot.qemu") return "0";
			if (key === "ro.kernel.qemu.gles") return "0";

			return result;
		};
		patched++;
	} catch (e) {
		failed++;
		console.log("[spoof-build] FAILED: SystemProperties.get -> " + e);
	}

	console.log(
		"[spoof-build] Patched " +
			patched +
			" Build fields" +
			(failed > 0 ? " (" + failed + " failed)" : ""),
	);
	console.log(
		"[spoof-build] MODEL=" +
			Build.MODEL.value +
			" HARDWARE=" +
			Build.HARDWARE.value +
			" MFG=" +
			Build.MANUFACTURER.value,
	);

	// Hook File.exists to hide emulator-indicator files
	File = Java.use("java.io.File");
	File.exists.implementation = function () {
		var path = this.getAbsolutePath();
		for (idx = 0; idx < HIDDEN_PATHS.length; idx++) {
			if (path === HIDDEN_PATHS[idx]) {
				return false;
			}
		}
		return this.exists();
	};

	// Also hook File.isFile and File.canRead for the same paths
	try {
		File.isFile.implementation = function () {
			var path = this.getAbsolutePath();
			for (idx = 0; idx < HIDDEN_PATHS.length; idx++) {
				if (path === HIDDEN_PATHS[idx]) {
					return false;
				}
			}
			return this.isFile();
		};
	} catch (e) {
		console.log("[spoof-build] File.isFile hook skipped: " + e.message);
	}

	try {
		File.canRead.implementation = function () {
			var path = this.getAbsolutePath();
			for (idx = 0; idx < HIDDEN_PATHS.length; idx++) {
				if (path === HIDDEN_PATHS[idx]) {
					return false;
				}
			}
			return this.canRead();
		};
	} catch (e) {
		console.log("[spoof-build] File.canRead hook skipped: " + e.message);
	}

	console.log(
		"[spoof-build] File.exists/isFile/canRead hooks active for " +
			HIDDEN_PATHS.length +
			" emulator paths",
	);
});
