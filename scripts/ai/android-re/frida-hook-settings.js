// Frida script: Log system settings access (Settings.Secure, Settings.Global, Settings.System).
// Focuses on adb/debug/proxy/verifier keys (security/emulator detection) for getString.
// Logs all putInt/putString writes.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-settings.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-settings.js

var INTEREST_PATTERNS = [
	"adb",
	"debug",
	"proxy",
	"verifier",
	"animation",
	"development",
];

function isInteresting(key) {
	if (!key) {
		return false;
	}
	var lower = key.toLowerCase();
	for (var i = 0; i < INTEREST_PATTERNS.length; i++) {
		if (lower.indexOf(INTEREST_PATTERNS[i]) >= 0) {
			return true;
		}
	}
	return false;
}

Java.perform(() => {
	// android.provider.Settings.Secure.getString(ContentResolver, String)
	try {
		var SettingsSecure = Java.use("android.provider.Settings$Secure");
		var secureGetString = SettingsSecure.getString.overload(
			"android.content.ContentResolver",
			"java.lang.String",
		);
		secureGetString.implementation = function (cr, key) {
			var value = secureGetString.call(this, cr, key);
			if (isInteresting(key)) {
				console.log("[settings] Secure.getString key=" + key + " value=" + value);
			}
			return value;
		};
	} catch (e) {
		console.log("[settings] Secure.getString hook skipped: " + e.message);
	}

	// android.provider.Settings.Global.getString(ContentResolver, String)
	try {
		var SettingsGlobal = Java.use("android.provider.Settings$Global");
		var globalGetString = SettingsGlobal.getString.overload(
			"android.content.ContentResolver",
			"java.lang.String",
		);
		globalGetString.implementation = function (cr, key) {
			var value = globalGetString.call(this, cr, key);
			if (isInteresting(key)) {
				console.log("[settings] Global.getString key=" + key + " value=" + value);
			}
			return value;
		};
	} catch (e) {
		console.log("[settings] Global.getString hook skipped: " + e.message);
	}

	// android.provider.Settings.System.getString(ContentResolver, String)
	try {
		var SettingsSystem = Java.use("android.provider.Settings$System");
		var systemGetString = SettingsSystem.getString.overload(
			"android.content.ContentResolver",
			"java.lang.String",
		);
		systemGetString.implementation = function (cr, key) {
			var value = systemGetString.call(this, cr, key);
			if (isInteresting(key)) {
				console.log("[settings] System.getString key=" + key + " value=" + value);
			}
			return value;
		};
	} catch (e) {
		console.log("[settings] System.getString hook skipped: " + e.message);
	}

	// android.provider.Settings.Secure.putInt(ContentResolver, String, int)
	try {
		var SettingsSecure2 = Java.use("android.provider.Settings$Secure");
		var securePutInt = SettingsSecure2.putInt.overload(
			"android.content.ContentResolver",
			"java.lang.String",
			"int",
		);
		securePutInt.implementation = function (cr, key, value) {
			console.log("[settings] Secure.putInt key=" + key + " value=" + value);
			return securePutInt.call(this, cr, key, value);
		};
	} catch (e) {
		console.log("[settings] Secure.putInt hook skipped: " + e.message);
	}

	// android.provider.Settings.Global.putInt(ContentResolver, String, int)
	try {
		var SettingsGlobal2 = Java.use("android.provider.Settings$Global");
		var globalPutInt = SettingsGlobal2.putInt.overload(
			"android.content.ContentResolver",
			"java.lang.String",
			"int",
		);
		globalPutInt.implementation = function (cr, key, value) {
			console.log("[settings] Global.putInt key=" + key + " value=" + value);
			return globalPutInt.call(this, cr, key, value);
		};
	} catch (e) {
		console.log("[settings] Global.putInt hook skipped: " + e.message);
	}

	// android.provider.Settings.Secure.putString(ContentResolver, String, String)
	try {
		var SettingsSecure3 = Java.use("android.provider.Settings$Secure");
		var securePutString = SettingsSecure3.putString.overload(
			"android.content.ContentResolver",
			"java.lang.String",
			"java.lang.String",
		);
		securePutString.implementation = function (cr, key, value) {
			console.log("[settings] Secure.putString key=" + key + " value=" + value);
			return securePutString.call(this, cr, key, value);
		};
	} catch (e) {
		console.log("[settings] Secure.putString hook skipped: " + e.message);
	}

	// android.provider.Settings.Global.putString(ContentResolver, String, String)
	try {
		var SettingsGlobal3 = Java.use("android.provider.Settings$Global");
		var globalPutString = SettingsGlobal3.putString.overload(
			"android.content.ContentResolver",
			"java.lang.String",
			"java.lang.String",
		);
		globalPutString.implementation = function (cr, key, value) {
			console.log("[settings] Global.putString key=" + key + " value=" + value);
			return globalPutString.call(this, cr, key, value);
		};
	} catch (e) {
		console.log("[settings] Global.putString hook skipped: " + e.message);
	}

	// android.provider.Settings.Global.getFloat(ContentResolver, String)
	// Used for animation scale reads (emulator detection).
	try {
		var SettingsGlobal4 = Java.use("android.provider.Settings$Global");
		var globalGetFloat = SettingsGlobal4.getFloat.overload(
			"android.content.ContentResolver",
			"java.lang.String",
		);
		globalGetFloat.implementation = function (cr, key) {
			var value = globalGetFloat.call(this, cr, key);
			if (isInteresting(key)) {
				console.log("[settings] Global.getFloat key=" + key + " value=" + value);
			}
			return value;
		};
	} catch (e) {
		console.log("[settings] Global.getFloat hook skipped: " + e.message);
	}

	console.log(
		"[settings] Hook active for settings operations (Secure, Global, System — filtered getString/Float, all putInt/putString)",
	);
});
