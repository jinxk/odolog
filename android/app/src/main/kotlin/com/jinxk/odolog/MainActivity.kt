package com.jinxk.odolog

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the auto backup channel. OdoLog writes a daily copy of its data to the
 * shared Downloads collection, under Download/OdoLog, so the file outlives an
 * uninstall or a sideloaded update. MediaStore is the only path that reaches
 * shared storage without the legacy storage permissions, so the whole feature
 * needs Android 10 (API 29) or newer; below that it reports itself unavailable
 * and the Dart side hides it.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.jinxk.odolog/auto_backup"
    private val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/OdoLog"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" ->
                        result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    "write" -> {
                        val fileName = call.argument<String>("fileName")
                        val content = call.argument<String>("content")
                        if (fileName == null || content == null) {
                            result.error("bad_args", "fileName and content are required", null)
                        } else {
                            handleWrite(fileName, content, result)
                        }
                    }
                    "list" -> handleList(result)
                    "delete" -> {
                        val fileName = call.argument<String>("fileName")
                        if (fileName == null) {
                            result.error("bad_args", "fileName is required", null)
                        } else {
                            handleDelete(fileName, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleWrite(fileName: String, content: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "Needs Android 10 or newer", null)
            return
        }
        try {
            // Replace any file already written for this day so the rolling set
            // keeps one entry per day instead of a "(1)" duplicate.
            deleteByName(fileName)
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/json")
                put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            }
            val collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = contentResolver.insert(collection, values)
            if (uri == null) {
                result.error("write_failed", "Could not create the backup file", null)
                return
            }
            val stream = contentResolver.openOutputStream(uri)
            if (stream == null) {
                result.error("write_failed", "Could not open the backup file", null)
                return
            }
            stream.use { it.write(content.toByteArray(Charsets.UTF_8)) }
            result.success(null)
        } catch (e: Exception) {
            result.error("write_failed", e.message, null)
        }
    }

    private fun handleList(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(emptyList<String>())
            return
        }
        try {
            val names = mutableListOf<String>()
            val collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val projection = arrayOf(MediaStore.Downloads.DISPLAY_NAME)
            val selection =
                "${MediaStore.Downloads.RELATIVE_PATH} LIKE ? AND " +
                    "${MediaStore.Downloads.DISPLAY_NAME} LIKE ?"
            val args = arrayOf("%$relativePath%", "odolog_auto_%.json")
            contentResolver.query(collection, projection, selection, args, null)?.use { cursor ->
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
                while (cursor.moveToNext()) {
                    names.add(cursor.getString(nameColumn))
                }
            }
            result.success(names)
        } catch (e: Exception) {
            result.error("list_failed", e.message, null)
        }
    }

    private fun handleDelete(fileName: String, result: MethodChannel.Result) {
        try {
            deleteByName(fileName)
            result.success(null)
        } catch (e: Exception) {
            result.error("delete_failed", e.message, null)
        }
    }

    /** Deletes any file in the OdoLog folder with this display name. */
    private fun deleteByName(fileName: String): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return 0
        val collection =
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val selection =
            "${MediaStore.Downloads.RELATIVE_PATH} LIKE ? AND " +
                "${MediaStore.Downloads.DISPLAY_NAME} = ?"
        val args = arrayOf("%$relativePath%", fileName)
        return contentResolver.delete(collection, selection, args)
    }
}
