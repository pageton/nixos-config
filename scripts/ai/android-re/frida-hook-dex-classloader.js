// Frida script: Monitor dynamic code loading (DexClassLoader, PathClassLoader,
// DexFile, InMemoryDexClassLoader, ClassLoader, Runtime, File).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-dex-classloader.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-dex-classloader.js

var DEX_FILE_PATTERNS = [".dex", ".odex", ".oat", ".jar"];
var EXEC_KEYWORDS = ["dexopt", "dalvikvm", "app_process"];
var SUSPICIOUS_PACKAGES = ["com.google", "dex", "vmo", "xposed"];

function matchesAny(text, patterns) {
	if (!text) {
		return false;
	}
	var lower = text.toLowerCase();
	for (var i = 0; i < patterns.length; i++) {
		if (lower.indexOf(patterns[i]) >= 0) {
			return true;
		}
	}
	return false;
}

Java.perform(() => {
	// dalvik.system.DexClassLoader.$init(String, String, String, ClassLoader)
	try {
		var DexClassLoader = Java.use("dalvik.system.DexClassLoader");
		var dclInit = DexClassLoader.$init.overload(
			"java.lang.String",
			"java.lang.String",
			"java.lang.String",
			"java.lang.ClassLoader",
		);
		dclInit.implementation = function (
			dexPath,
			optimizedDir,
			libraryPath,
			parent,
		) {
			console.log(
				"[dex-loader] DexClassLoader(dexPath=" +
					dexPath +
					", optimizedDir=" +
					optimizedDir +
					", libPath=" +
					libraryPath +
					", parent=" +
					parent +
					")",
			);
			return dclInit.call(this, dexPath, optimizedDir, libraryPath, parent);
		};
	} catch (e) {
		console.log(
			"[dex-loader] DexClassLoader hook skipped: " + e.message,
		);
	}

	// dalvik.system.PathClassLoader.$init(String, String, ClassLoader)
	try {
		var PathClassLoader = Java.use("dalvik.system.PathClassLoader");
		var pclInit = PathClassLoader.$init.overload(
			"java.lang.String",
			"java.lang.String",
			"java.lang.ClassLoader",
		);
		pclInit.implementation = function (dexPath, libPath, parent) {
			console.log(
				"[dex-loader] PathClassLoader(dexPath=" +
					dexPath +
					", libPath=" +
					libPath +
					", parent=" +
					parent +
					")",
			);
			return pclInit.call(this, dexPath, libPath, parent);
		};
	} catch (e) {
		console.log(
			"[dex-loader] PathClassLoader hook skipped: " + e.message,
		);
	}

	// dalvik.system.DexFile.$init(String)
	try {
		var DexFile = Java.use("dalvik.system.DexFile");
		var dfInit = DexFile.$init.overload("java.lang.String");
		dfInit.implementation = function (path) {
			console.log("[dex-loader] DexFile(\"" + path + "\")");
			return dfInit.call(this, path);
		};
	} catch (e) {
		console.log("[dex-loader] DexFile hook skipped: " + e.message);
	}

	// dalvik.system.DexFile.loadDex(String, File, int)
	try {
		var DexFile2 = Java.use("dalvik.system.DexFile");
		var loadDex = DexFile2.loadDex.overload(
			"java.lang.String",
			"java.io.File",
			"int",
		);
		loadDex.implementation = function (sourcePathName, outputPathName, flags) {
			console.log(
				"[dex-loader] DexFile.loadDex(source=" +
					sourcePathName +
					", output=" +
					outputPathName +
					", flags=" +
					flags +
					")",
			);
			return loadDex.call(this, sourcePathName, outputPathName, flags);
		};
	} catch (e) {
		console.log(
			"[dex-loader] DexFile.loadDex hook skipped: " + e.message,
		);
	}

	// dalvik.system.InMemoryDexClassLoader.$init(ByteBuffer[], ClassLoader) — Android 8+
	try {
		var InMemoryDexClassLoader = Java.use(
			"dalvik.system.InMemoryDexClassLoader",
		);
		var imdclInit = InMemoryDexClassLoader.$init.overload(
			"[Ljava.nio.ByteBuffer;",
			"java.lang.ClassLoader",
		);
		imdclInit.implementation = function (dexBuffers, parent) {
			var count = dexBuffers ? dexBuffers.length : 0;
			console.log(
				"[dex-loader] InMemoryDexClassLoader(byteBuffers=" +
					count +
					", parent=" +
					parent +
					") — in-memory dex loading",
			);
			return imdclInit.call(this, dexBuffers, parent);
		};
	} catch (e) {
		console.log(
			"[dex-loader] InMemoryDexClassLoader hook skipped: " + e.message,
		);
	}

	// java.lang.ClassLoader.loadClass(String) — filter suspicious package names
	try {
		var ClassLoader = Java.use("java.lang.ClassLoader");
		var loadClass = ClassLoader.loadClass.overload("java.lang.String");
		loadClass.implementation = function (name) {
			if (matchesAny(name, SUSPICIOUS_PACKAGES)) {
				console.log(
					"[dex-loader] ClassLoader.loadClass(\"" +
						name +
						"\") — suspicious class name",
				);
			}
			return loadClass.call(this, name);
		};
	} catch (e) {
		console.log(
			"[dex-loader] ClassLoader.loadClass hook skipped: " + e.message,
		);
	}

	// java.lang.Runtime.exec(String) — runtime compilation commands
	try {
		var Runtime = Java.use("java.lang.Runtime");
		var execStr = Runtime.exec.overload("java.lang.String");
		execStr.implementation = function (cmd) {
			if (matchesAny(String(cmd), EXEC_KEYWORDS)) {
				console.log(
					"[dex-loader] Runtime.exec(\"" +
						cmd +
						"\") — runtime compilation command",
				);
			}
			return execStr.call(this, cmd);
		};
	} catch (e) {
		console.log(
			"[dex-loader] Runtime.exec hook skipped: " + e.message,
		);
	}

	// java.io.File constructor — dex file creation
	try {
		var File = Java.use("java.io.File");
		var fileInitStr = File.$init.overload("java.lang.String");
		fileInitStr.implementation = function (path) {
			if (matchesAny(path, DEX_FILE_PATTERNS)) {
				console.log(
					"[dex-loader] File(\"" + path + "\") — dex file creation",
				);
			}
			return fileInitStr.call(this, path);
		};
	} catch (e) {
		console.log("[dex-loader] File constructor hook skipped: " + e.message);
	}

	console.log(
		"[dex-loader] Hook active for dynamic code loading (DexClassLoader, PathClassLoader, DexFile, InMemoryDexClassLoader, ClassLoader, Runtime, File)",
	);
});
