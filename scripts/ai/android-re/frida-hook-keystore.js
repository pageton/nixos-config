// Frida script: Log Android Keystore operations — key generation, store/load, entry access.
// Use to trace which aliases an app reads/writes and what key parameters it configures.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-keystore.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-keystore.js

Java.perform(() => {
	// java.security.KeyStore.getInstance — log keystore type
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		KeyStore.getInstance.overload("java.lang.String").implementation = function (
			type,
		) {
			console.log("[keystore:getInstance] type=" + type);
			return this.getInstance(type);
		};
	} catch (e) {
		console.log("[keystore] KeyStore.getInstance(String) hook skipped: " + e.message);
	}

	// java.security.KeyStore.load — log store load
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		var LoadStoreParameter = Java.use(
			"java.security.KeyStore$LoadStoreParameter",
		);
		KeyStore.load.overload(
			"java.security.KeyStore$LoadStoreParameter",
		).implementation = function (param) {
			var type = "?";
			try {
				type = this.getType();
			} catch (e2) {}
			console.log("[keystore:load] type=" + type + " param=" + String(param));
			return this.load(param);
		};
	} catch (e) {
		console.log("[keystore] KeyStore.load hook skipped: " + e.message);
	}

	// java.security.KeyStore.getEntry — log alias
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		KeyStore.getEntry.implementation = function (alias, param) {
			var type = "?";
			try {
				type = this.getType();
			} catch (e2) {}
			console.log(
				"[keystore:getEntry] type=" + type + " alias=" + alias,
			);
			return this.getEntry(alias, param);
		};
	} catch (e) {
		console.log("[keystore] KeyStore.getEntry hook skipped: " + e.message);
	}

	// java.security.KeyStore.getKey — log alias
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		KeyStore.getKey.implementation = function (alias, password) {
			var type = "?";
			try {
				type = this.getType();
			} catch (e2) {}
			console.log("[keystore:getKey] type=" + type + " alias=" + alias);
			return this.getKey(alias, password);
		};
	} catch (e) {
		console.log("[keystore] KeyStore.getKey hook skipped: " + e.message);
	}

	// java.security.KeyStore.setEntry — log alias and entry type
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		KeyStore.setEntry.implementation = function (alias, entry, param) {
			var type = "?";
			var entryType = "?";
			try {
				type = this.getType();
			} catch (e2) {}
			try {
				entryType = entry.getClass().getName();
			} catch (e2) {}
			console.log(
				"[keystore:setEntry] type=" +
					type +
					" alias=" +
					alias +
					" entryType=" +
					entryType,
			);
			return this.setEntry(alias, entry, param);
		};
	} catch (e) {
		console.log("[keystore] KeyStore.setEntry hook skipped: " + e.message);
	}

	// android.security.keystore.KeyGenParameterSpec$Builder — log key generation config
	try {
		var Builder = Java.use(
			"android.security.keystore.KeyGenParameterSpec$Builder",
		);
		Builder.build.implementation = function () {
			var spec = this.build();
			var purpose = "?";
			var blockModes = "?";
			var paddings = "?";
			try {
				purpose = String(spec.getPurposes());
			} catch (e2) {}
			try {
				var modes = spec.getBlockModes();
				blockModes = modes ? modes.join(",") : "none";
			} catch (e2) {}
			try {
				var pads = spec.getEncryptionPaddings();
				paddings = pads ? pads.join(",") : "none";
			} catch (e2) {}
			console.log(
				"[keystore:keygen.build] purpose=" +
					purpose +
					" blockModes=[" +
					blockModes +
					"] encryptionPaddings=[" +
					paddings +
					"]",
			);
			return spec;
		};
	} catch (e) {
		console.log(
			"[keystore] KeyGenParameterSpec$Builder hook skipped: " + e.message,
		);
	}

	// android.security.keystore.KeyProperties — log references to constants
	try {
		var KeyProperties = Java.use("android.security.keystore.KeyProperties");
		// KeyProperties is a constants class; log that it was loaded
		console.log(
			"[keystore:keyproperties] KeyProperties class referenced (constants class loaded)",
		);
	} catch (e) {
		console.log("[keystore] KeyProperties hook skipped: " + e.message);
	}

	console.log(
		"[keystore] Hook active for Android Keystore operations (getInstance, load, getEntry, getKey, setEntry, KeyGenParameterSpec, KeyProperties)",
	);
});
