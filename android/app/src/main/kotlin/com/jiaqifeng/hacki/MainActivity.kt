package com.jiaqifeng.hacki

import android.content.ContentValues
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "image_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImage") {
                    val bytes = call.argument<ByteArray>("bytes")!!
                    val name = call.argument<String>("name") ?: "image"
                    val success = saveImageToGallery(bytes, name)
                    result.success(success)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveImageToGallery(bytes: ByteArray, name: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+ — use MediaStore
                val values = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, "$name.png")
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES)
                }
                val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                uri?.let {
                    contentResolver.openOutputStream(it)?.use { stream ->
                        stream.write(bytes)
                    }
                } != null
            } else {
                // Android 9 and below — write to file directly
                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val file = File(dir, "$name.png")
                FileOutputStream(file).use { it.write(bytes) }
                // Notify gallery
                val mediaScanIntent = android.content.Intent(android.content.Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                mediaScanIntent.data = android.net.Uri.fromFile(file)
                sendBroadcast(mediaScanIntent)
                true
            }
        } catch (e: Exception) {
            false
        }
    }
}