// Frida script: Monitor Frida/instrumentation detection attempts.
// Logs common anti-Frida vectors so you can see what an app checks for.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-frida-detection.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-frida-detection.js

var FRIDA_PATH_PATTERNS = ["frida", "re.frida", "frida-server", "frida-agent"];
var PROC_PATHS = ["/proc/self/maps", "/proc/self/status"];
var EXEC_KEYWORDS = ["frida", "ps", "grep frida", "lsof"];
var FRIDA_PORT = 27042;

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
	// java.io.File.exists — frida-related path probes
	try {
		var File = Java.use("java.io.File");
		var FileExists = File.exists.overload();
		FileExists.implementation = function () {
			var path = "";
			try {
				path = this.getAbsolutePath();
			} catch (err) {
				path = "<unknown>";
			}
			var result = FileExists.call(this);
			if (matchesAny(path, FRIDA_PATH_PATTERNS)) {
				console.log(
					"[frida-detect] File.exists() path=" +
						path +
						" result=" +
						result,
				);
			}
			return result;
		};
	} catch (e) {
		console.log("[frida-detect] File.exists hook skipped: " + e.message);
	}

	// java.io.FileInputStream constructor — /proc/self/{maps,status} reads
	try {
		var FileInputStream = Java.use("java.io.FileInputStream");
		var fisInitStr = FileInputStream.$init.overload("java.lang.String");
		fisInitStr.implementation = function (path) {
			if (PROC_PATHS.indexOf(path) >= 0) {
				console.log(
					"[frida-detect] FileInputStream(\"" +
						path +
						"\") — scanning process info",
				);
			}
			return fisInitStr.call(this, path);
		};
		var fisInitFile = FileInputStream.$init.overload("java.io.File");
		fisInitFile.implementation = function (file) {
			var path = "";
			try {
				path = file.getAbsolutePath();
			} catch (err) {
				path = "<unknown>";
			}
			if (PROC_PATHS.indexOf(path) >= 0) {
				console.log(
					"[frida-detect] FileInputStream(File) path=" +
						path +
						" — scanning process info",
				);
			}
			return fisInitFile.call(this, file);
		};
	} catch (e) {
		console.log(
			"[frida-detect] FileInputStream hook skipped: " + e.message,
		);
	}

	// java.io.FileReader constructor — /proc path reads
	try {
		var FileReader = Java.use("java.io.FileReader");
		var frInitStr = FileReader.$init.overload("java.lang.String");
		frInitStr.implementation = function (path) {
			if (path && path.indexOf("/proc/") === 0) {
				console.log(
					"[frida-detect] FileReader(\"" +
						path +
						"\") — reading proc info",
				);
			}
			return frInitStr.call(this, path);
		};
	} catch (e) {
		console.log("[frida-detect] FileReader hook skipped: " + e.message);
	}

	// java.lang.Runtime.exec(String) — frida/ps/grep/lsof commands
	try {
		var Runtime = Java.use("java.lang.Runtime");
		var execStr = Runtime.exec.overload("java.lang.String");
		execStr.implementation = function (cmd) {
			if (matchesAny(String(cmd), EXEC_KEYWORDS)) {
				console.log(
					"[frida-detect] Runtime.exec(\"" +
						cmd +
						"\") — process scanning command",
				);
			}
			return execStr.call(this, cmd);
		};
	} catch (e) {
		console.log("[frida-detect] Runtime.exec hook skipped: " + e.message);
	}

	// java.net.InetSocketAddress constructor — frida default port 27042
	try {
		var InetSocketAddress = Java.use("java.net.InetSocketAddress");
		var isaInitPort = InetSocketAddress.$init.overload("int");
		isaInitPort.implementation = function (port) {
			if (port === FRIDA_PORT) {
				console.log(
					"[frida-detect] InetSocketAddress(" +
						port +
						") — frida default port",
				);
			}
			return isaInitPort.call(this, port);
		};
		var isaInitHost = InetSocketAddress.$init.overload(
			"java.lang.String",
			"int",
		);
		isaInitHost.implementation = function (host, port) {
			if (port === FRIDA_PORT) {
				console.log(
					"[frida-detect] InetSocketAddress(\"" +
						host +
						"\", " +
						port +
						") — frida default port",
				);
			}
			return isaInitHost.call(this, host, port);
		};
	} catch (e) {
		console.log(
			"[frida-detect] InetSocketAddress hook skipped: " + e.message,
		);
	}

	// java.net.Socket.connect(SocketAddress, int) — frida default port 27042
	try {
		var Socket = Java.use("java.net.Socket");
		var sockConnect = Socket.connect.overload(
			"java.net.SocketAddress",
			"int",
		);
		sockConnect.implementation = function (addr, timeout) {
			var port = -1;
			var host = "";
			try {
				var inetAddr = Java.cast(addr, InetSocketAddress);
				host = inetAddr.getHostString();
				port = inetAddr.getPort();
			} catch (err) {
				host = String(addr);
			}
			if (port === FRIDA_PORT) {
				console.log(
					"[frida-detect] Socket.connect(" +
						host +
						":" +
						port +
						", timeout=" +
						timeout +
						") — frida default port",
				);
			}
			return sockConnect.call(this, addr, timeout);
		};
	} catch (e) {
		console.log(
			"[frida-detect] Socket.connect hook skipped: " + e.message,
		);
	}

	// android.app.ActivityManager.getRunningAppProcesses — process list scan
	try {
		var ActivityManager = Java.use("android.app.ActivityManager");
		var getRunning = ActivityManager.getRunningAppProcesses.overload();
		getRunning.implementation = function () {
			console.log(
				"[frida-detect] ActivityManager.getRunningAppProcesses() called — process list scan",
			);
			return getRunning.call(this);
		};
	} catch (e) {
		console.log(
			"[frida-detect] ActivityManager.getRunningAppProcesses hook skipped: " +
				e.message,
		);
	}

	// java.lang.Thread.enumerate — thread scanning
	try {
		var Thread = Java.use("java.lang.Thread");
		var threadEnum = Thread.enumerate.overload(
			"[Ljava.lang.Thread;",
		);
		threadEnum.implementation = function (threads) {
			var count = threadEnum.call(this, threads);
			console.log(
				"[frida-detect] Thread.enumerate() — found " +
					count +
					" threads (frida thread scan)",
			);
			return count;
		};
	} catch (e) {
		console.log("[frida-detect] Thread.enumerate hook skipped: " + e.message);
	}

	// dalvik.system.DexFile constructor — dynamic detection code loading
	try {
		var DexFile = Java.use("dalvik.system.DexFile");
		var dfInitStr = DexFile.$init.overload("java.lang.String");
		dfInitStr.implementation = function (path) {
			console.log(
				"[frida-detect] DexFile(\"" +
					path +
					"\") — loading detection dex dynamically",
			);
			return dfInitStr.call(this, path);
		};
	} catch (e) {
		console.log("[frida-detect] DexFile hook skipped: " + e.message);
	}

	console.log(
		"[frida-detect] Hook active for frida detection vectors (File, FileInputStream, FileReader, Runtime, Socket, ActivityManager, Thread, DexFile)",
	);
});
