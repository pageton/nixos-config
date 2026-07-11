// Frida script: Log network connections (Socket, SSLSocket, OkHttp, HttpURLConnection,
// Retrofit, SSL factory/verifier overrides, URLConnection).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-network.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-network.js

Java.perform(() => {
	// java.net.Socket.connect (two overloads)
	try {
		var Socket = Java.use("java.net.Socket");
		var InetSocketAddress = Java.use("java.net.InetSocketAddress");
		Socket.connect.overload("java.net.SocketAddress", "int").implementation =
			function (addr, timeout) {
				try {
					var inetAddr = Java.cast(addr, InetSocketAddress);
					console.log(
						"[network:connect] " +
							inetAddr.getHostString() +
							":" +
							inetAddr.getPort() +
							" timeout=" +
							timeout,
					);
				} catch (e) {
					console.log("[network:connect] " + addr + " timeout=" + timeout);
				}
				return this.connect(addr, timeout);
			};
		Socket.connect.overload("java.net.SocketAddress").implementation =
			function (addr) {
				try {
					var inetAddr = Java.cast(addr, InetSocketAddress);
					console.log(
						"[network:connect] " +
							inetAddr.getHostString() +
							":" +
							inetAddr.getPort(),
					);
				} catch (e) {
					console.log("[network:connect] " + addr);
				}
				return this.connect(addr);
			};
	} catch (e) {
		console.log("[network] Socket.connect hook skipped: " + e.message);
	}

	// javax.net.ssl.SSLSocket.startHandshake
	try {
		var SSLSocket = Java.use("javax.net.ssl.SSLSocket");
		SSLSocket.startHandshake.implementation = function () {
			var host = "?";
			var port = 0;
			try {
				var inetAddr = Java.cast(
					this.getInetAddress(),
					Java.use("java.net.InetAddress"),
				);
				host = inetAddr.getHostAddress();
				port = this.getPort();
			} catch (e2) {}
			console.log("[network:tls] handshake start " + host + ":" + port);
			return this.startHandshake();
		};
	} catch (e) {
		console.log(
			"[network] SSLSocket.startHandshake hook skipped: " + e.message,
		);
	}

	// okhttp3.RealCall.execute
	try {
		var RealCall = Java.use("okhttp3.RealCall");
		RealCall.execute.implementation = function () {
			var url = "?";
			var method = "?";
			try {
				var req = this.request();
				url = req.url().toString();
				method = req.method();
			} catch (e2) {}
			console.log("[network:okhttp] " + method + " " + url);
			return this.execute();
		};
	} catch (e) {
		console.log("[network] OkHttp RealCall.execute hook skipped: " + e.message);
	}

	// java.net.HttpURLConnection.connect
	try {
		var HttpURLConnection = Java.use("java.net.HttpURLConnection");
		HttpURLConnection.connect.implementation = function () {
			var url = "?";
			try {
				url = this.getURL().toString();
			} catch (e2) {}
			console.log("[network:http] connect " + url);
			return this.connect();
		};
	} catch (e) {
		console.log(
			"[network] HttpURLConnection.connect hook skipped: " + e.message,
		);
	}

	// okhttp3.Response.code — log HTTP status codes
	try {
		var OkResponse = Java.use("okhttp3.Response");
		OkResponse.code.implementation = function () {
			var code = this.code();
			var url = "?";
			try {
				url = this.request().url().toString();
			} catch (e2) {}
			console.log("[network:okhttp:code] " + code + " " + url);
			return code;
		};
	} catch (e) {
		console.log("[network] okhttp3.Response.code hook skipped: " + e.message);
	}

	// okhttp3.Response.body — log content type and content length (NOT body content)
	try {
		var OkResponse2 = Java.use("okhttp3.Response");
		OkResponse2.body.implementation = function () {
			var url = "?";
			var ct = "?";
			var len = -1;
			try {
				url = this.request().url().toString();
			} catch (e2) {}
			var body = this.body();
			if (body) {
				try {
					var mt = body.contentType();
					if (mt) ct = mt.toString();
				} catch (e2) {}
				try {
					len = body.contentLength();
				} catch (e2) {}
			}
			console.log(
				"[network:okhttp:body] " +
					url +
					" type=" +
					ct +
					" len=" +
					len,
			);
			return body;
		};
	} catch (e) {
		console.log("[network] okhttp3.Response.body hook skipped: " + e.message);
	}

	// okhttp3.OkHttpClient.newCall — log request method + URL
	try {
		var OkHttpClient = Java.use("okhttp3.OkHttpClient");
		OkHttpClient.newCall.implementation = function (request) {
			var method = "?";
			var url = "?";
			try {
				method = request.method();
				url = request.url().toString();
			} catch (e2) {}
			console.log("[network:okhttp:newCall] " + method + " " + url);
			return this.newCall(request);
		};
	} catch (e) {
		console.log(
			"[network] okhttp3.OkHttpClient.newCall hook skipped: " + e.message,
		);
	}

	// java.net.URLConnection.connect — broader than HttpURLConnection
	try {
		var URLConnection = Java.use("java.net.URLConnection");
		URLConnection.connect.implementation = function () {
			var url = "?";
			try {
				url = this.getURL().toString();
			} catch (e2) {}
			console.log("[network:urlconn] connect " + url);
			return this.connect();
		};
	} catch (e) {
		console.log("[network] URLConnection.connect hook skipped: " + e.message);
	}

	// java.net.URLConnection.getInputStream — log when connection opens
	try {
		var URLConnection2 = Java.use("java.net.URLConnection");
		URLConnection2.getInputStream.implementation = function () {
			var url = "?";
			try {
				url = this.getURL().toString();
			} catch (e2) {}
			console.log("[network:urlconn:input] getInputStream " + url);
			return this.getInputStream();
		};
	} catch (e) {
		console.log(
			"[network] URLConnection.getInputStream hook skipped: " + e.message,
		);
	}

	// retrofit2.OkHttpCall.execute — log Retrofit calls if available
	try {
		var RetrofitCall = Java.use("retrofit2.OkHttpCall");
		RetrofitCall.execute.implementation = function () {
			var url = "?";
			var method = "?";
			try {
				var req = this.createRawCall().request();
				url = req.url().toString();
				method = req.method();
			} catch (e2) {}
			console.log("[network:retrofit] execute " + method + " " + url);
			return this.execute();
		};
	} catch (e) {
		console.log(
			"[network] retrofit2.OkHttpCall.execute hook skipped: " + e.message,
		);
	}

	// retrofit2.OkHttpCall.enqueue — log async Retrofit calls
	try {
		var RetrofitCall2 = Java.use("retrofit2.OkHttpCall");
		RetrofitCall2.enqueue.implementation = function (callback) {
			var url = "?";
			var method = "?";
			try {
				var req = this.createRawCall().request();
				url = req.url().toString();
				method = req.method();
			} catch (e2) {}
			console.log("[network:retrofit] enqueue " + method + " " + url);
			return this.enqueue(callback);
		};
	} catch (e) {
		console.log(
			"[network] retrofit2.OkHttpCall.enqueue hook skipped: " + e.message,
		);
	}

	// javax.net.ssl.HttpsURLConnection.setDefaultSSLSocketFactory — log SSL factory override
	try {
		var HttpsConn = Java.use("javax.net.ssl.HttpsURLConnection");
		HttpsConn.setDefaultSSLSocketFactory.implementation = function (factory) {
			console.log(
				"[network:tls:override] setDefaultSSLSocketFactory called — app is replacing default SSLSocketFactory",
			);
			return this.setDefaultSSLSocketFactory(factory);
		};
	} catch (e) {
		console.log(
			"[network] HttpsURLConnection.setDefaultSSLSocketFactory hook skipped: " +
				e.message,
		);
	}

	// javax.net.ssl.HttpsURLConnection.setDefaultHostnameVerifier — log hostname verifier override
	try {
		var HttpsConn2 = Java.use("javax.net.ssl.HttpsURLConnection");
		HttpsConn2.setDefaultHostnameVerifier.implementation = function (verifier) {
			console.log(
				"[network:tls:override] setDefaultHostnameVerifier called — app is replacing default HostnameVerifier",
			);
			return this.setDefaultHostnameVerifier(verifier);
		};
	} catch (e) {
		console.log(
			"[network] HttpsURLConnection.setDefaultHostnameVerifier hook skipped: " +
				e.message,
		);
	}

	console.log(
		"[network] Hook active for network connections (Socket, SSLSocket, OkHttp, HttpURLConnection, URLConnection, Retrofit, TLS overrides)",
	);
});
