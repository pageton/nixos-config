// Frida script: Log ContentResolver operations (query, insert, update, delete,
// call, openInputStream, openOutputStream).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-content-provider.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-content-provider.js

Java.perform(() => {
	// android.content.ContentResolver.query — log URI, projection, selection, sortOrder
	try {
		var ContentResolver = Java.use("android.content.ContentResolver");
		ContentResolver.query.overload(
			"android.net.Uri",
			"[Ljava.lang.String;",
			"java.lang.String",
			"[Ljava.lang.String;",
			"java.lang.String",
		).implementation = function (
			uri,
			projection,
			selection,
			selectionArgs,
			sortOrder,
		) {
			var proj = "none";
			if (projection) {
				proj = projection.length + " cols";
			}
			console.log(
				"[content-provider:query] uri=" +
					uri +
					" selection=" +
					(selection || "none") +
					" projection=" +
					proj +
					" sort=" +
					(sortOrder || "none"),
			);
			return this.query(uri, projection, selection, selectionArgs, sortOrder);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.query hook skipped: " + e.message,
		);
	}

	// android.content.ContentResolver.insert — log URI and key set
	try {
		var ContentResolver2 = Java.use("android.content.ContentResolver");
		ContentResolver2.insert.overload(
			"android.net.Uri",
			"android.content.ContentValues",
		).implementation = function (uri, values) {
			var keys = "none";
			if (values) {
				try {
					var keySet = values.keySet();
					var arr = keySet.toArray();
					keys = arr.join(", ");
				} catch (e2) {}
			}
			console.log(
				"[content-provider:insert] uri=" +
					uri +
					" keys=[" +
					keys +
					"]",
			);
			return this.insert(uri, values);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.insert hook skipped: " + e.message,
		);
	}

	// android.content.ContentResolver.update — log URI and key set
	try {
		var ContentResolver3 = Java.use("android.content.ContentResolver");
		ContentResolver3.update.overload(
			"android.net.Uri",
			"android.content.ContentValues",
			"java.lang.String",
			"[Ljava.lang.String;",
		).implementation = function (uri, values, selection, selectionArgs) {
			var keys = "none";
			if (values) {
				try {
					var keySet = values.keySet();
					var arr = keySet.toArray();
					keys = arr.join(", ");
				} catch (e2) {}
			}
			console.log(
				"[content-provider:update] uri=" +
					uri +
					" keys=[" +
					keys +
					"] selection=" +
					(selection || "none"),
			);
			return this.update(uri, values, selection, selectionArgs);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.update hook skipped: " + e.message,
		);
	}

	// android.content.ContentResolver.delete — log URI and selection
	try {
		var ContentResolver4 = Java.use("android.content.ContentResolver");
		ContentResolver4.delete.overload(
			"android.net.Uri",
			"java.lang.String",
			"[Ljava.lang.String;",
		).implementation = function (uri, selection, selectionArgs) {
			console.log(
				"[content-provider:delete] uri=" +
					uri +
					" selection=" +
					(selection || "none"),
			);
			return this.delete(uri, selection, selectionArgs);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.delete hook skipped: " + e.message,
		);
	}

	// android.content.ContentResolver.call — log URI, method, arg
	try {
		var ContentResolver5 = Java.use("android.content.ContentResolver");
		ContentResolver5.call.overload(
			"android.net.Uri",
			"java.lang.String",
			"java.lang.String",
			"android.os.Bundle",
		).implementation = function (uri, method, arg, extras) {
			console.log(
				"[content-provider:call] uri=" +
					uri +
					" method=" +
					(method || "none") +
					" arg=" +
					(arg || "none"),
			);
			return this.call(uri, method, arg, extras);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.call hook skipped: " + e.message,
		);
	}

	// android.content.ContentResolver.openInputStream — log URI (file access via provider)
	try {
		var ContentResolver6 = Java.use("android.content.ContentResolver");
		ContentResolver6.openInputStream.overload("android.net.Uri").implementation =
			function (uri) {
				console.log(
					"[content-provider:openInputStream] uri=" + uri,
				);
				return this.openInputStream(uri);
			};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.openInputStream hook skipped: " +
				e.message,
		);
	}

	// android.content.ContentResolver.openOutputStream — log URI
	try {
		var ContentResolver7 = Java.use("android.content.ContentResolver");
		ContentResolver7.openOutputStream.overload(
			"android.net.Uri",
		).implementation = function (uri) {
			console.log(
				"[content-provider:openOutputStream] uri=" + uri,
			);
			return this.openOutputStream(uri);
		};
	} catch (e) {
		console.log(
			"[content-provider] ContentResolver.openOutputStream hook skipped: " +
				e.message,
		);
	}

	console.log(
		"[content-provider] Hook active for ContentResolver operations (query, insert, update, delete, call, openInputStream, openOutputStream)",
	);
});
