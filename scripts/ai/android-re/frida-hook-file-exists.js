// Frida script: Log File.exists, File.isFile, and File.canRead checks for
// common root/emulator/frida/debugger indicators.
//
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-file-exists.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-file-exists.js

var WATCH_PATTERNS = [
    "su",
    "/su",
    "magisk",
    "busybox",
    "supersu",
    "superuser",
    "goldfish",
    "qemu",
    "qemud",
    "test-keys",
    "xposed",
    "frida",
    "substrate",
    "cydia",
    "genymotion",
    "vbox",
    "ranchu",
    "generic",
    "sdk_gphone",
    "emulator",
    "/proc/self/maps",
    "tracerpid",
    "init.svc"
];

function matchesPattern(path) {
    var lower = path.toLowerCase();
    for (var i = 0; i < WATCH_PATTERNS.length; i++) {
        if (lower.indexOf(WATCH_PATTERNS[i]) >= 0) {
            return true;
        }
    }
    return false;
}

Java.perform(function () {
    var File = Java.use("java.io.File");

    // -----------------------------------------------------------------------
    // File.exists()
    // -----------------------------------------------------------------------
    try {
        var origExists = File.exists.overload();

        origExists.implementation = function () {
            var path = "<unknown>";
            try {
                path = this.getAbsolutePath();
            } catch (e) {
                path = "<error>";
            }

            var result = origExists.call(this);

            if (matchesPattern(path)) {
                console.log("[file-exists] exists()  " + path + " -> " + result);
            }

            return result;
        };

        console.log("[file-exists] File.exists() hook active");
    } catch (e) {
        console.log("[file-exists] File.exists() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // File.isFile()
    // -----------------------------------------------------------------------
    try {
        var origIsFile = File.isFile.overload();

        origIsFile.implementation = function () {
            var path = "<unknown>";
            try {
                path = this.getAbsolutePath();
            } catch (e) {
                path = "<error>";
            }

            var result = origIsFile.call(this);

            if (matchesPattern(path)) {
                console.log("[file-exists] isFile()  " + path + " -> " + result);
            }

            return result;
        };

        console.log("[file-exists] File.isFile() hook active");
    } catch (e) {
        console.log("[file-exists] File.isFile() hook skipped: " + e.message);
    }

    // -----------------------------------------------------------------------
    // File.canRead()
    // -----------------------------------------------------------------------
    try {
        var origCanRead = File.canRead.overload();

        origCanRead.implementation = function () {
            var path = "<unknown>";
            try {
                path = this.getAbsolutePath();
            } catch (e) {
                path = "<error>";
            }

            var result = origCanRead.call(this);

            if (matchesPattern(path)) {
                console.log("[file-exists] canRead() " + path + " -> " + result);
            }

            return result;
        };

        console.log("[file-exists] File.canRead() hook active");
    } catch (e) {
        console.log("[file-exists] File.canRead() hook skipped: " + e.message);
    }

    console.log("[file-exists] === File probe detection hook loaded ===");
});
