// Frida script: Log SharedPreferences reads and writes for secrets/token triage.
// Hooks all typed accessors and editor mutations.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-shared-prefs.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-shared-prefs.js

Java.perform(function () {
    var SharedPreferencesImpl = Java.use("android.app.SharedPreferencesImpl");
    var EditorImpl = Java.use("android.app.SharedPreferencesImpl$EditorImpl");

    // ---- Read accessors ----

    try {
        var getString = SharedPreferencesImpl.getString.overload("java.lang.String", "java.lang.String");
        getString.implementation = function (key, defValue) {
            var value = getString.call(this, key, defValue);
            console.log("[shared-prefs:getString] " + key + " = " + value);
            return value;
        };
    } catch (e) {
        console.log("[shared-prefs] getString hook skipped: " + e.message);
    }

    try {
        var getBoolean = SharedPreferencesImpl.getBoolean.overload("java.lang.String", "boolean");
        getBoolean.implementation = function (key, defValue) {
            var value = getBoolean.call(this, key, defValue);
            console.log("[shared-prefs:getBoolean] " + key + " = " + value);
            return value;
        };
    } catch (e) {
        console.log("[shared-prefs] getBoolean hook skipped: " + e.message);
    }

    try {
        var getInt = SharedPreferencesImpl.getInt.overload("java.lang.String", "int");
        getInt.implementation = function (key, defValue) {
            var value = getInt.call(this, key, defValue);
            console.log("[shared-prefs:getInt] " + key + " = " + value);
            return value;
        };
    } catch (e) {
        console.log("[shared-prefs] getInt hook skipped: " + e.message);
    }

    try {
        var getLong = SharedPreferencesImpl.getLong.overload("java.lang.String", "long");
        getLong.implementation = function (key, defValue) {
            var value = getLong.call(this, key, defValue);
            console.log("[shared-prefs:getLong] " + key + " = " + value);
            return value;
        };
    } catch (e) {
        console.log("[shared-prefs] getLong hook skipped: " + e.message);
    }

    try {
        var getFloat = SharedPreferencesImpl.getFloat.overload("java.lang.String", "float");
        getFloat.implementation = function (key, defValue) {
            var value = getFloat.call(this, key, defValue);
            console.log("[shared-prefs:getFloat] " + key + " = " + value);
            return value;
        };
    } catch (e) {
        console.log("[shared-prefs] getFloat hook skipped: " + e.message);
    }

    try {
        var contains = SharedPreferencesImpl.contains.overload("java.lang.String");
        contains.implementation = function (key) {
            var result = contains.call(this, key);
            console.log("[shared-prefs:contains] " + key + " = " + result);
            return result;
        };
    } catch (e) {
        console.log("[shared-prefs] contains hook skipped: " + e.message);
    }

    try {
        var getAll = SharedPreferencesImpl.getAll.overload();
        getAll.implementation = function () {
            var map = getAll.call(this);
            var count = 0;
            var keys = "";
            try {
                var keySet = map.keySet();
                var iter = keySet.iterator();
                var arr = [];
                while (iter.hasNext()) {
                    arr.push(String(iter.next()));
                }
                count = arr.length;
                keys = arr.join(", ");
            } catch (e2) {
                keys = "<error enumerating: " + e2.message + ">";
            }
            console.log("[shared-prefs:getAll] count=" + count + " keys=[" + keys + "]");
            return map;
        };
    } catch (e) {
        console.log("[shared-prefs] getAll hook skipped: " + e.message);
    }

    // ---- Editor mutations ----

    try {
        var putString = EditorImpl.putString.overload("java.lang.String", "java.lang.String");
        putString.implementation = function (key, value) {
            console.log("[shared-prefs:putString] " + key + " = " + value);
            return putString.call(this, key, value);
        };
    } catch (e) {
        console.log("[shared-prefs] putString hook skipped: " + e.message);
    }

    try {
        var putBoolean = EditorImpl.putBoolean.overload("java.lang.String", "boolean");
        putBoolean.implementation = function (key, value) {
            console.log("[shared-prefs:putBoolean] " + key + " = " + value);
            return putBoolean.call(this, key, value);
        };
    } catch (e) {
        console.log("[shared-prefs] putBoolean hook skipped: " + e.message);
    }

    try {
        var putInt = EditorImpl.putInt.overload("java.lang.String", "int");
        putInt.implementation = function (key, value) {
            console.log("[shared-prefs:putInt] " + key + " = " + value);
            return putInt.call(this, key, value);
        };
    } catch (e) {
        console.log("[shared-prefs] putInt hook skipped: " + e.message);
    }

    try {
        var putLong = EditorImpl.putLong.overload("java.lang.String", "long");
        putLong.implementation = function (key, value) {
            console.log("[shared-prefs:putLong] " + key + " = " + value);
            return putLong.call(this, key, value);
        };
    } catch (e) {
        console.log("[shared-prefs] putLong hook skipped: " + e.message);
    }

    try {
        var putFloat = EditorImpl.putFloat.overload("java.lang.String", "float");
        putFloat.implementation = function (key, value) {
            console.log("[shared-prefs:putFloat] " + key + " = " + value);
            return putFloat.call(this, key, value);
        };
    } catch (e) {
        console.log("[shared-prefs] putFloat hook skipped: " + e.message);
    }

    try {
        var remove = EditorImpl.remove.overload("java.lang.String");
        remove.implementation = function (key) {
            console.log("[shared-prefs:remove] " + key);
            return remove.call(this, key);
        };
    } catch (e) {
        console.log("[shared-prefs] remove hook skipped: " + e.message);
    }

    try {
        var clear = EditorImpl.clear.overload();
        clear.implementation = function () {
            console.log("[shared-prefs:clear] (all keys wiped)");
            return clear.call(this);
        };
    } catch (e) {
        console.log("[shared-prefs] clear hook skipped: " + e.message);
    }

    console.log("[shared-prefs] Hook active for SharedPreferences reads/writes (14 accessors)");
});
