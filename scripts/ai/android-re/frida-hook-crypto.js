// Frida script: Log cryptographic operations with hex dumps.
// Covers Cipher, Mac, MessageDigest, Signature, KeyGenerator, KeyAgreement,
// SecureRandom, and KeyStore entry/key access.
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-crypto.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-crypto.js

function hexdump_short(byteArray, maxBytes) {
	maxBytes = maxBytes || 64;
	if (!byteArray) return "<null>";
	var len = Math.min(byteArray.length, maxBytes);
	var hex = "";
	for (var i = 0; i < len; i++) {
		var b = (byteArray[i] & 0xff).toString(16);
		hex += b.length === 1 ? "0" + b : b;
	}
	if (byteArray.length > maxBytes)
		hex += "... (" + byteArray.length + " bytes total)";
	return hex;
}

Java.perform(() => {
	// javax.crypto.Cipher
	try {
		var Cipher = Java.use("javax.crypto.Cipher");
		Cipher.init.overload("int", "java.security.Key").implementation = function (
			opmode,
			key,
		) {
			var alg = this.getAlgorithm();
			var mode =
				opmode === 1 ? "ENCRYPT" : opmode === 2 ? "DECRYPT" : String(opmode);
			console.log("[crypto:cipher.init] mode=" + mode + " algorithm=" + alg);
			return this.init(opmode, key);
		};
		Cipher.init.overload(
			"int",
			"java.security.Key",
			"java.security.spec.AlgorithmParameterSpec",
		).implementation = function (opmode, key, params) {
			var alg = this.getAlgorithm();
			var mode =
				opmode === 1 ? "ENCRYPT" : opmode === 2 ? "DECRYPT" : String(opmode);
			console.log(
				"[crypto:cipher.init] mode=" +
					mode +
					" algorithm=" +
					alg +
					" params=" +
					String(params),
			);
			return this.init(opmode, key, params);
		};
		Cipher.doFinal.overload("[B").implementation = function (input) {
			var alg = this.getAlgorithm();
			var inLen = input ? input.length : 0;
			var inHex = hexdump_short(input);
			var result = this.doFinal(input);
			var outLen = result ? result.length : 0;
			var outHex = hexdump_short(result);
			console.log(
				"[crypto:cipher.doFinal] algorithm=" +
					alg +
					" in=" +
					inLen +
					"B out=" +
					outLen +
					"B",
			);
			console.log("[crypto:cipher.doFinal] in_hex=" + inHex);
			console.log("[crypto:cipher.doFinal] out_hex=" + outHex);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Cipher hook skipped: " + e.message);
	}

	// javax.crypto.Mac
	try {
		var Mac = Java.use("javax.crypto.Mac");
		Mac.update.overload("[B").implementation = function (input) {
			console.log(
				"[crypto:mac.update] algorithm=" +
					this.getAlgorithm() +
					" input=" +
					(input ? input.length : 0) +
					"B hex=" +
					hexdump_short(input),
			);
			return this.update(input);
		};
		Mac.doFinal.implementation = function () {
			var result = this.doFinal();
			var outLen = result ? result.length : 0;
			console.log(
				"[crypto:mac.doFinal] algorithm=" +
					this.getAlgorithm() +
					" out=" +
					outLen +
					"B hex=" +
					hexdump_short(result),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Mac hook skipped: " + e.message);
	}

	// java.security.MessageDigest
	try {
		var MessageDigest = Java.use("java.security.MessageDigest");
		MessageDigest.digest.overload("[B").implementation = function (input) {
			var alg = this.getAlgorithm();
			var inHex = hexdump_short(input);
			var result = this.digest(input);
			console.log(
				"[crypto:digest] algorithm=" +
					alg +
					" in=" +
					(input ? input.length : 0) +
					"B in_hex=" +
					inHex,
			);
			console.log(
				"[crypto:digest] algorithm=" + alg + " hash_hex=" + hexdump_short(result),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] MessageDigest hook skipped: " + e.message);
	}

	// java.security.Signature
	try {
		var Signature = Java.use("java.security.Signature");
		Signature.sign.implementation = function () {
			var result = this.sign();
			console.log(
				"[crypto:signature.sign] algorithm=" +
					this.getAlgorithm() +
					" out=" +
					(result ? result.length : 0) +
					"B hex=" +
					hexdump_short(result),
			);
			return result;
		};
		Signature.verify.overload("[B").implementation = function (signature) {
			var result = this.verify(signature);
			console.log(
				"[crypto:signature.verify] algorithm=" +
					this.getAlgorithm() +
					" result=" +
					result +
					" sig_hex=" +
					hexdump_short(signature),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] Signature hook skipped: " + e.message);
	}

	// javax.crypto.KeyGenerator
	try {
		var KeyGenerator = Java.use("javax.crypto.KeyGenerator");
		KeyGenerator.init.overload("int").implementation = function (keysize) {
			console.log(
				"[crypto:keygen.init] algorithm=" +
					this.getAlgorithm() +
					" keysize=" +
					keysize,
			);
			return this.init(keysize);
		};
		KeyGenerator.init.overload(
			"java.security.spec.AlgorithmParameterSpec",
		).implementation = function (params) {
			console.log(
				"[crypto:keygen.init] algorithm=" +
					this.getAlgorithm() +
					" params=" +
					String(params),
			);
			return this.init(params);
		};
		KeyGenerator.generateKey.implementation = function () {
			var key = this.generateKey();
			console.log(
				"[crypto:keygen.generate] algorithm=" +
					this.getAlgorithm() +
					" format=" +
					(key ? key.getFormat() : "?") +
					" encoded_hex=" +
					(key ? hexdump_short(key.getEncoded()) : "<null>"),
			);
			return key;
		};
	} catch (e) {
		console.log("[crypto] KeyGenerator hook skipped: " + e.message);
	}

	// javax.crypto.KeyAgreement
	try {
		var KeyAgreement = Java.use("javax.crypto.KeyAgreement");
		KeyAgreement.init.overload("java.security.Key").implementation = function (
			key,
		) {
			console.log(
				"[crypto:keyagree.init] algorithm=" + this.getAlgorithm(),
			);
			return this.init(key);
		};
		KeyAgreement.doPhase.implementation = function (key, lastPhase) {
			console.log(
				"[crypto:keyagree.doPhase] algorithm=" +
					this.getAlgorithm() +
					" lastPhase=" +
					lastPhase,
			);
			return this.doPhase(key, lastPhase);
		};
		KeyAgreement.generateSecret.overload().implementation = function () {
			var result = this.generateSecret();
			console.log(
				"[crypto:keyagree.secret] algorithm=" +
					this.getAlgorithm() +
					" out=" +
					(result ? result.length : 0) +
					"B hex=" +
					hexdump_short(result),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] KeyAgreement hook skipped: " + e.message);
	}

	// java.security.SecureRandom
	try {
		var SecureRandom = Java.use("java.security.SecureRandom");
		SecureRandom.nextBytes.overload("[B").implementation = function (bytes) {
			var result = this.nextBytes(bytes);
			console.log(
				"[crypto:securerandom.nextBytes] len=" +
					(bytes ? bytes.length : 0) +
					"B hex=" +
					hexdump_short(bytes),
			);
			return result;
		};
	} catch (e) {
		console.log("[crypto] SecureRandom hook skipped: " + e.message);
	}

	// java.security.KeyStore.getEntry / getKey
	try {
		var KeyStore = Java.use("java.security.KeyStore");
		KeyStore.getEntry.implementation = function (alias, param) {
			console.log(
				"[crypto:keystore.getEntry] alias=" +
					alias +
					" type=" +
					this.getType(),
			);
			return this.getEntry(alias, param);
		};
		KeyStore.getKey.implementation = function (alias, password) {
			console.log(
				"[crypto:keystore.getKey] alias=" + alias + " type=" + this.getType(),
			);
			return this.getKey(alias, password);
		};
	} catch (e) {
		console.log("[crypto] KeyStore hook skipped: " + e.message);
	}

	console.log(
		"[crypto] Hook active for crypto operations (Cipher, Mac, MessageDigest, Signature, KeyGenerator, KeyAgreement, SecureRandom, KeyStore)",
	);
});
