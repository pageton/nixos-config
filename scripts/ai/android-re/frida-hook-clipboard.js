// Frida script: Log clipboard read/write operations (ClipboardManager, ClipData).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-clipboard.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-clipboard.js

Java.perform(() => {
	// android.content.ClipboardManager.setPrimaryClip(ClipData)
	try {
		var ClipboardManager = Java.use("android.content.ClipboardManager");
		var setPrimaryClip = ClipboardManager.setPrimaryClip.overload("android.content.ClipData");
		setPrimaryClip.implementation = function (clip) {
			var desc = "?";
			var count = "?";
			try {
				desc = clip.getDescription().toString();
				count = clip.getItemCount();
			} catch (e) {
				desc = "<error>";
			}
			console.log("[clipboard] setPrimaryClip desc=" + desc + " itemCount=" + count);
			return setPrimaryClip.call(this, clip);
		};
	} catch (e) {
		console.log("[clipboard] setPrimaryClip hook skipped: " + e.message);
	}

	// android.content.ClipboardManager.getPrimaryClip()
	try {
		var ClipboardManager2 = Java.use("android.content.ClipboardManager");
		var getPrimaryClip = ClipboardManager2.getPrimaryClip.overload();
		getPrimaryClip.implementation = function () {
			var clip = getPrimaryClip.call(this);
			var desc = "?";
			var count = "?";
			try {
				desc = clip.getDescription().toString();
				count = clip.getItemCount();
			} catch (e) {
				desc = "<null>";
			}
			console.log("[clipboard] getPrimaryClip desc=" + desc + " itemCount=" + count);
			return clip;
		};
	} catch (e) {
		console.log("[clipboard] getPrimaryClip hook skipped: " + e.message);
	}

	// android.content.ClipboardManager.getText() (deprecated but still used)
	try {
		var ClipboardManager3 = Java.use("android.content.ClipboardManager");
		var getText = ClipboardManager3.getText.overload();
		getText.implementation = function () {
			var text = getText.call(this);
			console.log("[clipboard] getText=" + text);
			return text;
		};
	} catch (e) {
		console.log("[clipboard] getText hook skipped: " + e.message);
	}

	// android.content.ClipData.newPlainText(CharSequence, CharSequence)
	try {
		var ClipData = Java.use("android.content.ClipData");
		var newPlainText = ClipData.newPlainText.overload("java.lang.CharSequence", "java.lang.CharSequence");
		newPlainText.implementation = function (label, text) {
			console.log("[clipboard] ClipData.newPlainText label=" + label + " text=" + text);
			return newPlainText.call(this, label, text);
		};
	} catch (e) {
		console.log("[clipboard] ClipData.newPlainText hook skipped: " + e.message);
	}

	// android.content.ClipData.getItemAt(int)
	try {
		var ClipData2 = Java.use("android.content.ClipData");
		var getItemAt = ClipData2.getItemAt.overload("int");
		getItemAt.implementation = function (index) {
			var item = getItemAt.call(this, index);
			var itemText = "?";
			try {
				itemText = item.getText();
			} catch (e) {
				itemText = "<non-text>";
			}
			console.log("[clipboard] ClipData.getItemAt index=" + index + " text=" + itemText);
			return item;
		};
	} catch (e) {
		console.log("[clipboard] ClipData.getItemAt hook skipped: " + e.message);
	}

	console.log(
		"[clipboard] Hook active for clipboard operations (setPrimaryClip, getPrimaryClip, getText, ClipData)",
	);
});
