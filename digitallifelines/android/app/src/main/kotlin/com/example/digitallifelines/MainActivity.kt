package com.example.digitallifelines

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
	private val filesChannel = "digitallifelines/files"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		GeneratedPluginRegistrant.registerWith(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, filesChannel).setMethodCallHandler { call, result ->
			if (call.method == "saveJsonToDownloads") {
				val fileName = call.argument<String>("fileName")
				val content = call.argument<String>("content")

				if (fileName.isNullOrBlank() || content == null) {
					result.error("INVALID_ARGS", "fileName and content are required", null)
					return@setMethodCallHandler
				}

				try {
					if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
						val values = ContentValues().apply {
							put(MediaStore.Downloads.DISPLAY_NAME, fileName)
							put(MediaStore.Downloads.MIME_TYPE, "application/json")
							put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/digitallifelines")
						}

						val resolver = applicationContext.contentResolver
						val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)

						if (uri == null) {
							result.error("SAVE_FAILED", "Could not create MediaStore entry", null)
							return@setMethodCallHandler
						}

						resolver.openOutputStream(uri)?.use { out ->
							out.write(content.toByteArray(Charsets.UTF_8))
						}

						result.success(uri.toString())
					} else {
						val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
						val targetDir = File(downloads, "digitallifelines")
						if (!targetDir.exists()) {
							targetDir.mkdirs()
						}

						val outFile = File(targetDir, fileName)
						FileOutputStream(outFile).use { out ->
							out.write(content.toByteArray(Charsets.UTF_8))
						}

						result.success(outFile.absolutePath)
					}
				} catch (e: Exception) {
					result.error("SAVE_FAILED", e.message, null)
				}
			} else {
				result.notImplemented()
			}
		}
	}
}
