// Frida script: Log SQLite database operations (open, execSQL, query, rawQuery,
// insert, update, delete).
// Usage:
//   frida -U -n com.example.target -l scripts/ai/android-re/frida-hook-sqlite.js -q
//   frida -U -f com.example.target -l scripts/ai/android-re/frida-hook-sqlite.js

var DML_KEYWORDS = ["CREATE", "INSERT", "UPDATE", "DELETE", "DROP"];

function matchesAny(text, patterns) {
	if (!text) {
		return false;
	}
	var upper = text.toUpperCase();
	for (var i = 0; i < patterns.length; i++) {
		if (upper.indexOf(patterns[i]) >= 0) {
			return true;
		}
	}
	return false;
}

function contentValuesKeys(cv) {
	if (!cv) {
		return "<null>";
	}
	try {
		var KeySet = Java.use("android.content.ContentValues");
		var casted = Java.cast(cv, KeySet);
		return casted.keySet().toArray().join(", ");
	} catch (err) {
		return "<unknown>";
	}
}

Java.perform(() => {
	// SQLiteDatabase.openDatabase(String, CursorFactory, int)
	try {
		var SQLiteDatabase = Java.use("android.database.sqlite.SQLiteDatabase");
		var openDb = SQLiteDatabase.openDatabase.overload(
			"java.lang.String",
			"android.database.sqlite.SQLiteDatabase$CursorFactory",
			"int",
		);
		openDb.implementation = function (path, factory, flags) {
			console.log(
				"[sqlite:openDatabase] path=" + path + " flags=" + flags,
			);
			return openDb.call(this, path, factory, flags);
		};
	} catch (e) {
		console.log("[sqlite] openDatabase hook skipped: " + e.message);
	}

	// SQLiteDatabase.openOrCreateDatabase(String, CursorFactory)
	try {
		var SQLiteDatabase2 = Java.use("android.database.sqlite.SQLiteDatabase");
		var openOrCreate = SQLiteDatabase2.openOrCreateDatabase.overload(
			"java.lang.String",
			"android.database.sqlite.SQLiteDatabase$CursorFactory",
		);
		openOrCreate.implementation = function (path, factory) {
			console.log("[sqlite:openOrCreate] path=" + path);
			return openOrCreate.call(this, path, factory);
		};
	} catch (e) {
		console.log(
			"[sqlite] openOrCreateDatabase hook skipped: " + e.message,
		);
	}

	// SQLiteDatabase.execSQL(String)
	try {
		var SQLiteDatabase3 = Java.use("android.database.sqlite.SQLiteDatabase");
		var execSql = SQLiteDatabase3.execSQL.overload("java.lang.String");
		execSql.implementation = function (sql) {
			if (matchesAny(sql, DML_KEYWORDS)) {
				console.log("[sqlite:execSQL] " + sql);
			}
			return execSql.call(this, sql);
		};
	} catch (e) {
		console.log("[sqlite] execSQL(String) hook skipped: " + e.message);
	}

	// SQLiteDatabase.execSQL(String, Object[])
	try {
		var SQLiteDatabase4 = Java.use("android.database.sqlite.SQLiteDatabase");
		var execSqlArgs = SQLiteDatabase4.execSQL.overload(
			"java.lang.String",
			"[Ljava.lang.Object;",
		);
		execSqlArgs.implementation = function (sql, bindArgs) {
			if (matchesAny(sql, DML_KEYWORDS)) {
				console.log(
					"[sqlite:execSQL] " +
						sql +
						" args=[" +
						(bindArgs ? bindArgs.join(", ") : "") +
						"]",
				);
			}
			return execSqlArgs.call(this, sql, bindArgs);
		};
	} catch (e) {
		console.log("[sqlite] execSQL(String, Object[]) hook skipped: " + e.message);
	}

	// SQLiteDatabase.query(table, columns, selection, selectionArgs, groupBy, having, orderBy)
	try {
		var SQLiteDatabase5 = Java.use("android.database.sqlite.SQLiteDatabase");
		var query = SQLiteDatabase5.query.overload(
			"java.lang.String",
			"[Ljava.lang.String;",
			"java.lang.String",
			"[Ljava.lang.String;",
			"java.lang.String",
			"java.lang.String",
			"java.lang.String",
		);
		query.implementation = function (
			table,
			columns,
			selection,
			selectionArgs,
			groupBy,
			having,
			orderBy,
		) {
			var cols = columns ? columns.join(", ") : "*";
			console.log(
				"[sqlite:query] table=" +
					table +
					" columns=[" +
					cols +
					"] selection=" +
					selection,
			);
			return query.call(
				this,
				table,
				columns,
				selection,
				selectionArgs,
				groupBy,
				having,
				orderBy,
			);
		};
	} catch (e) {
		console.log("[sqlite] query hook skipped: " + e.message);
	}

	// SQLiteDatabase.rawQuery(String, String[])
	try {
		var SQLiteDatabase6 = Java.use("android.database.sqlite.SQLiteDatabase");
		var rawQuery = SQLiteDatabase6.rawQuery.overload(
			"java.lang.String",
			"[Ljava.lang.String;",
		);
		rawQuery.implementation = function (sql, selectionArgs) {
			console.log(
				"[sqlite:rawQuery] " +
					sql +
					" args=[" +
					(selectionArgs ? selectionArgs.join(", ") : "") +
					"]",
			);
			return rawQuery.call(this, sql, selectionArgs);
		};
	} catch (e) {
		console.log("[sqlite] rawQuery hook skipped: " + e.message);
	}

	// SQLiteDatabase.insert(String, String, ContentValues)
	try {
		var SQLiteDatabase7 = Java.use("android.database.sqlite.SQLiteDatabase");
		var insert = SQLiteDatabase7.insert.overload(
			"java.lang.String",
			"java.lang.String",
			"android.content.ContentValues",
		);
		insert.implementation = function (table, nullColumnHack, values) {
			console.log(
				"[sqlite:insert] table=" +
					table +
					" keys=[" +
					contentValuesKeys(values) +
					"]",
			);
			return insert.call(this, table, nullColumnHack, values);
		};
	} catch (e) {
		console.log("[sqlite] insert hook skipped: " + e.message);
	}

	// SQLiteDatabase.update(String, ContentValues, String, String[])
	try {
		var SQLiteDatabase8 = Java.use("android.database.sqlite.SQLiteDatabase");
		var update = SQLiteDatabase8.update.overload(
			"java.lang.String",
			"android.content.ContentValues",
			"java.lang.String",
			"[Ljava.lang.String;",
		);
		update.implementation = function (table, values, whereClause, whereArgs) {
			console.log(
				"[sqlite:update] table=" +
					table +
					" keys=[" +
					contentValuesKeys(values) +
					"] where=" +
					whereClause,
			);
			return update.call(this, table, values, whereClause, whereArgs);
		};
	} catch (e) {
		console.log("[sqlite] update hook skipped: " + e.message);
	}

	// SQLiteDatabase.delete(String, String, String[])
	try {
		var SQLiteDatabase9 = Java.use("android.database.sqlite.SQLiteDatabase");
		var del = SQLiteDatabase9.delete.overload(
			"java.lang.String",
			"java.lang.String",
			"[Ljava.lang.String;",
		);
		del.implementation = function (table, whereClause, whereArgs) {
			console.log(
				"[sqlite:delete] table=" + table + " where=" + whereClause,
			);
			return del.call(this, table, whereClause, whereArgs);
		};
	} catch (e) {
		console.log("[sqlite] delete hook skipped: " + e.message);
	}

	console.log(
		"[sqlite] Hook active for SQLite operations (openDatabase, openOrCreate, execSQL, query, rawQuery, insert, update, delete)",
	);
});
