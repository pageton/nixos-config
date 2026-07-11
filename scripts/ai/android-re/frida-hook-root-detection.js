// Frida script: Log common root/emulator/debugger detection vectors.
// Captures command execution, package enumeration, debugger state, system
// properties, telephony identifiers, and /proc file reads.
//
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-root-detection.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-root-detection.js

Java.perform(function () {

    // -----------------------------------------------------------------------
    // 1. Runtime.exec(String) — log commands containing root/debug keywords
    // -----------------------------------------------------------------------
    try {
        var Runtime = Java.use("java.lang.Runtime");
        var execStr = Runtime.exec.overload("java.lang.String");

        execStr.implementation = function (cmd) {
            var lower = (cmd || "").toLowerCase();
            if (lower.indexOf("su") >= 0 ||
                lower.indexOf("which") >= 0 ||
                lower.indexOf("busybox") >= 0 ||
                lower.indexOf("magisk") >= 0) {
                console.log("[root-detect] Runtime.exec(\"" + cmd + "\")");
            }
            return execStr.call(this, cmd);
        };

        console.log("[root-detect] Runtime.exec(String) hook active");
    } catch (e) {
        console.log("[root-detect] Runtime.exec(String) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 2. Runtime.exec(String[]) — log command arrays containing keywords
    // -----------------------------------------------------------------------
    try {
        var Runtime2 = Java.use("java.lang.Runtime");
        var execArr = Runtime2.exec.overload("java.lang.String[]");

        execArr.implementation = function (cmdArray) {
            var joined = "";
            try {
                joined = cmdArray.join(" ");
            } catch (e2) {
                joined = "<join failed>";
            }
            var lower = joined.toLowerCase();
            if (lower.indexOf("su") >= 0 ||
                lower.indexOf("which") >= 0 ||
                lower.indexOf("busybox") >= 0 ||
                lower.indexOf("magisk") >= 0) {
                console.log("[root-detect] Runtime.exec([\"" + joined + "\"])");
            }
            return execArr.call(this, cmdArray);
        };

        console.log("[root-detect] Runtime.exec(String[]) hook active");
    } catch (e) {
        console.log("[root-detect] Runtime.exec(String[]) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 3. PackageManager.getInstalledPackages(int) — log suspicious packages
    // -----------------------------------------------------------------------
    try {
        var PackageManager = Java.use("android.content.pm.PackageManager");
        var getInstalledPackages = PackageManager.getInstalledPackages.overload("int");

        getInstalledPackages.implementation = function (flags) {
            var packages = getInstalledPackages.call(this, flags);

            try {
                var keywords = ["root", "frida", "magisk", "xposed", "supersu", "busybox", "substrate", "cydia"];
                var size = packages.size();
                for (var i = 0; i < size; i++) {
                    var pkgName = packages.get(i).packageName.value;
                    if (pkgName) {
                        var lower = pkgName.toLowerCase();
                        for (var k = 0; k < keywords.length; k++) {
                            if (lower.indexOf(keywords[k]) >= 0) {
                                console.log("[root-detect] Suspicious package installed: " + pkgName);
                                break;
                            }
                        }
                    }
                }
            } catch (e2) {
                console.log("[root-detect] getInstalledPackages scan error: " + e2.message);
            }

            return packages;
        };

        console.log("[root-detect] PackageManager.getInstalledPackages hook active");
    } catch (e) {
        console.log("[root-detect] PackageManager.getInstalledPackages hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 4. Debug.isDebuggerConnected() — log return value
    // -----------------------------------------------------------------------
    try {
        var Debug = Java.use("android.os.Debug");
        var isDebuggerConnected = Debug.isDebuggerConnected.overload();

        isDebuggerConnected.implementation = function () {
            var result = isDebuggerConnected.call(this);
            console.log("[root-detect] Debug.isDebuggerConnected() -> " + result);
            return result;
        };

        console.log("[root-detect] Debug.isDebuggerConnected() hook active");
    } catch (e) {
        console.log("[root-detect] Debug.isDebuggerConnected() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 5. Settings.Secure.getString — log dev/adb settings
    // -----------------------------------------------------------------------
    try {
        var Settings = Java.use("android.provider.Settings$Secure");
        var getString = Settings.getString.overload(
            "android.content.ContentResolver",
            "java.lang.String"
        );

        getString.implementation = function (cr, name) {
            var result = getString.call(this, cr, name);
            if (name) {
                var lower = name.toLowerCase();
                if (lower.indexOf("development_settings") >= 0 ||
                    lower.indexOf("adb_enabled") >= 0) {
                    console.log("[root-detect] Settings.Secure.getString(\"" + name + "\") -> " + result);
                }
            }
            return result;
        };

        console.log("[root-detect] Settings.Secure.getString hook active");
    } catch (e) {
        console.log("[root-detect] Settings.Secure.getString hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 6. TelephonyManager.getDeviceId() — emulator IMEI patterns
    // -----------------------------------------------------------------------
    try {
        var TelephonyManager = Java.use("android.telephony.TelephonyManager");
        var getDeviceId = TelephonyManager.getDeviceId.overload();

        getDeviceId.implementation = function () {
            var result = getDeviceId.call(this);
            console.log("[root-detect] TelephonyManager.getDeviceId() -> " + result);
            return result;
        };

        console.log("[root-detect] TelephonyManager.getDeviceId() hook active");
    } catch (e) {
        console.log("[root-detect] TelephonyManager.getDeviceId() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 7. TelephonyManager.getSubscriberId()
    // -----------------------------------------------------------------------
    try {
        var TelephonyManager2 = Java.use("android.telephony.TelephonyManager");
        var getSubscriberId = TelephonyManager2.getSubscriberId.overload();

        getSubscriberId.implementation = function () {
            var result = getSubscriberId.call(this);
            console.log("[root-detect] TelephonyManager.getSubscriberId() -> " + result);
            return result;
        };

        console.log("[root-detect] TelephonyManager.getSubscriberId() hook active");
    } catch (e) {
        console.log("[root-detect] TelephonyManager.getSubscriberId() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 8. TelephonyManager.getLine1Number()
    // -----------------------------------------------------------------------
    try {
        var TelephonyManager3 = Java.use("android.telephony.TelephonyManager");
        var getLine1Number = TelephonyManager3.getLine1Number.overload();

        getLine1Number.implementation = function () {
            var result = getLine1Number.call(this);
            console.log("[root-detect] TelephonyManager.getLine1Number() -> " + result);
            return result;
        };

        console.log("[root-detect] TelephonyManager.getLine1Number() hook active");
    } catch (e) {
        console.log("[root-detect] TelephonyManager.getLine1Number() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 9. FileInputStream constructor — /proc/self/status, /proc/self/maps
    // -----------------------------------------------------------------------
    try {
        var FileInputStream = Java.use("java.io.FileInputStream");
        var fisCtor = FileInputStream.$init.overload("java.lang.String");

        fisCtor.implementation = function (path) {
            if (path) {
                var lower = path.toLowerCase();
                if (lower.indexOf("/proc/self/status") >= 0 ||
                    lower.indexOf("/proc/self/maps") >= 0 ||
                    lower.indexOf("/proc/") >= 0) {
                    console.log("[root-detect] FileInputStream(\"" + path + "\")");
                }
            }
            return fisCtor.call(this, path);
        };

        console.log("[root-detect] FileInputStream(String) hook active");
    } catch (e) {
        console.log("[root-detect] FileInputStream(String) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 10. System.getProperty(String) — ro.kernel.qemu and similar
    // -----------------------------------------------------------------------
    try {
        var System = Java.use("java.lang.System");
        var getProperty = System.getProperty.overload("java.lang.String");

        getProperty.implementation = function (key) {
            var result = getProperty.call(this, key);
            if (key) {
                var lower = key.toLowerCase();
                if (lower.indexOf("qemu") >= 0 ||
                    lower.indexOf("ro.kernel") >= 0 ||
                    lower.indexOf("init.svc") >= 0 ||
                    lower.indexOf("ro.build") >= 0) {
                    console.log("[root-detect] System.getProperty(\"" + key + "\") -> " + result);
                }
            }
            return result;
        };

        console.log("[root-detect] System.getProperty(String) hook active");
    } catch (e) {
        console.log("[root-detect] System.getProperty(String) hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // 11. FileReader constructor — /proc/ paths
    // -----------------------------------------------------------------------
    try {
        var FileReader = Java.use("java.io.FileReader");
        var frCtor = FileReader.$init.overload("java.lang.String");

        frCtor.implementation = function (path) {
            if (path) {
                var lower = path.toLowerCase();
                if (lower.indexOf("/proc/") >= 0) {
                    console.log("[root-detect] FileReader(\"" + path + "\")");
                }
            }
            return frCtor.call(this, path);
        };

        console.log("[root-detect] FileReader(String) hook active");
    } catch (e) {
        console.log("[root-detect] FileReader(String) hook skipped: " + e.message);
    }

    console.log("[root-detect] === Root/emulator/debugger detection hook loaded ===");
});
