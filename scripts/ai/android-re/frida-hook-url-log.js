// Frida script: Log URL/URI construction (java.net.URL, java.net.URI, OkHttp
// Request/HttpUrl builders, WebView.loadUrl).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-url-log.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-url-log.js

Java.perform(function () {
	// java.net.URL.$init(String) — most common URL constructor
	try {
		var URL = Java.use("java.net.URL");
		var urlInitString = URL.$init.overload("java.lang.String");
		urlInitString.implementation = function (url) {
			console.log("[url-log:url] " + url);
			return urlInitString.call(this, url);
		};
	} catch (e) {
		console.log("[url-log] URL.$init(String) hook skipped: " + e.message);
	}

	// okhttp3.Request$Builder.url(String) — OkHttp request URL builder
	try {
		var RequestBuilder = Java.use("okhttp3.Request$Builder");
		var requestBuilderUrl = RequestBuilder.url.overload("java.lang.String");
		requestBuilderUrl.implementation = function (url) {
			console.log("[url-log:okhttp] " + url);
			return requestBuilderUrl.call(this, url);
		};
	} catch (e) {
		console.log(
			"[url-log] okhttp3.Request$Builder.url(String) hook skipped: " +
				e.message,
		);
	}

	// java.net.URL.$init(String, String, int, String) — protocol, host, port, file
	try {
		var URL2 = Java.use("java.net.URL");
		var urlInit4 = URL2.$init.overload(
			"java.lang.String",
			"java.lang.String",
			"int",
			"java.lang.String",
		);
		urlInit4.implementation = function (protocol, host, port, file) {
			console.log(
				"[url-log:url] " +
					protocol +
					"://" +
					host +
					":" +
					port +
					file,
			);
			return urlInit4.call(this, protocol, host, port, file);
		};
	} catch (e) {
		console.log(
			"[url-log] URL.$init(String,String,int,String) hook skipped: " +
				e.message,
		);
	}

	// java.net.URL.$init(String, String, String) — protocol, host, file (default port)
	try {
		var URL3 = Java.use("java.net.URL");
		var urlInit3 = URL3.$init.overload(
			"java.lang.String",
			"java.lang.String",
			"java.lang.String",
		);
		urlInit3.implementation = function (protocol, host, file) {
			console.log(
				"[url-log:url] " + protocol + "://" + host + file,
			);
			return urlInit3.call(this, protocol, host, file);
		};
	} catch (e) {
		console.log(
			"[url-log] URL.$init(String,String,String) hook skipped: " +
				e.message,
		);
	}

	// java.net.URL.$init(URL, String) — context URL + spec (relative resolution)
	try {
		var URL4 = Java.use("java.net.URL");
		var urlInitContext = URL4.$init.overload(
			"java.net.URL",
			"java.lang.String",
		);
		urlInitContext.implementation = function (context, spec) {
			var ctx = "?";
			try {
				if (context) ctx = context.toString();
			} catch (e2) {}
			console.log("[url-log:url] context=" + ctx + " spec=" + spec);
			return urlInitContext.call(this, context, spec);
		};
	} catch (e) {
		console.log(
			"[url-log] URL.$init(URL,String) hook skipped: " + e.message,
		);
	}

	// java.net.URI(String) — log URI construction
	try {
		var URI = Java.use("java.net.URI");
		var uriInitString = URI.$init.overload("java.lang.String");
		uriInitString.implementation = function (uri) {
			console.log("[url-log:uri] " + uri);
			return uriInitString.call(this, uri);
		};
	} catch (e) {
		console.log("[url-log] URI.$init(String) hook skipped: " + e.message);
	}

	// java.net.URI(String, String, String, int, String, String, String) — full 7-arg constructor
	// (scheme, userInfo, host, port, path, query, fragment)
	try {
		var URI2 = Java.use("java.net.URI");
		var uriInit7 = URI2.$init.overload(
			"java.lang.String",
			"java.lang.String",
			"java.lang.String",
			"int",
			"java.lang.String",
			"java.lang.String",
			"java.lang.String",
		);
		uriInit7.implementation = function (
			scheme,
			userInfo,
			host,
			port,
			path,
			query,
			fragment,
		) {
			console.log(
				"[url-log:uri] " +
					scheme +
					"://" +
					(userInfo || "") +
					host +
					":" +
					port +
					path +
					(query ? "?" + query : "") +
					(fragment ? "#" + fragment : ""),
			);
			return uriInit7.call(
				this,
				scheme,
				userInfo,
				host,
				port,
				path,
				query,
				fragment,
			);
		};
	} catch (e) {
		console.log(
			"[url-log] URI.$init(7-arg) hook skipped: " + e.message,
		);
	}

	// android.webkit.WebView.loadUrl — log URL for correlation
	try {
		var WebView = Java.use("android.webkit.WebView");
		WebView.loadUrl.overload("java.lang.String").implementation = function (
			url,
		) {
			console.log("[url-log:webview] loadUrl " + url);
			return this.loadUrl(url);
		};
	} catch (e) {
		console.log("[url-log] WebView.loadUrl hook skipped: " + e.message);
	}

	// okhttp3.HttpUrl.parse(String) — log OkHttp URL parsing
	try {
		var HttpUrl = Java.use("okhttp3.HttpUrl");
		var httpUrlParse = HttpUrl.parse.overload("java.lang.String");
		httpUrlParse.implementation = function (url) {
			console.log("[url-log:okhttp:parse] " + url);
			return httpUrlParse.call(this, url);
		};
	} catch (e) {
		console.log("[url-log] okhttp3.HttpUrl.parse hook skipped: " + e.message);
	}

	// okhttp3.HttpUrl$Builder.build — log final URL
	try {
		var HttpUrlBuilder = Java.use("okhttp3.HttpUrl$Builder");
		HttpUrlBuilder.build.implementation = function () {
			var result = this.build();
			var url = "?";
			try {
				url = result.toString();
			} catch (e2) {}
			console.log("[url-log:okhttp:build] " + url);
			return result;
		};
	} catch (e) {
		console.log(
			"[url-log] okhttp3.HttpUrl$Builder.build hook skipped: " +
				e.message,
		);
	}

	console.log(
		"[url-log] Hook active for URL/URI construction (URL, URI, OkHttp, WebView)",
	);
});
