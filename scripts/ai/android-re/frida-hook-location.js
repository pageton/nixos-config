// Frida script: Log location/GPS access (LocationManager, Location).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-location.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-location.js

Java.perform(() => {
	// android.location.LocationManager.getLastKnownLocation(String)
	try {
		var LocationManager = Java.use("android.location.LocationManager");
		var getLastKnownLocation = LocationManager.getLastKnownLocation.overload("java.lang.String");
		getLastKnownLocation.implementation = function (provider) {
			console.log("[location] getLastKnownLocation provider=" + provider);
			return getLastKnownLocation.call(this, provider);
		};
	} catch (e) {
		console.log("[location] getLastKnownLocation hook skipped: " + e.message);
	}

	// android.location.LocationManager.getCurrentLocation(int, CancellationSignal, Executor, Consumer)
	try {
		var LocationManager2 = Java.use("android.location.LocationManager");
		var getCurrentLocation = LocationManager2.getCurrentLocation.overload(
			"int",
			"android.os.CancellationSignal",
			"java.util.concurrent.Executor",
			"java.util.function.Consumer",
		);
		getCurrentLocation.implementation = function (provider, cancelSig, exec, consumer) {
			console.log("[location] getCurrentLocation providerCode=" + provider);
			return getCurrentLocation.call(this, provider, cancelSig, exec, consumer);
		};
	} catch (e) {
		console.log("[location] getCurrentLocation hook skipped: " + e.message);
	}

	// android.location.LocationManager.requestLocationUpdates(String, long, float, LocationListener)
	try {
		var LocationManager3 = Java.use("android.location.LocationManager");
		var requestUpdates1 = LocationManager3.requestLocationUpdates.overload(
			"java.lang.String",
			"long",
			"float",
			"android.location.LocationListener",
		);
		requestUpdates1.implementation = function (provider, minTime, minDistance, listener) {
			console.log(
				"[location] requestLocationUpdates(Listener) provider=" +
					provider +
					" minTime=" +
					minTime +
					" minDistance=" +
					minDistance,
			);
			return requestUpdates1.call(this, provider, minTime, minDistance, listener);
		};
	} catch (e) {
		console.log("[location] requestLocationUpdates(Listener) hook skipped: " + e.message);
	}

	// android.location.LocationManager.requestLocationUpdates(String, long, float, PendingIntent)
	try {
		var LocationManager4 = Java.use("android.location.LocationManager");
		var requestUpdates2 = LocationManager4.requestLocationUpdates.overload(
			"java.lang.String",
			"long",
			"float",
			"android.app.PendingIntent",
		);
		requestUpdates2.implementation = function (provider, minTime, minDistance, intent) {
			console.log(
				"[location] requestLocationUpdates(PendingIntent) provider=" +
					provider +
					" minTime=" +
					minTime +
					" minDistance=" +
					minDistance,
			);
			return requestUpdates2.call(this, provider, minTime, minDistance, intent);
		};
	} catch (e) {
		console.log("[location] requestLocationUpdates(PendingIntent) hook skipped: " + e.message);
	}

	// android.location.Location.getLatitude()
	try {
		var Location = Java.use("android.location.Location");
		var getLatitude = Location.getLatitude.overload();
		getLatitude.implementation = function () {
			var lat = getLatitude.call(this);
			console.log("[location] getLatitude=" + lat);
			return lat;
		};
	} catch (e) {
		console.log("[location] getLatitude hook skipped: " + e.message);
	}

	// android.location.Location.getLongitude()
	try {
		var Location2 = Java.use("android.location.Location");
		var getLongitude = Location2.getLongitude.overload();
		getLongitude.implementation = function () {
			var lon = getLongitude.call(this);
			console.log("[location] getLongitude=" + lon);
			return lon;
		};
	} catch (e) {
		console.log("[location] getLongitude hook skipped: " + e.message);
	}

	// android.location.Location.getAltitude()
	try {
		var Location3 = Java.use("android.location.Location");
		var getAltitude = Location3.getAltitude.overload();
		getAltitude.implementation = function () {
			var alt = getAltitude.call(this);
			console.log("[location] getAltitude=" + alt);
			return alt;
		};
	} catch (e) {
		console.log("[location] getAltitude hook skipped: " + e.message);
	}

	// android.location.Location.getAccuracy()
	try {
		var Location4 = Java.use("android.location.Location");
		var getAccuracy = Location4.getAccuracy.overload();
		getAccuracy.implementation = function () {
			var acc = getAccuracy.call(this);
			console.log("[location] getAccuracy=" + acc);
			return acc;
		};
	} catch (e) {
		console.log("[location] getAccuracy hook skipped: " + e.message);
	}

	// android.location.LocationManager.isProviderEnabled(String)
	try {
		var LocationManager5 = Java.use("android.location.LocationManager");
		var isProviderEnabled = LocationManager5.isProviderEnabled.overload("java.lang.String");
		isProviderEnabled.implementation = function (provider) {
			var enabled = isProviderEnabled.call(this, provider);
			console.log("[location] isProviderEnabled provider=" + provider + " enabled=" + enabled);
			return enabled;
		};
	} catch (e) {
		console.log("[location] isProviderEnabled hook skipped: " + e.message);
	}

	// android.location.LocationManager.getProviders(boolean)
	try {
		var LocationManager6 = Java.use("android.location.LocationManager");
		var getProviders = LocationManager6.getProviders.overload("boolean");
		getProviders.implementation = function (enabledOnly) {
			var providers = getProviders.call(this, enabledOnly);
			console.log(
				"[location] getProviders enabledOnly=" + enabledOnly + " providers=" + providers,
			);
			return providers;
		};
	} catch (e) {
		console.log("[location] getProviders hook skipped: " + e.message);
	}

	console.log(
		"[location] Hook active for location/GPS operations (LocationManager, Location)",
	);
});
